# Backend API Documentation

This document outlines the API endpoints and Server Actions available in the application.

## API Routes

### Grounds

#### `GET /api/grounds`
Fetches the list of available grounds from the static data file.
- **Response**: `Array<Ground>`
  ```json
  [
    {
      "id": 1,
      "name": "Futsal Arena",
      "location": "Kathmandu",
      "price": 1500,
      "image": "/images/ground1.jpg"
    }
  ]
  ```
- **Note**: This endpoint reads from `data/grounds.json`.

#### `POST /api/grounds`
Adds a new ground to the static data file.
- **Body**: `Ground` object
  ```json
  {
    "name": "New Ground",
    "location": "Lalitpur",
    "price": 2000,
    "image": "url"
  }
  ```
- **Response**:
  ```json
  {
    "message": "Ground added successfully"
  }
  ```

### Payment (eSewa)

#### `POST /api/payment/verify`
Verifies a transaction with eSewa.
- **Body**:
  ```json
  {
    "transactionUuid": "string (Required)",
    "productCode": "string (Required)",
    "totalAmount": "number (Optional, used for verification url construction)"
  }
  ```
- **Response (Success)**:
  ```json
  {
    "verified": true,
    "status": "COMPLETE",
    "transactionUuid": "string",
    "refId": "string"
  }
  ```
- **Response (Failure)**:
  ```json
  {
    "error": "Payment verification failed",
    "details": "string",
    "verified": false
  }
  ```
  OR
  ```json
  {
    "verified": false,
    "status": "PENDING | FAILED | INITIATED",
    "transactionUuid": "string",
    "refId": "string"
  }
  ```

#### `POST /api/payment/generate-signature`
Generates a secure HMAC-SHA256 signature for eSewa payment requests.
- **Body**:
  ```json
  {
    "totalAmount": "number (Required)",
    "transactionUuid": "string (Required)",
    "productCode": "string (Required)"
  }
  ```
- **Response**:
  ```json
  {
    "signature": "string (Base64 encoded)",
    "message": "string (The string that was signed)"
  }
  ```

### Bookings

#### `POST /api/bookings/[id]/cancel`
Cancels an existing booking.
- **Path Parameters**:
  - `id`: The ID of the booking to cancel.
- **Body**:
  ```json
  {
    "userId": "string (Required)"
  }
  ```
- **Response (Success)**:
  ```json
  {
    "success": true
  }
  ```
- **Response (Error)**:
  ```json
  {
    "error": "string",
    "canCancel": false
  }
  ```
- **Logic**: Checks if the cancellation is within the allowed time limit set by the venue manager.

### Maintenance

#### `GET /api/cron`
Runs maintenance tasks, such as cleaning up expired slot holds.
- **Response**:
  ```json
  {
    "success": true,
    "message": "Maintenance tasks completed successfully",
    "stats": {
      "venuesProcessed": 0,
      "holdsRemoved": 0,
      "errors": 0
    }
  }
  ```

### UploadThing

#### `POST /api/uploadthing`
Webhook/Endpoint for file uploads using UploadThing.
- **Configuration**: `imageUploader`
  - Max file size: 4MB
  - Max file count: 5
  - Middleware: Verifies user authentication.
  - Callback: Returns `{ uploadedBy: userId }`.

---

## Server Actions

These actions are called directly from React Server Components or Client Components.

### Bookings (`app/actions/bookings.ts`)

#### `createBooking`
Creates a new booking, handling slot availability and temporary holds.
- **Arguments**:
  - `token`: `string` (User authentication token)
  - `venueId`: `string`
  - `date`: `string` (YYYY-MM-DD)
  - `startTime`: `string` (HH:mm)
  - `endTime`: `string` (HH:mm)
  - `amount`: `number`
- **Returns**:
  - Success: `{ success: true, bookingId: string }`
  - Error: `{ success: false, error: string }`
- **Process**:
  1. Verifies user.
  2. Checks slot availability in `venueSlots`.
  3. Creates a temporary hold.
  4. Creates a `bookings` document with status `pending_payment`.

### Slots (`app/actions/slots.ts`)

#### `releaseHold`
Releases a temporary hold on a slot.
- **Arguments**:
  - `venueId`: `string`
  - `date`: `string`
  - `startTime`: `string`
- **Returns**:
  - Success: `{ success: true }`
  - Error: `{ success: false, error: string }`

#### `blockSlot`
Blocks a slot from being booked (Manager only).
- **Arguments**:
  - `token`: `string`
  - `venueId`: `string`
  - `date`: `string`
  - `startTime`: `string`
  - `reason`: `string` (Optional)
- **Returns**:
  - Success: `{ success: true }`
  - Error: `{ success: false, error: string }`
