// Supabase Edge Function: Paystack webhook handler
// Env vars required:
// - PAYSTACK_SECRET          (secret key for HMAC verification)
// - SUPABASE_URL
// - SUPABASE_SERVICE_ROLE_KEY

import { serve } from 'std/server';
import { createClient } from '@supabase/supabase-js';

const PAYSTACK_SECRET = Deno.env.get('PAYSTACK_SECRET') || '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function verifyPaystackSignature(body: string, signatureHeader: string | null) {
  if (!signatureHeader) return false;
  const encoder = new TextEncoder();
  const keyData = encoder.encode(PAYSTACK_SECRET);
  const key = await crypto.subtle.importKey('raw', keyData, { name: 'HMAC', hash: 'SHA-512' }, false, ['sign']);
  const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(body));
  const hex = Array.from(new Uint8Array(signature)).map(b => b.toString(16).padStart(2, '0')).join('');
  // Paystack sends hex string in x-paystack-signature
  return signatureHeader === hex;
}

serve(async (req) => {
  try {
    const raw = await req.text();
    const signatureHeader = req.headers.get('x-paystack-signature');

    const ok = await verifyPaystackSignature(raw, signatureHeader);
    if (!ok) {
      console.warn('Invalid Paystack signature');
      return new Response('Invalid signature', { status: 400 });
    }

    let payload: any;
    try {
      payload = JSON.parse(raw);
    } catch (err) {
      console.error('Invalid JSON payload', err);
      return new Response('bad payload', { status: 400 });
    }

    const eventType = payload.event || payload.event_type || payload.type || '';
    const data = payload.data || payload.payload || {};

    console.log('Paystack event:', eventType);

    // Helper to safely read user_id from metadata
    const getUserId = (obj: any) => {
      // Paystack supports a `metadata` object on charges/subscriptions
      if (!obj) return null;
      if (obj.metadata && typeof obj.metadata === 'object') {
        if (obj.metadata.user_id) return obj.metadata.user_id;
        if (obj.metadata.userId) return obj.metadata.userId;
      }
      // Some flows embed customer or authorization with email/phone; prefer explicit metadata
      return null;
    };

    // Map events to entitlement upsert/deactivate
    if (eventType === 'charge.success') {
      const userId = getUserId(data) || (data.customer && data.customer.metadata && data.customer.metadata.user_id);
      const productId = data.metadata?.product_id || data.plan?.id || data.plan?.plan_code || 'paystack_one_time';
      if (!userId) {
        console.warn('charge.success with no user_id metadata');
        return new Response('ok', { status: 200 });
      }

      await supabase.from('entitlements').upsert({
        user_id: userId,
        product_id: productId,
        platform: 'paystack',
        purchase_token: data.reference || data.id,
        expires_at: null,
        is_active: true,
        raw_response: data,
      }).eq('user_id', userId).eq('product_id', productId);

      return new Response('ok', { status: 200 });
    }

    // Subscription created or updated
    if (eventType === 'subscription.create' || eventType === 'subscription.update' || eventType === 'subscription.activate') {
      // data should contain subscription info
      const userId = getUserId(data) || (data.customer && data.customer.metadata && data.customer.metadata.user_id);
      const productId = data.plan?.id || data.plan?.plan_code || data.plan?.name || 'paystack_subscription';
      const expiresAt = data.next_payment_date ? new Date(data.next_payment_date).toISOString() : null;
      const isActive = data.status ? (data.status === 'active' || data.status === 'incomplete') : true;

      if (!userId) {
        console.warn('subscription event with no user_id metadata');
        return new Response('ok', { status: 200 });
      }

      await supabase.from('entitlements').upsert({
        user_id: userId,
        product_id: productId,
        platform: 'paystack',
        purchase_token: data.subscription_code || data.id,
        expires_at: expiresAt,
        is_active: isActive,
        raw_response: data,
      }).eq('user_id', userId).eq('product_id', productId);

      return new Response('ok', { status: 200 });
    }

    // Subscription disabled / cancelled or charge.failed
    if (eventType === 'subscription.disable' || eventType === 'subscription.disable' || eventType === 'charge.failed' || eventType === 'subscription.terminate') {
      const userId = getUserId(data) || (data.customer && data.customer.metadata && data.customer.metadata.user_id);
      const productId = data.plan?.id || data.plan?.plan_code || 'paystack_subscription';
      if (!userId) return new Response('ok', { status: 200 });
      await supabase.from('entitlements').update({ is_active: false, raw_response: data }).match({ user_id: userId, product_id: productId });
      return new Response('ok', { status: 200 });
    }

    // invoice / payment events
    if (eventType === 'invoice.payment_success' || eventType === 'invoice.payment_failed' || eventType === 'invoice.create') {
      const userId = getUserId(data) || (data.customer && data.customer.metadata && data.customer.metadata.user_id);
      const productId = data.plan?.id || data.plan?.plan_code || 'paystack_subscription';
      const expiresAt = data.next_payment_date ? new Date(data.next_payment_date).toISOString() : null;
      const isActive = eventType === 'invoice.payment_success';

      if (!userId) return new Response('ok', { status: 200 });

      if (isActive) {
        await supabase.from('entitlements').upsert({
          user_id: userId,
          product_id: productId,
          platform: 'paystack',
          purchase_token: data.subscription_code || data.id,
          expires_at: expiresAt,
          is_active: true,
          raw_response: data,
        }).eq('user_id', userId).eq('product_id', productId);
      } else {
        await supabase.from('entitlements').update({ is_active: false, raw_response: data }).match({ user_id: userId, product_id: productId });
      }

      return new Response('ok', { status: 200 });
    }

    // Unhandled events
    return new Response('ignored', { status: 200 });
  } catch (err) {
    console.error('Error handling Paystack webhook:', err);
    return new Response('internal error', { status: 500 });
  }
});
