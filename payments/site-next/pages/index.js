import { createClient } from '@supabase/supabase-js';
import Head from 'next/head';

export default function Home() {
  return (
    <div style={{fontFamily:'Inter, Arial, sans-serif',padding:24,maxWidth:800,margin:'40px auto'}}>
      <Head>
        <title>Lovely - Subscribe</title>
      </Head>
      <h1>Lovely — Subscribe</h1>
      <p>This is a minimal Next.js scaffold. Replace with your real checkout UI.</p>
      <p>Use the payments server `/initiate` endpoint to initialize Paystack transactions.</p>
    </div>
  );
}
