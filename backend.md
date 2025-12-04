# Backend API Reference (Complete)

This document is a detailed, machine-friendly and developer-oriented reference for all server API endpoints implemented in this repository. Each endpoint includes:

- Method & path
- Auth / required headers
- Query parameters (if any)
- Request body schema (JSON)
- All expected responses: success and common error responses, with examples
- Implementation file for quick navigation

Notes
- Authentication: Most write endpoints require a Firebase ID token supplied as `Authorization: Bearer <idToken>`. Tokens are validated server-side via the Admin SDK.
- Role checks: Manager/Admin privileges are derived from `users/{uid}` documents (role fields).
- Secrets & env vars:
  - `ESEWA_SECRET_KEY` — HMAC secret for eSewa signatures & verification
  - `ESEWA_MERCHANT_CODE` — merchant/product code used for eSewa
  - `INVOICE_QR_SECRET` — AES key/secret used to encrypt/decrypt invoice QR payloads
- Standard error shape: `{ "error": "message", "details": {...} }`
- Timestamp fields use Firestore server timestamps in implementations.
- Implementation files are listed as `app/api/.../route.ts` or similar.

--------------------------------------------------------------------------------
Table of contents
1. Bookings
  - Create booking (POST /api/bookings)
  - Cancel booking (POST /api/bookings/[id]/cancel)
2. Invoices & QR
  - Get invoice (GET /api/invoices/[id])
  - Verify invoice / QR payload (POST /api/invoices/verify)
3. Payment (eSewa)
  - Initiate payment (POST /api/payment/initiate)
  - Generate signature (POST /api/payment/generate-signature)
  - Verify payment (POST /api/payment/verify)
4. Slots
  - Generate slots (POST /api/slots/generate)
  - Hold slot (POST /api/slots/hold)
  - Reserve / Confirm slot (POST /api/slots/reserve)
  - Unbook / Release (POST /api/slots/unbook)
5. Venues
  - List venues (GET /api/venues)
  - Create / Upsert venue (POST /api/venues)
  - Add review (POST /api/venues/[id]/reviews)
6. Users
  - Upsert user (POST /api/users/upsert)
7. Uploads (UploadThing)
  - Upload webhook endpoint (POST /api/uploadthing)
8. Maintenance / Cron
  - Run maintenance (GET /api/cron)
9. Legacy local mock
  - Grounds (GET /api/grounds, POST /api/grounds)
--------------------------------------------------------------------------------

1) BOOKINGS

A. Create booking
- Method: POST
- Path: `/api/bookings`
- Auth: Required — Firebase ID token (`Authorization: Bearer <idToken>`)
- Implementation: `app/api/bookings/route.ts`

Headers:
- `Authorization: Bearer <idToken>`
- `Content-Type: application/json`

Request body (JSON):
```json
{
  "venueId": "string (required)",
  "slotId": "string (required)",
  // optional: client-provided metadata
  "metadata": { "teamName": "string", "notes": "string" }
}
```

Success responses:
- 200 / 201 (created)
```json
{
  "ok": true,
  "bookingId": "booking_generated_id"
}
```

Common error responses:
- 400 Bad Request — missing required fields
```json
{ "error": "Missing required fields: venueId, slotId" }
```
- 401 Unauthorized — missing/invalid token
```json
{ "error": "Unauthorized" }
```
- 404 Not Found — slot not found
```json
{ "error": "Slot not found" }
```
- 409 Conflict — slot not available
```json
{ "error": "Slot is not available" }
```
- 500 Internal Server Error — transaction failure

Notes:
- Implementation performs a Firestore transaction to ensure atomicity: checks slot availability, creates `bookings/{id}`, updates slot/venue state (`booked` + `bookingId`).
- The booking doc created includes `status` = `pending` or `pending_payment` depending on flow conventions.

B. Cancel booking
- Method: POST
- Path: `/api/bookings/[id]/cancel`
- Auth: Required — Firebase ID token
- Implementation: `app/api/bookings/[id]/cancel/route.ts` (or related file under `app/api/bookings/[id]/`)

Headers:
- `Authorization: Bearer <idToken>`
- `Content-Type: application/json`

Request body (JSON):
```json
{
  "reason": "string (optional)",
  "userId": "string (optional) - server may derive from token"
}
```

Success:
- 200
```json
{ "success": true, "bookingId": "booking_xyz", "status": "cancelled" }
```

