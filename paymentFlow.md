# PaymentFlow — Detailed Specification

This document describes the complete payment flow for the Tournament app including:
- hold semantics and expiration rules,
- fees and percentage breakdown (configurable defaults and recommended values),
- eSewa-specific integration details (signature generation, verify flow),
- expected API payloads and responses,
- idempotency, logging, and reconciliation rules,
- manager/ops procedures for edge cases.

Use this as the canonical reference for frontend, backend, and ops teams.

---

Table of contents
1. Overview
2. Configuration and fee model
3. Hold lifecycle & rules
4. Booking lifecycle and state transitions
5. eSewa integration details
6. API examples (initiate, verify, invoice QR)
7. Error handling, idempotency and logging
8. Reconciliation & operational runbook
9. Security notes
10. Appendix: sample JSON payloads

---

1. Overview
-----------
High-level user flow:
1. User selects slot and either directly creates a booking or places a short hold.
2. System creates a booking (status `pending` / `pending_payment`) and/or applies a hold to the slot.
3. Client calls `/api/payment/initiate` — server assigns `esewaTransactionUuid` and returns signature & params.
4. Client posts/redirects to eSewa with returned params.
5. After payment, client or server triggers `/api/payment/verify` to confirm status with eSewa.
6. On successful verification (`COMPLETE`) server converts the hold to a confirmed booking and logs the payment.
7. For non-terminal states, the booking stays pending and awaits user retry or hold expiry.

Important design goals:
- Keep secrets and signature generation server-side.
- Avoid losing successful payments by ensuring payments are logged even when DB update fails.
- Implementation must be idempotent for verify operations.

---

2. Configuration and fee model
------------------------------
The app should expose configurable values (env or settings collection) to control fee and hold behavior. Below are recommended keys and default values. These are recommendations — review for your business rules.

Configuration keys (recommended)
- `PLATFORM_COMMISSION_PERCENT` (default: 5.0)
  - Percent of the booking amount taken by platform (rounded to 2 decimals).
- `SERVICE_CHARGE_PERCENT` (default: 0.0)
  - Optional service charge applied to booking (e.g., payment processing or convenience fee).
- `TAX_PERCENT` (default: 0.0)
  - Optional tax percent applied to booking (if applicable).
- `HOLD_DEFAULT_MINUTES` (default: 5)
  - Default hold duration applied when a slot is held during checkout.
- `HOLD_EXTENSION_ALLOWED` (default: true)
  - Whether a hold may be automatically extended (rare; be cautious).
- `HOLD_MAX_EXTENSION_MINUTES` (default: 2)
  - How much extra time can be automatically added (if allowed).
- `REFUND_FULL_WINDOW_MINUTES` (default: 30)
  - Window after payment where a full refund is automatically allowed by policy (optional).
- `REFUND_FEE_PERCENT_AFTER_WINDOW` (default: 10.0)
  - Fee percent deducted from refunds after the full-window period.

Fee calculation example (recommended defaults)
- Let base amount be `A`.
- Platform commission: `platform = A * (PLATFORM_COMMISSION_PERCENT / 100)`
- Service charge: `service = A * (SERVICE_CHARGE_PERCENT / 100)`
- Tax: `tax = A * (TAX_PERCENT / 100)`
- Total amount passed to payment gateway: `total = A + platform + service + tax`

Important:
- Persist exact amounts on booking documents to avoid recalculation ambiguity.
- Use integer smallest-currency units where practical (e.g., paisa/rupee rounding) to avoid floating point issues.

---

3. Hold lifecycle & rules
-------------------------
Purpose
- A hold prevents other users from booking the same slot while the current user completes checkout.

Where holds are stored
- Implementation stores holds either on a `slots` document or a `venueSlots.held` array entry. Holds must include:
  - `bookingId` or `tempId`
  - `userId`
  - `holdExpiresAt` (timestamp)
  - `esewaTransactionUuid` (optional, added at initiate)
  - `createdAt`

Default TTL
- Default: 5 minutes (`HOLD_DEFAULT_MINUTES`). This is typically sufficient for form submission and redirect to payment.

Hold placement
- Endpoint: `POST /api/slots/hold`
- Preconditions: slot must be `available`.
- Atomically: write hold and ensure slot state prevents other holds/reservations while active.

