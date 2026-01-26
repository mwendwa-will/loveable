# Lovely Next.js payments scaffold

This is a minimal Next.js scaffold for the Lovely payments site. Replace the UI and wire to the payments server (`/initiate`).

Local dev:

```bash
cd payments/site-next
npm install
npm run dev
```

Make sure to update environment variables and the payments server `CALLBACK_BASE` to point at your deployed site or the local URL used during development (e.g., `http://localhost:3000`).