Errors:
- 401 Unauthorized
- 403 Forbidden — user not owner and not admin/manager
```json
{ "error": "Forbidden" }
```
- 404 Not Found — booking not found
- 409 Conflict — booking cannot be canceled (outside cancellation window)
- 500 Internal Server Error

Notes:
- Cancel may also release the slot in `venueSlots` or `slots` collection.
- Refund logic (if payment already captured) is NOT part of this endpoint unless implemented — check payment logs and reconcile.

--------------------------------------------------------------------------------
2) INVOICES & QR

A. Get invoice (PDF)
- Method: GET
- Path: `/api/invoices/[id]`
- Auth: Required — owner or manager/admin
- Implementation: `app/api/invoices/[id]/route.ts`

Headers:
- `Authorization: Bearer <idToken>`
- Accept: `application/pdf` or `application/json` (depends on implementation)

Query:
- `download=true` (optional) to set Content-Disposition

Success:
- 200 (PDF binary)
  - Content-Type: `application/pdf`
  - Body: PDF bytes

Or if returning JSON metadata:
- 200
```json
{
  "ok": true,
  "bookingId": "booking_xyz",
  "pdfUrl": "/path/to/generated.pdf"
}
```

Errors:
- 401 Unauthorized
- 403 Forbidden — not owner and not manager/admin
- 404 Not Found — booking/invoice not found
- 500 Internal Server Error

B. Verify invoice / QR payload
- Method: POST
- Path: `/api/invoices/verify`
- Auth: Required — Firebase ID token
- Implementation: `app/api/invoices/verify/route.ts`

Headers:
- `Authorization: Bearer <idToken>`
- `Content-Type: application/json`

Request body (JSON):
```json
{
  "qr": "base64 string or data URL of encrypted payload" // required
}
```

Behavior:
- Endpoint decrypts AES-256-GCM encrypted payload (iv || tag || ciphertext) using `INVOICE_QR_SECRET`.
- Expected decrypted structure: `{ "b": "<bookingId>", "t": 1670000000000 }`
- Checks caller's authorization: caller must be admin or manager of the venue (`venue.managedBy` contains caller uid).
- Optionally checks freshness using `t` timestamp (default TTL 24h).

Success:
- 200
```json
{
  "ok": true,
  "stale": false,
  "booking": { /* booking doc */ },
  "venue": { /* venue doc */ },
  "user": { /* booking owner user doc */ }
}
```

Errors:
- 400 Bad Request — missing `qr` or invalid payload
```json
{ "error": "Missing qr payload" }
```
- 401 Unauthorized — missing/invalid token
- 403 Forbidden — caller not authorized for this venue
- 404 Not Found — booking or venue not found
- 500 Internal Server Error — decryption errors or server misconfiguration (e.g., missing `INVOICE_QR_SECRET`)

Notes:
- Protect `INVOICE_QR_SECRET` in environment; do not leak decrypted payloads in logs.
- Implementation file performs token verification via Firebase Admin and role checks.

--------------------------------------------------------------------------------
3) PAYMENT (eSewa)

Overview:
- Flow uses three endpoints: `initiate` (assigns txn uuid & returns signature/params), `generate-signature` (helper HMAC generator), and `verify` (server calls eSewa verify endpoint and reconciles).
- `ESEWA_SECRET_KEY` and `ESEWA_MERCHANT_CODE` must be set.
- Transaction UUID format used by this code: `<bookingId>_<timestamp>` (example: `booking_abc_1700000000000`). The verify logic contains fallbacks to resolve booking by prefix or by `esewaTransactionUuid` field.

A. Initiate payment
- Method: POST
- Path: `/api/payment/initiate`
- Auth: Required
- Implementation: `app/api/payment/initiate/route.ts`

Headers:
- `Authorization: Bearer <idToken>`
- `Content-Type: application/json`

Request body:
```json
{
  "bookingId": "string (required)",
  "amount": 600,          // optional: paid amount
  "totalAmount": 600      // required: amount used to sign/verify
}
```

Behavior:
- Validates booking exists.
- Generates `transactionUuid = "<bookingId>_<Date.now()>"`.
- Atomically updates booking doc with `esewaTransactionUuid` and `esewaInitiatedAt`.
- If `venueSlots` exist, also attaches `esewaTransactionUuid` to the held entry in `venueSlots` within a transaction.
- Generates HMAC signature (same algorithm as generate-signature).
- Returns `transactionUuid`, `signature`, and paymentParams for the client.

