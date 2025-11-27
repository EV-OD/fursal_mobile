# eSewa Payment Integration

This document explains the eSewa payment integration in the tournament booking system.

## Overview

The payment system uses eSewa's ePay API v2 with HMAC-SHA256 signature verification for secure transactions.

## Architecture

### Security Model
- **Client-side**: Initiates payment, displays UI
- **Server-side**: Generates HMAC-SHA256 signatures, verifies transactions
- **Secret Key**: Never exposed to client, stored in server environment variables

### Flow
1. User books a slot (5-minute hold created)
2. User clicks "Confirm & Pay" on payment page
3. System generates secure signature (server-side)
4. User redirected to eSewa payment gateway
5. User completes payment on eSewa
6. eSewa redirects back to success/failure page
7. System verifies transaction with eSewa API
8. Booking confirmed and hold converted to booking

## Files Structure

```
lib/esewa/
├── config.ts           # Configuration, URLs, constants
└── initiate.ts        # Client-side payment initiation

app/api/payment/
├── generate-signature/
│   └── route.ts       # Server-side signature generation
└── verify/
    └── route.ts       # Transaction verification

app/payment/
├── [bookingId]/
│   └── page.tsx       # Payment page with countdown
├── success/
│   └── page.tsx       # Success callback handler
└── failure/
    └── page.tsx       # Failure callback handler
```

## Environment Variables

Create `.env.local` file with:

```bash
# Public Merchant Code
NEXT_PUBLIC_ESEWA_MERCHANT_CODE=EPAYTEST  # UAT
# Production: Your actual merchant code

# Secret Key (Server-side only)
ESEWA_SECRET_KEY=8gBm/:&EnhH.1/q  # UAT
# Production: Your actual secret key

# Application URL
NEXT_PUBLIC_APP_URL=http://localhost:3000
# Production: https://yourdomain.com
```

## API Endpoints

### POST /api/payment/generate-signature
Generates HMAC-SHA256 signature for payment request.

**Request:**
```json
{
  "totalAmount": "1000",
  "transactionUuid": "booking_123",
  "productCode": "EPAYTEST"
}
```

**Response:**
```json
{
  "signature": "4Ov7pCI1zIOdwtV2BRMUNjz1upIlT/COTxfLhWvVurE="
}
```

### POST /api/payment/verify
Verifies transaction status with eSewa.

**Request:**
```json
{
  "transactionUuid": "booking_123",
  "productCode": "EPAYTEST"
}
```

**Response:**
```json
{
  "verified": true,
  "status": "COMPLETE",
  "transactionUuid": "booking_123",
  "refId": "00AK01",
  "totalAmount": "1000",
  "productCode": "EPAYTEST"
}
```

## URLs

### UAT (Testing)
- **Payment**: https://rc-epay.esewa.com.np/api/epay/main/v2/form
- **Verification**: https://rc-epay.esewa.com.np/api/epay/transaction/status/

### Production
- **Payment**: https://epay.esewa.com.np/api/epay/main/v2/form
- **Verification**: https://epay.esewa.com.np/api/epay/transaction/status/

## Testing

### UAT Credentials
- **Merchant Code**: EPAYTEST
- **Secret Key**: 8gBm/:&EnhH.1/q
- **Test User**: Get from eSewa for testing

### Test Flow
1. Book a slot as a regular user
2. Click "Confirm & Pay"
3. Login with eSewa test credentials
4. Complete payment
5. Verify redirection to success page
6. Check booking status updated to "confirmed"

## Production Deployment

1. Get production credentials from eSewa:
   - Merchant Code
   - Secret Key

2. Update environment variables:
   ```bash
   NEXT_PUBLIC_ESEWA_MERCHANT_CODE=YOUR_MERCHANT_CODE
   ESEWA_SECRET_KEY=YOUR_SECRET_KEY
   NEXT_PUBLIC_APP_URL=https://yourdomain.com
   ```

3. Verify callback URLs are accessible:
   - https://yourdomain.com/payment/success
   - https://yourdomain.com/payment/failure

4. Test with real eSewa account

## Security Considerations

- ✅ Secret key stored server-side only
- ✅ Signature generation done server-side
- ✅ Transaction verification with eSewa
- ✅ HTTPS required in production
- ✅ Hold expiry mechanism (5 minutes)
- ✅ Status validation before payment

## Troubleshooting

### Payment fails immediately
- Check merchant code and secret key
- Verify environment variables loaded
- Check eSewa account has sufficient balance (testing)

### Signature mismatch error
- Ensure message format: `total_amount=X,transaction_uuid=Y,product_code=Z`
- Verify secret key matches eSewa dashboard
- Check no extra spaces in parameters

### Verification fails
- Check if using correct environment (UAT vs Production)
- Verify transaction UUID matches
- Check network connectivity to eSewa API

### Callback not working
- Verify APP_URL is correct and accessible
- Check success/failure URLs are not blocked
- Ensure HTTPS in production

## References

- [eSewa ePay Documentation](https://developer.esewa.com.np/)
- HMAC-SHA256 Algorithm: RFC 2104
