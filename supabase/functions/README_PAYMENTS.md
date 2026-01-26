Paystack Edge Function (payments webhook)

This folder contains the Paystack webhook Edge Function used to update the `entitlements` table in Supabase when Paystack payment or subscription events occur.

Files
- `paystack_webhook/index.ts` - Edge Function handler (HMAC-SHA512 signature verification, event parsing, upsert to `entitlements`).
- (Stripe handler removed; keep only if you need parallel providers.)

Required environment variables (set in Supabase project secrets or CI):
- `PAYSTACK_SECRET` - your Paystack secret key (used to verify `x-paystack-signature`).
- `SUPABASE_URL` - Supabase project URL.
- `SUPABASE_SERVICE_ROLE_KEY` - Supabase service role key (used by Edge Function to perform upserts).

Deploying locally with supabase CLI
1. Install `supabase` CLI and authenticate: https://supabase.com/docs/guides/cli
2. From repository root deploy the function:

```bash
cd supabase/functions/paystack_webhook
supabase functions deploy paystack_webhook --project-ref your-project-ref
```

Set secrets for the function (example):

```bash
supabase secrets set PAYSTACK_SECRET="sk_test_xxx" SUPABASE_SERVICE_ROLE_KEY="service_role_xxx" SUPABASE_URL="https://..." --project-ref your-project-ref
```

Notes
- Ensure your Paystack webhook URL is set in the Paystack Dashboard to the deployed function URL.
- The function must verify `x-paystack-signature` using HMAC-SHA512(body, PAYSTACK_SECRET).
- The function is idempotent; it upserts entitlements by `user_id` + `product_id`.
- Keep `raw_response` stored in `entitlements` for debugging and reconciliation.

Testing webhooks
- Use Paystack's dashboard/webhook simulator in test mode.
- For local testing use `supabase functions serve` (or `supabase start`) and the Paystack webhook forwarder (if available) or deploy a temporary staging function and point Paystack test webhooks there.

Reconciliation
- Implement a periodic reconciliation job if you expect missed webhooks (optional). The reconciliation job can call Paystack subscription APIs and sync `entitlements`.