Success:
- 200
```json
{
  "success": true,
  "transactionUuid": "booking_abc_1700000000000",
  "signature": "base64-signature",
  "paymentParams": {
    "amount": "600",
    "totalAmount": "600",
    "transactionUuid": "booking_abc_1700000000000",
    "productCode": "ESEWA_MERCHANT_CODE",
    "successUrl": "https://.../payment-success",
    "failureUrl": "https://.../payment-failure"
  }
}
```

Errors:
- 400 Bad Request — missing required fields
- 401 Unauthorized — missing / invalid token
- 404 Booking not found
- 500 Payment gateway not configured (missing env var) or DB transaction failure

B. Generate signature (server-side helper)
- Method: POST
- Path: `/api/payment/generate-signature`
- Auth: Should be protected (server-only). Implementation expects server usage.
- Implementation: `app/api/payment/generate-signature/route.ts`

Headers:
- `Content-Type: application/json`

Request body:
```json
{
  "totalAmount": "600",             // required (string or number)
  "transactionUuid": "string",      // required
  "productCode": "string"           // required (usually ESEWA_MERCHANT_CODE)
}
```

Success:
- 200
```json
{
  "signature": "base64-hmac",
  "message": "total_amount=600,transaction_uuid=...,product_code=..."
}
```

Errors:
- 400 Missing params
- 500 Missing `ESEWA_SECRET_KEY` or generation failure

C. Verify payment
- Method: POST
- Path: `/api/payment/verify`
- Auth: Required
- Implementation: `app/api/payment/verify/route.ts`

Headers:
- `Authorization: Bearer <idToken>` (required by this implementation)
- `Content-Type: application/json`

Request body:
```json
{
  "transactionUuid": "string (required)",
  "productCode": "string (required)",
  "totalAmount": 600
}
```

Behavior:
- Generates verification URL and calls eSewa's verify endpoint (GET).
- Parses eSewa response: expected shape includes `status`, `transaction_uuid`, `product_code`, `total_amount`, `ref_id`.
- If `status === 'COMPLETE'`:
  - Resolve booking (by doc id, by prefix, or by `esewaTransactionUuid` field).
  - If booking found and not already confirmed:
    - Call `bookSlot` helper to convert held slot -> confirmed.
    - Update booking doc: `status: confirmed`, `paymentTimestamp`, `esewaTransactionCode/ref` fields, `verifiedAt`.
    - Log payment via `lib/paymentLogger`.
    - Return success with booking data.
  - If booking not found:
    - Log payment for manual reconciliation and return success (to avoid losing payment).
  - If DB update fails after eSewa confirms: log payment and return success with `bookingUpdateFailed: true`.
- If non-terminal (`PENDING`, `INITIATED`, `NOT_FOUND` etc.):
  - Return `verified: false` and retain booking as `pending_payment`.
- Idempotent: if booking already `confirmed`, it will log payment and return `alreadyConfirmed: true`.

Success examples:
- Payment verified and booking confirmed:
```json
{
  "verified": true,
  "status": "COMPLETE",
  "transactionUuid": "booking_abc_1700000000000",
  "refId": "ES12345",
  "totalAmount": "600",
  "productCode": "EPAYTEST",
  "bookingConfirmed": true,
  "bookingData": {
    "bookingId": "booking_abc",
    "venueId": "venue_abc",
    "userId": "uid_123",
    "date": "2025-01-20",
    "startTime": "18:00",
    "endTime": "19:00",
    "amount": 600,
    "bookingType": "website"
  }
}
```

- Payment verified but booking missing (logged for reconciliation):
```json
{
  "verified": true,
  "status": "COMPLETE",
  "bookingFound": false,
  "message": "Payment verified but booking document not found; payment logged for manual reconciliation"
}
```

Non-terminal response:
```json
{
  "verified": false,
  "status": "PENDING",
  "bookingFound": true,
  "message": "Payment not completed; booking retained (no automatic deletion)."
}
```

Error responses:
- 400 Bad Request — missing required parameters
- 401 Unauthorized — missing/invalid token
- 500 Internal Server Error — network to eSewa failed or DB errors (but handler attempts to log payments where appropriate)

Notes:
- To prevent lost payments, the endpoint returns success (200) to eSewa when verification was received even if DB updates failed — payment is logged for manual intervention.
- The code attempts multiple strategies to find the booking document:
  1. `bookings/{transactionUuid}`
  2. If `transactionUuid` contains underscore: `bookings/{prefixBeforeLastUnderscore}`
  3. Query `bookings` where `esewaTransactionUuid` equals `transactionUuid`
- Log audit entries in `lib/paymentLogger` for every payment outcome.

