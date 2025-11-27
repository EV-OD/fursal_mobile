# Firebase Database Documentation

This document outlines the Firestore database structure and security rules used in the application.

## Collections

### `users`
Stores user profile information.
- **Document ID**: `userId` (Auth UID)
- **Fields**:
  - `role`: `string` ('admin' | 'manager' | 'user')
  - `email`: `string`
  - `displayName`: `string` (Optional)
  - `photoURL`: `string` (Optional)
  - `cancellationHoursLimit`: `number` (Optional, specific to managers)
  - `createdAt`: `string` (ISO)

### `venues`
Stores information about sports venues.
- **Document ID**: `venueId` (Auto-generated)
- **Fields**:
  - `name`: `string`
  - `description`: `string | null`
  - `latitude`: `number`
  - `longitude`: `number`
  - `address`: `string | null`
  - `imageUrls`: `string[]`
  - `pricePerHour`: `number`
  - `attributes`: `Map<string, string>` (e.g., { "Parking": "Available" })
  - `createdAt`: `string` (ISO)
  - `managedBy`: `string` (UID of the manager)
  - `averageRating`: `number` (Optional, updated on review)
  - `reviewCount`: `number` (Optional, updated on review)

### `venueSlots`
Contains critical availability data for venues. This collection is used to manage concurrency and prevent double bookings.
- **Document ID**: `venueId` (Matches the ID in `venues` collection)
- **Fields**:
  - `venueId`: `string`
  - `config`: `Object`
    - `startTime`: `string` (HH:mm)
    - `endTime`: `string` (HH:mm)
    - `slotDuration`: `number` (minutes)
    - `daysOfWeek`: `number[]` (0=Sunday, 6=Saturday)
    - `timezone`: `string`
  - `bookings`: `Array<BookedSlot>`
    - `date`: `string`
    - `startTime`: `string`
    - `userId`: `string` (Optional)
    - `bookingId`: `string` (Optional)
    - `bookingType`: `'physical' | 'website'` (Optional)
    - `status`: `'confirmed' | 'pending_payment'` (Optional)
    - `customerName`: `string` (Optional)
    - `customerPhone`: `string` (Optional)
    - `notes`: `string` (Optional)
  - `held`: `Array<HeldSlot>` (Temporary holds)
    - `date`: `string`
    - `startTime`: `string`
    - `userId`: `string`
    - `holdExpiresAt`: `Timestamp`
    - `bookingId`: `string`
    - `createdAt`: `Timestamp`
  - `blocked`: `Array<BlockedSlot>` (Manager blocked slots)
    - `date`: `string`
    - `startTime`: `string`
    - `reason`: `string` (Optional)
    - `blockedBy`: `string`
    - `blockedAt`: `Timestamp`
  - `reserved`: `Array<ReservedSlot>`
    - `date`: `string`
    - `startTime`: `string`
    - `note`: `string` (Optional)
    - `reservedBy`: `string`
    - `reservedAt`: `Timestamp`
  - `updatedAt`: `Timestamp`

### `bookings`
Stores individual booking records.
- **Document ID**: `bookingId`
- **Fields**:
  - `venueId`: `string`
  - `userId`: `string`
  - `date`: `string` (YYYY-MM-DD)
  - `startTime`: `string` (HH:mm)
  - `endTime`: `string` (HH:mm)
  - `status`: `string` ('pending_payment', 'confirmed', 'cancelled')
  - `amount`: `number`
  - `bookingType`: `string` ('website')
  - `holdExpiresAt`: `Timestamp`
  - `createdAt`: `Timestamp`
  - `cancelledAt`: `Timestamp` (if cancelled)

### `reviews`
Stores user reviews for venues.
- **Document ID**: `${venueId}_${userId}` (Composite key to ensure one review per user per venue)
- **Fields**:
  - `venueId`: `string`
  - `userId`: `string`
  - `rating`: `number`
  - `comment`: `string`
  - `createdAt`: `Timestamp`
  - `updatedAt`: `Timestamp`

### `venues/{venueId}/comments`
Subcollection for comments on a specific venue.
- **Document ID**: Auto-generated
- **Fields**:
  - `text`: `string`
  - `author`: `string` (Display name or email)
  - `role`: `string` ('user' | 'manager' | 'admin')
  - `rating`: `number`
  - `createdAt`: `string` (ISO)

---

## Security Rules (`firestore.rules`)

### General
- **Helper Functions**:
  - `isAuthenticated()`: Checks if `request.auth` is not null.
  - `isOwner(userId)`: Checks if the authenticated user matches the `userId`.
  - `isAdmin()`: Checks if the user has the 'admin' role in their `users` document.

### Collection Rules

- **`users/{userId}`**
  - **Read**: Allowed if authenticated.
  - **Create**: Allowed if user is owner.
  - **Update**: Allowed if user is owner AND not modifying the `role` field.
  - **Delete**: Allowed if admin.

- **`venues/{venueId}`**
  - **Read**: Publicly allowed.
  - **Write**: Allowed if admin.

- **`venueSlots/{venueId}`**
  - **Read**: Publicly allowed.
  - **Write**: **Denied**. All modifications must be performed via Server Actions (using Firebase Admin SDK) to ensure data integrity and handle complex logic like locking.

- **`bookings/{bookingId}`**
  - **Read**: Allowed if user is the owner of the booking OR is an admin.
  - **Write**: **Denied**. Creation and updates must be handled via Server Actions.

## Storage Rules (`storage.rules`)

- **Read**: Publicly allowed for all files.
- **Write**: Allowed if the user is authenticated.