Hold expiry rules
- When `holdExpiresAt` passes:
  - The server/cron job should clear expired holds and set slot status back to `available`.
  - Expired pending bookings (if any were created) should be either auto-cancelled or marked `expired` (business choice). The default recommended flow:
    - Booking with `status: pending_payment` and expired hold => change to `expired` and release slot.
    - If booking has `esewaTransactionUuid`, keep booking for reconciliation if payment later verifies (see reconciliation section).

Hold extension
- Automatic extension is discouraged because it increases blocked inventory.
- If allowed (`HOLD_EXTENSION_ALLOWED = true`) only extend once and only by `HOLD_MAX_EXTENSION_MINUTES` total.
- The app must track `holdExtensionCount` and `holdExtendedAt`.

Edge cases
- If hold expires but user completes eSewa flow and eSewa returns `COMPLETE`:
  - The verify flow should still process the payment and attempt to convert to confirmed booking if possible.
  - If the slot was re-assigned in the meantime, the server must detect the conflict and surface to ops (avoid double-booking).

---

4. Booking lifecycle and state transitions
-----------------------------------------
Canonical booking fields (recommended)
- `bookingId` — document id
- `venueId`
- `slotId`
- `userId`
- `status` — one of `pending`/`pending_payment`, `confirmed`, `payment_failed`, `cancelled`, `expired`, `refunded`
- `amount` — base amount (number)
- `platformFee`, `serviceCharge`, `tax` — persisted computed amounts
- `totalAmount` — persisted total to pass to gateway
- `esewaTransactionUuid` — set on init
- `esewaTransactionCode`/`refId` — set on verify
- `esewaStatus`
- `createdAt`, `verifiedAt`, `paymentTimestamp`, `cancelledAt`

State transitions (recommended)
- `nil` -> `pending` (booking created or temporary record)
- `pending` -> `pending_payment` (if hold created and waiting for payment)
- `pending_payment` -> `confirmed` (on eSewa COMPLETE & booking update)
- `pending_payment` -> `payment_failed` (on terminal failure)
- `pending_payment` -> `expired` (hold TTL passed, user did not pay)
- `confirmed` -> `refunded` (refund processed)
- `confirmed` -> `cancelled` (manager cancels or user cancels within policy)

Cancellation & refund rules (recommended policy)
- If booking is `pending_payment` and user cancels before payment: release hold, set `status: cancelled`.
- If booking is `confirmed` and user requests refund:
  - Within `REFUND_FULL_WINDOW_MINUTES`: full refund (no deduction).
  - After window: apply `REFUND_FEE_PERCENT_AFTER_WINDOW`.
- Refunds are operational actions (often outside eSewa direct API). Document refunds in `payments` or `paymentLogs`.

---

5. eSewa integration details
----------------------------
This section documents exact message format, signature rules, verification best practices and how to handle edge conditions.

Signature generation (server-only)
- Algorithm used: HMAC-SHA256 (base64 output)
- Message format used by our server (same as implementation):
  ```
  total_amount=<totalAmount>,transaction_uuid=<transactionUuid>,product_code=<ESEWA_MERCHANT_CODE>
  ```
  Example message used to generate HMAC:
  ```/dev/null/example_hmac.txt#L1-1
  total_amount=600,transaction_uuid=booking_abc_1700000000000,product_code=EPAYTEST
  ```
- Server must never expose `ESEWA_SECRET_KEY` to the client.
- Endpoint in repo used: `/api/payment/generate-signature` and `/api/payment/initiate` (which itself generates a signature).

Note: the verification helper in the repo uses a different signature for verification requests (example: `transaction_uuid=<txn>` HMAC usage). When implementing, ensure you follow the gateway docs and the exact server code in `app/api/payment/*`.

Initiate payment (`/api/payment/initiate`)
- Behavior:
  - Validate booking exists and current state allows initiation.
  - Create `transactionUuid = <bookingId>_<timestamp>` (e.g., `booking_abc_1700000000000`).
  - Persist `esewaTransactionUuid` on booking and attach it to the hold entry if present (atomically).
  - Generate `signature` from message above using `ESEWA_SECRET_KEY`.
  - Return payment params (signature, transactionUuid, productCode, successUrl, failureUrl).
- Response includes:
  - `transactionUuid`, `signature`, and `paymentParams` used client-side.

