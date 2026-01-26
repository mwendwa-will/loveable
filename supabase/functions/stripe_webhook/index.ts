// Supabase Edge Function: Stripe webhook handler
// Environment variables required:
// - STRIPE_SECRET: your Stripe secret key (to fetch objects if needed)
// - STRIPE_WEBHOOK_SECRET: your Stripe webhook signing secret
// - SUPABASE_URL
// - SUPABASE_SERVICE_ROLE_KEY

import { serve } from 'std/server';
import Stripe from 'stripe';
import { createClient } from '@supabase/supabase-js';

// Note: In Deno / Supabase Edge Functions you may need to import stripe via a compatible CDN or
// use the stripe package bundled for Deno. This scaffold assumes that import works in your setup.

const STRIPE_SECRET = Deno.env.get('STRIPE_SECRET') || '';
const STRIPE_WEBHOOK_SECRET = Deno.env.get('STRIPE_WEBHOOK_SECRET') || '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

const stripe = new Stripe(STRIPE_SECRET, { apiVersion: '2022-11-15' });
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

serve(async (req) => {
  try {
    const body = await req.text();
    const sig = req.headers.get('stripe-signature') || '';

    let event: Stripe.Event;
    try {
      event = stripe.webhooks.constructEvent(body, sig, STRIPE_WEBHOOK_SECRET);
    } catch (err) {
      console.error('Webhook signature verification failed', err);
      return new Response('Invalid signature', { status: 400 });
    }

    console.log('Received stripe event:', event.type);

    // Handle relevant events
    if (event.type === 'checkout.session.completed') {
      const session = event.data.object as Stripe.Checkout.Session;
      // Expect metadata.user_id to be set during Checkout session creation
      const userId = session.metadata?.user_id;
      const subscriptionId = session.subscription as string | undefined;

      if (!userId) {
        console.warn('No user_id metadata present on session');
        return new Response('No user metadata', { status: 200 });
      }

      if (subscriptionId) {
        // Retrieve subscription to get current_period_end and status
        const subscription = await stripe.subscriptions.retrieve(subscriptionId);
        const productId = subscription.items.data[0]?.plan?.product || subscription.items.data[0]?.plan?.id;
        const expiresAt = subscription.current_period_end ? new Date(subscription.current_period_end * 1000).toISOString() : null;
        const isActive = subscription.status === 'active' || subscription.status === 'trialing';

        // Upsert entitlement into Supabase (service role)
        await supabase.from('entitlements').upsert({
          user_id: userId,
          product_id: productId,
          platform: 'stripe',
          purchase_token: subscription.id,
          expires_at: expiresAt,
          is_active: isActive,
          raw_response: subscription,
        }).eq('user_id', userId).eq('product_id', productId);

        return new Response('ok', { status: 200 });
      } else if (session.payment_status === 'paid') {
        // One-time purchase path (if you use Checkout for one-time products)
        const productId = session.metadata?.product_id ?? 'stripe_checkout_product';
        await supabase.from('entitlements').insert({
          user_id: userId,
          product_id: productId,
          platform: 'stripe',
          purchase_token: session.id,
          expires_at: null,
          is_active: true,
          raw_response: session,
        });
        return new Response('ok', { status: 200 });
      }
    }

    if (event.type === 'invoice.payment_succeeded') {
      const invoice = event.data.object as Stripe.Invoice;
      const subscriptionId = invoice.subscription as string | undefined;
      if (subscriptionId) {
        const subscription = await stripe.subscriptions.retrieve(subscriptionId);
        const userId = subscription.metadata?.user_id as string | undefined;
        if (userId) {
          const productId = subscription.items.data[0]?.plan?.product || subscription.items.data[0]?.plan?.id;
          const expiresAt = subscription.current_period_end ? new Date(subscription.current_period_end * 1000).toISOString() : null;
          const isActive = subscription.status === 'active' || subscription.status === 'trialing';
          await supabase.from('entitlements').upsert({
            user_id: userId,
            product_id: productId,
            platform: 'stripe',
            purchase_token: subscription.id,
            expires_at: expiresAt,
            is_active: isActive,
            raw_response: subscription,
          }).eq('user_id', userId).eq('product_id', productId);
        }
      }
      return new Response('ok', { status: 200 });
    }

    if (event.type === 'customer.subscription.deleted' || event.type === 'invoice.payment_failed') {
      // Deactivate related entitlements
      let subscription: Stripe.Subscription | null = null;
      if (event.type === 'customer.subscription.deleted') subscription = event.data.object as Stripe.Subscription;
      if (event.type === 'invoice.payment_failed') {
        const invoice = event.data.object as Stripe.Invoice;
        if (invoice.subscription) subscription = await stripe.subscriptions.retrieve(invoice.subscription as string);
      }
      if (subscription) {
        const userId = subscription.metadata?.user_id as string | undefined;
        const productId = subscription.items.data[0]?.plan?.product || subscription.items.data[0]?.plan?.id;
        if (userId) {
          await supabase.from('entitlements').update({ is_active: false, raw_response: subscription }).match({ user_id: userId, product_id: productId });
        }
      }
      return new Response('ok', { status: 200 });
    }

    // Ignore other events
    return new Response('ignored', { status: 200 });
  } catch (err) {
    console.error('Error handling webhook:', err);
    return new Response('internal error', { status: 500 });
  }
});
