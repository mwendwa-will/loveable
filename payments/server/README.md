Minimal Paystack payment server

This tiny Express server exposes an `/initiate` endpoint to initialize a Paystack Checkout (transaction.initialize).

Environment variables:
- `PAYSTACK_SECRET` - your Paystack secret key (test or live)
- `CALLBACK_BASE` - base URL for your callback pages (defaults to `http://localhost:3000`)
- `PORT` - optional server port (default 3000)

Install and run

```bash
cd payments/server
npm install
PAYSTACK_SECRET=sk_test_xxx CALLBACK_BASE=http://localhost:3000 npm start
```

Open the test page

```bash
# Serve or open payments/web/index.html in your browser
# If server runs on same origin, the page will POST to /initiate
open payments/web/index.html
```

How it works

- The server calls Paystack `transaction/initialize` with `email`, `amount` (in minor units), `metadata` including `user_id` and `product`, and a `callback_url`.
- Paystack responds with an `authorization_url` where you redirect the user to complete payment.
- Paystack will notify your webhook (Edge Function) about the payment result; you must include `metadata.user_id` so your webhook can map payments to Supabase users.

Next steps

- Deploy this server behind TLS (or use the Supabase Edge Function to implement the same `/initiate` logic).
- Configure Paystack webhook to hit your deployed `paystack_webhook` Edge Function.
- Create subscription plans in the Paystack dashboard and use matching `product` IDs in the metadata.