--------------------------------------------------------------------------------
4) SLOTS

A. Generate slots
- Method: POST
- Path: `/api/slots/generate`
- Auth: Manager or Admin
- Implementation: `app/api/slots/generate/route.ts`

Headers:
- `Authorization: Bearer <idToken>`
- `Content-Type: application/json`

Request body (example):
```json
{
  "venueId": "string (required)",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD",
  "openTime": "08:00",
  "closeTime": "22:00",
  "slotDurationMinutes": 60,
  "daysOfWeek": [1,2,3,4,5,6,7] // optional
}
```

Success:
- 200
```json
{ "ok": true, "slotsCreated": 120 }
```

Errors:
- 400 Missing params
- 403 Forbidden (caller not manager)
- 500 DB/transaction errors

Notes:
- Use to bulk-create slots for a venue. Implementation may write to `venueSlots` or `slots` collection.

B. Hold slot
- Method: POST
- Path: `/api/slots/hold`
- Auth: Required
- Implementation: `app/api/slots/hold/route.ts`

Headers:
- `Authorization: Bearer <idToken>`
- `Content-Type: application/json`

Request body:
```json
{
  "slotId": "string (required)",
  "venueId": "string (required)",
  "holdDurationMinutes": 5
}
```

Success:
- 200
```json
{
  "ok": true,
  "slotId": "slot_xyz",
  "holdExpiresAt": 1700000000000
}
```

Errors:
- 400 Missing params
- 401 Unauthorized
- 404 Slot not found
- 409 Conflict — slot is already held / booked
- 500 Internal Server Error

Notes:
- Holds are short-lived; implementation stores hold in `venueSlots.held` or slot doc with expiry.

C. Reserve / Confirm slot
- Method: POST
- Path: `/api/slots/reserve`
- Auth: Required
- Implementation: `app/api/slots/reserve/route.ts`

Request body:
```json
{
  "slotId": "string (required)",
  "bookingId": "string (required)"
}
```

Success:
- 200
```json
{ "ok": true, "reserved": true, "slotId": "slot_xyz" }
```

Errors:
- 400/401/403/404/409/500 similar categories

D. Unbook / Release
- Method: POST
- Path: `/api/slots/unbook`
- Auth: Manager or Admin
- Implementation: `app/api/slots/unbook/route.ts`

Request body:
```json
{
  "slotId": "string (required)",
  "reason": "optional string"
}
```

Success:
- 200
```json
{ "ok": true, "slotId": "slot_xyz", "released": true }
```

Errors:
- 403 Forbidden if caller not manager/admin
- 404 Slot not found

--------------------------------------------------------------------------------
5) VENUES

A. List venues
- Method: GET
- Path: `/api/venues`
- Auth: Public
- Implementation: `app/api/venues/route.ts`

Query params:
- Pagination / filters may exist (check implementation)

Success:
- 200
```json
[
  {
    "id": "venue_1",
    "name": "Futsal Arena",
    "location": "Kathmandu",
    "pricePerHour": 1500,
    "images": ["/images/ground1.jpg"],
    "managedBy": "uid_manager"
  }
]
```

Errors:
- 500 Internal Server Error

B. Create / Upsert venue
- Method: POST
- Path: `/api/venues`
- Auth: Manager or Admin
- Implementation: `app/api/venues/route.ts` and `app/api/venues/[id]/route.ts`

Request body (example):
```json
{
  "name": "Venue Name",
  "location": "string",
  "pricePerHour": 1500,
  "managedBy": "uid_manager",
  "metadata": { "phone": "string" }
}
```

Success:
- 200 / 201
```json
{ "ok": true, "venueId": "venue_abc" }
```

Errors:
- 400, 401, 403, 500 as applicable

C. Add review
- Method: POST
- Path: `/api/venues/[id]/reviews`
- Auth: Required
- Implementation: `app/api/venues/[id]/reviews/route.ts`

Request body:
```json
{
  "rating": 4,
  "comment": "Nice ground",
  "userId": "optional (server may derive from token)"
}
```

Success:
- 200
```json
{ "ok": true, "reviewId": "rev_123" }
```

Errors:
- 400 invalid rating
- 401 / 403 / 500

--------------------------------------------------------------------------------
6) USERS

A. Upsert user
- Method: POST
- Path: `/api/users/upsert`
- Auth: Required
- Implementation: `app/api/users/upsert/route.ts`

Request body:
```json
{
  "uid": "string (required)",
  "displayName": "string",
  "email": "string",
  "role": "optional (only admin allowed to set role)"
}
```

