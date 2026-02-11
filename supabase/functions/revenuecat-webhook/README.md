# RevenueCat Webhook Setup Guide

## Environment Variables Required

Add these secrets to your Supabase project:

```bash
# In Supabase Dashboard → Project Settings → Edge Functions → Secrets
REVENUECAT_WEBHOOK_SECRET=your_webhook_secret_here
```

## Deployment

Deploy this function to Supabase:

```bash
supabase functions deploy revenuecat-webhook
```

## Webhook URL

After deployment, configure this URL in RevenueCat:

```
https://your-project-id.supabase.co/functions/v1/revenuecat-webhook
```

## RevenueCat Configuration

1. Go to RevenueCat Dashboard → Project Settings → Integrations
2. Click "Add Integration" → Webhooks
3. Enter the webhook URL above
4. Set Authorization Header: `Bearer your_webhook_secret_here`
5. Select events to send:
   - INITIAL_PURCHASE
   - RENEWAL
   - CANCELLATION
   - EXPIRATION
   - PRODUCT_CHANGE
   - BILLING_ISSUE

## Testing

Test the webhook locally:

```bash
supabase functions serve revenuecat-webhook --env-file ./supabase/.env.local
```

Send a test payload:

```bash
curl -X POST http://localhost:54321/functions/v1/revenuecat-webhook \
  -H "Authorization: Bearer test_secret" \
  -H "Content-Type: application/json" \
  -d '{
    "api_version": "1.0",
    "event": {
      "id": "test-event-123",
      "type": "INITIAL_PURCHASE",
      "app_user_id": "user-uuid-here",
      "product_id": "lovely_premium_monthly",
      "expiration_at_ms": 1738886400000,
      "transaction_id": "test-txn-123"
    }
  }'
```

## Event Mapping

| RevenueCat Event | Subscription Tier | Status |
|-----------------|-------------------|--------|
| INITIAL_PURCHASE | premium | active/trial |
| RENEWAL | premium | active |
| CANCELLATION | (unchanged) | cancelled |
| EXPIRATION | free | expired |
| BILLING_ISSUE | free | expired |
| PRODUCT_CHANGE | premium | active |