Verify payment (`/api/payment/verify`)
- Behavior:
  - Server calls eSewa verify endpoint:
    ```
    GET <ESEWA_VERIFY_URL>?product_code=<productCode>&total_amount=<normalizedAmount>&transaction_uuid=<transactionUuid>
    ```
  - Parse eSewa response with fields: `status`, `transaction_uuid`, `product_code`, `total_amount`, `ref_id`.
  - If `status === 'COMPLETE'`:
    - Locate booking using strategies:
      1. booking doc id equal to `transactionUuid`
      2. booking doc id using prefix before last underscore: `txn.substring(0, txn.lastIndexOf('_'))`
      3. query bookings where `esewaTransactionUuid == transactionUuid`
    - If booking found and not already `confirmed`:
      - Call slot helper (`bookSlot`) to convert hold -> confirmed.
      - Update booking doc: `status: confirmed`, set `esewaTransactionCode/refId`, set `verifiedAt`, set `paymentTimestamp`.
      - Log payment to `paymentLogs` with `status: success`.
    - If booking not found:
      - Log payment for manual reconciliation (store the txn + refId + amount).
      - Return 200 to the gateway (so the gateway will not retry).
    - If DB update fails after verify:
      - Log payment with `bookingUpdateFailed` flagged, return success to gateway.
  - If `status` is non-terminal (e.g., `PENDING`, `INITIATED`):
    - Return `verified: false` and leave booking `pending_payment`.
  - If `status` is terminal failed/canceled:
    - Optionally set booking to `payment_failed` and release hold.

Important eSewa fields and normalization
- Normalize amounts when calling verify (strip trailing `.00` if necessary).
- Always log `ref_id` returned by eSewa for reconciliation.
- The server code uses different HMAC constructs for initiation and verification; rely on server code to produce signatures and call eSewa.

Idempotency
- `/api/payment/verify` must be idempotent:
  - Repeated verifies must not double-confirm or double-log.
  - If booking already `confirmed`, still log the verify call and return `alreadyConfirmed: true` to client.

---

6. API examples
---------------
A. Initiate payment (client -> server)
```/dev/null/initiate.example.json#L1-12
{
  "bookingId": "booking_abc",
  "amount": 600,
  "totalAmount": 600
}
```

Server response (success):
```/dev/null/initiate.response.json#L1-24
{
  "success": true,
  "transactionUuid": "booking_abc_1700000000000",
  "signature": "base64-hmac-string",
  "paymentParams": {
    "amount": "600",
    "totalAmount": "600",
    "transactionUuid": "booking_abc_1700000000000",
    "productCode": "EPAYTEST",
    "successUrl": "https://example.com/payment-success",
    "failureUrl": "https://example.com/payment-failure"
  }
}
```

B. Verify payment (server -> eSewa; client -> server triggers it)
Client -> server:
```/dev/null/verify.request.json#L1-12
{
  "transactionUuid": "booking_abc_1700000000000",
  "productCode": "EPAYTEST",
  "totalAmount": 600
}
```

Example server responses:
- Complete & confirmed:
```/dev/null/verify.complete.json#L1-20
{
  "verified": true,
  "status": "COMPLETE",
  "transactionUuid": "booking_abc_1700000000000",
  "refId": "ES12345678",
  "totalAmount": "600",
  "bookingConfirmed": true,
  "bookingData": {
    "bookingId": "booking_abc",
    "venueId": "venue_abc",
    "userId": "uid_123",
    "date": "2025-01-20",
    "startTime": "18:00",
    "endTime": "19:00",
    "amount": 600
  }
}
```

- Pending:
```/dev/null/verify.pending.json#L1-12
{
  "verified": false,
  "status": "PENDING",
  "transactionUuid": "booking_abc_1700000000000",
  "bookingFound": true,
  "message": "Payment not completed; booking retained (no automatic deletion)."
}
```

- Complete but booking missing (reconciliation required):
```/dev/null/verify.missing.json#L1-8
{
  "verified": true,
  "status": "COMPLETE",
  "bookingFound": false,
  "message": "Payment verified but booking document not found; payment logged for manual reconciliation"
}
```

C. Invoice QR verification (manager scan)
Client (manager) -> server:
```/dev/null/invoice.verify.request.json#L1-6
{ "qr": "<base64-or-data-url>" }
```

Server success:
```/dev/null/invoice.verify.response.json#L1-12
{
  "ok": true,
  "stale": false,
  "booking": { /* booking doc */ },
  "venue": { /* venue doc */ },
  "user": { /* booking owner doc */ }
}
```

