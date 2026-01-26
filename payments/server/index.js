import express from 'express';
import fetch from 'node-fetch';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
app.use(express.json());
// Simple CORS middleware to allow the website to call this server from another origin
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type,Authorization');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

const PAYSTACK_SECRET = process.env.PAYSTACK_SECRET;
const CALLBACK_BASE = process.env.CALLBACK_BASE || 'http://localhost:3000';

if (!PAYSTACK_SECRET) {
  console.error('Missing PAYSTACK_SECRET in environment');
  process.exit(1);
}

// Helper: initialize Paystack transaction
app.post('/initiate', async (req, res) => {
  try {
    const { amount, email, user_id, product } = req.body;
    if (!amount || !email || !user_id) return res.status(400).json({ error: 'Missing fields' });

    // Paystack expects amount in kobo (Naira uses kobo; for general currencies multiply by 100)
    // We'll assume minor units: amount is in major currency units (e.g., 3.00 for $3 or KES)
    const amountMinor = Math.round(Number(amount) * 100);

    const callback_url = `${CALLBACK_BASE}/paystack_callback`;

    const body = {
      email,
      amount: amountMinor,
      metadata: { user_id, product },
      callback_url,
    };

    const resp = await fetch('https://api.paystack.co/transaction/initialize', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${PAYSTACK_SECRET}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    const json = await resp.json();
    if (!json.status) {
      return res.status(500).json({ error: 'Paystack init failed', detail: json });
    }

    return res.json({ authorization_url: json.data.authorization_url, reference: json.data.reference });
  } catch (err) {
    console.error('Error initiating Paystack transaction', err);
    return res.status(500).json({ error: 'internal error' });
  }
});

// Simple callback endpoints for browser redirects (optional)
app.get('/success', (req, res) => {
  res.send('<h2>Payment success — you can close this tab and return to the app.</h2>');
});

app.get('/cancel', (req, res) => {
  res.send('<h2>Payment cancelled.</h2>');
});

// Paystack callback redirect - show rich success page with deep link
app.get('/paystack_callback', (req, res) => {
  // You may parse query params or reference if needed for tracking
  const successHtml = `
    <!doctype html>
    <html>
      <head><meta charset="utf-8"><title>Payment successful</title></head>
      <body style="font-family: Arial, sans-serif; max-width:600px;margin:40px auto;text-align:center;">
        <h1>Payment successful! ✓</h1>
        <p>Open the Lovely app to access your premium features.</p>
        <p>
          <a href="lovely://success" style="display:inline-block;padding:12px 20px;background:#0b74de;color:white;border-radius:6px;text-decoration:none;">Open Lovely App</a>
        </p>
        <p>Not installed? <a href="#">Download for Android</a> or <a href="#">iOS</a></p>
      </body>
    </html>
  `;
  res.send(successHtml);
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Payments server listening on ${port}`));