Success:
- 200
```json
{ "ok": true, "uid": "uid_123" }
```

Errors:
- 401 Unauthorized
- 403 Forbidden — non-admin attempting to set role
- 500 Internal Server Error

Notes:
- Typically called from client to ensure `users/{uid}` doc exists after sign-up.

--------------------------------------------------------------------------------
7) UPLOADS (UploadThing)

A. Upload webhook / endpoint
- Method: POST
- Path: `/api/uploadthing`
- Auth: Required (server should verify user's token)
- Implementation: `app/api/uploadthing/route.ts` and `app/api/uploadthing/core.ts`

Request:
- Multipart/form-data or JSON depending on provider callback
- For dev stub, implementation returns `{ id: "fakeId" }`

Success (expected production):
- 200
```json
{ "ok": true, "fileId": "uploaded_file_id", "url": "https://cdn.example/..." }
```

Errors:
- 401 Unauthorized — if token missing/invalid (must verify)
- 500 Internal Server Error

Notes:
- Current repo contains a dev stub — must replace with proper verification and return of user info and file metadata in production.

--------------------------------------------------------------------------------
8) MAINTENANCE / CRON

A. Run maintenance
- Method: GET
- Path: `/api/cron`
- Auth: Optional but should be protected in production (recommend `CRON_SECRET` header)
- Implementation: `app/api/cron/route.ts`

Purpose:
- Cleanup expired holds, reconcile stuck states, run scheduled maintenance tasks.

Headers (recommended in prod):
- `X-CRON-SECRET: <secret>`

Success:
- 200
```json
{ "ok": true, "jobsRun": ["cleanupExpiredHolds", "reindexStats"] }
```

Errors:
- 403 Forbidden if `CRON_SECRET` missing/invalid when enforced
- 500 Internal Server Error

--------------------------------------------------------------------------------
9) LEGACY / LOCAL-ONLY

A. Grounds (file-backed mock)
- Method: GET / POST
- Path: `/api/grounds`
- Auth: Public (used only in dev)
- Implementation: `app/api/grounds/route.ts`

GET success:
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

POST (dev only):
- Body: same shape as above (no id)
- Returns:
```json
{ "message": "Ground added successfully" }
```

Notes:
- This is a development mock that persists to `data/grounds.json`. Not suitable for production.

--------------------------------------------------------------------------------
Common response examples and shapes

- Generic success:
```json
{
  "ok": true,
  "data": { ... }
}
```

- Generic error:
```json
{
  "error": "Descriptive error message",
  "details": { /* optional debug info */ }
}
```

--------------------------------------------------------------------------------
Operational & security recommendations
- Always validate tokens server-side for write operations.
- Use Firestore security rules to restrict client writes; server endpoints should be the only way to modify sensitive fields (booking status, esewaTransactionUuid, etc.).
- Keep `ESEWA_SECRET_KEY`, `ESEWA_MERCHANT_CODE`, `INVOICE_QR_SECRET` out of source control and set them in environment settings for each deployment.
- Add monitoring & alerts for the following conditions:
  - Payment verified by eSewa but DB update failed.
  - Booking documents missing for confirmed eSewa payments.
  - High rate of `409 Conflict` holds/fails during checkout (indicates race conditions).
- Implement reconciliation UI that queries `lib/paymentLogger` outputs so ops can match logged payments with missing/mismatched bookings.

--------------------------------------------------------------------------------
Where to find the code (quick)
- Bookings: `app/api/bookings/route.ts` and `app/api/bookings/[id]/...`
- Slots: `app/api/slots/` directory
- Payments: `app/api/payment/initiate/route.ts`, `app/api/payment/verify/route.ts`, `app/api/payment/generate-signature/route.ts`
- Invoices/QR verify: `app/api/invoices/verify/route.ts`
- Uploads: `app/api/uploadthing/route.ts` and `app/api/uploadthing/core.ts`
- Maintenance: `app/api/cron/route.ts`
- Local grounds mock: `app/api/grounds/route.ts`

--------------------------------------------------------------------------------
If you want next steps, I can:
- Generate a fully validated OpenAPI (Swagger) specification for all endpoints, including request/response schemas and examples.
- Add `curl` and Postman examples inline to each endpoint.
- Implement basic tests (integration / e2e stubs) for payment flows, idempotency and booking transactions.
- Add an admin reconciliation page that surfaces payments logged by `lib/paymentLogger` for manual reconciliation.