---

7. Error handling, idempotency and logging
-----------------------------------------
Error handling best practices
- Return clear JSON errors: `{ "error": "message", "details": { ... } }`.
- Use HTTP status codes properly: 400 for bad request, 401 unauthorized, 403 forbidden, 404 not found, 409 conflict, 500 server error.
- For verify operations, prefer returning 200 to the payment gateway when the gateway successfully confirmed payment even if DB update fails — but record the DB failure in `paymentLogs` for manual reconciliation.

Idempotency rules
- `POST /api/payment/verify` must be idempotent:
  - If an incoming verify shows `COMPLETE` and booking is already `confirmed`, do not re-run booking conversion — still ensure a log entry exists.
  - Record `alreadyConfirmed` flag in logs/responses.

Logging & persistent audit trail
- Persist every interaction with the payment gateway to a `paymentLogs` collection (or `payments`), fields:
  - `transactionUuid`, `bookingId` (if known), `userId`, `venueId`, `status` (gateway status), `refId`, `amount`, `rawGatewayResponse`, `handledAt`, `handler` (system/operator), `reconciled` flag.
- Payments must never be treated as ephemeral — even if the booking is missing, keep the log entry so ops can reconcile.

---

8. Reconciliation & operational runbook
---------------------------------------
Automated reconciliation
- Daily job: scan `paymentLogs` where `status = SUCCESS/COMPLETE` and `bookingConfirmed != true`.
- Attempt automatic reconciliation:
  1. If bookingId is available in log and booking exists but not confirmed, call `bookSlot` helper or update booking doc.
  2. If booking not found, attempt to match by `userId`, `amount`, `timestamp` range.
  3. If matched, create or update booking and mark `reconciled = true`.

Manual ops steps
- If auto-reconciliation fails:
  1. Create an ops ticket with `transactionUuid`, `refId`, amount, and relevant logs.
  2. Contact payment provider if necessary (eSewa support) with `refId`.
  3. If user requests refund: follow refund policy; record refund action in `paymentLogs` (append-only).

Alerts & monitoring
- Alert when:
  - > N verified payments without confirmed bookings in last hour.
  - > M `bookingUpdateFailed` entries in last hour.
  - Spike in `409` conflicts during checkout.

Admin tools (recommended)
- A reconciliation UI with:
  - Search by `transactionUuid`, `bookingId`, `userId`, `refId`.
  - Actions: `Attempt auto-reconcile`, `Mark reconciled manually`, `Initiate refund`, `Create ops ticket`.
- Audit logs of every manual reconciliation action.

---

9. Security notes
-----------------
- Never expose `ESEWA_SECRET_KEY` or `INVOICE_QR_SECRET` on client-side.
- Use secure storage (secrets manager) for environment variables.
- Validate and verify ID tokens server-side for all protected endpoints.
- Rate limit public endpoints such as `/api/payment/generate-signature` and `/api/invoices/verify`.
- Mask sensitive logs (do not log raw QR secrets or full gateway secret responses).
- Use HTTPS for all endpoints, especially callbacks and verify endpoints.

---

10. Appendix: sample JSON payloads
----------------------------------
Initiate example:
```/dev/null/appendix.initiate.json#L1-12
{
  "bookingId": "booking_abc",
  "amount": 600,
  "totalAmount": 600
}
```

Verify example:
```/dev/null/appendix.verify.json#L1-10
{
  "transactionUuid": "booking_abc_1700000000000",
  "productCode": "EPAYTEST",
  "totalAmount": 600
}
```

Payment log schema (recommended)
```/dev/null/paymentLog.schema.json#L1-30
{
  "transactionUuid": "string",
  "bookingId": "string | null",
  "userId": "string | null",
  "venueId": "string | null",
  "amount": "number",
  "status": "string (COMPLETE|PENDING|FAILED)",
  "refId": "string",
  "rawResponse": { "...": "gateway response" },
  "handledAt": "timestamp",
  "reconciled": false,
  "notes": "string"
}
```

---

If you want I can:
- Convert this specification into an OpenAPI spec or a machine-readable JSON Schema for use by frontend & backend code generation.
- Add a reconciliation UI scaffold (simple admin page) connected to `paymentLogs`.
- Implement a small cron job script template to auto-reconcile `paymentLogs`.
