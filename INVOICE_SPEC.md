# Invoice Specification

This document outlines the structure and content of the generated PDF invoice for bookings.

## PDF Structure

The invoice is generated using the `pdf` Flutter package and contains the following sections:

### 1. Header
- **Title**: "INVOICE" (Large, Bold)
- **App Name**: "SajiloKhel"
- **Layout**: Row with title on left, app name on right.

### 2. Billing Information
- **Billed To**:
  - User ID (Currently displayed, should be replaced with User Name in future)
- **Invoice Details**:
  - Invoice Date: Current date (YYYY-MM-DD)
  - Booking ID: Unique identifier for the booking

### 3. Booking Details Table
A section listing the specifics of the booking:
- **Venue**: Name of the venue.
- **Date & Time**: Date and time range of the slot.
- **Platform**: "Mobile App (SajiloKhel)" - Indicates the source of booking.
- **Total Amount**: The price paid (e.g., "Rs. 1200").

### 4. Verification (QR Code)
A QR code is included for verification purposes.
- **Format**: QR Code
- **Content**: A JSON string containing:
  - `data`: Object with booking details:
    - `bookingId`
    - `userId`
    - `venueId`
    - `amount`
    - `date`
    - `startTime`
    - `endTime`
    - `timestamp` (Generation time)
  - `hash`: SHA-256 hash of the `data` object (stringified).
- **Purpose**:
  - **Identification**: Contains all necessary fields to identify the booking.
  - **Integrity**: The hash allows verification that the data hasn't been tampered with (though full security requires a private key signature, this provides a basic check).
  - **Conflict Resolution**: Managers can scan this code to quickly pull up booking details and verify validity against their records.

### 5. Footer
- **Message**: "Thank you for booking with SajiloKhel!"

## Usage
- The invoice is available for download only for **confirmed** bookings.
- Users can access it from the `BookingDetailScreen`.
- The PDF is generated on-the-fly and can be saved or shared using the device's native capabilities.
