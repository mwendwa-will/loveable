// ================================================
// RevenueCat Webhook Handler
// Syncs subscription events from RevenueCat to Supabase
// ================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Type definitions for RevenueCat webhook events
interface RevenueCatEvent {
  api_version: string;
  event: {
    id: string;
    type: string;
    app_user_id: string;
    aliases?: string[];
    original_app_user_id: string;
    product_id?: string;
    period_type?: string;
    purchased_at_ms?: number;
    expiration_at_ms?: number;
    store?: string;
    environment?: string;
    entitlement_ids?: string[];
    entitlement_id?: string;
    is_trial_conversion?: boolean;
    price?: number;
    currency?: string;
    transaction_id?: string;
    original_transaction_id?: string;
  };
}

interface SubscriptionUpdate {
  tier: string;
  status: string;
  expires_at?: string;
  billing_cycle?: string;
  transaction_id?: string;
  payment_provider: string;
  updated_at: string;
}

serve(async (req: Request) => {
  try {
    // Verify webhook authorization
    const authHeader = req.headers.get("Authorization");
    const webhookSecret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");

    if (!webhookSecret) {
      console.error("REVENUECAT_WEBHOOK_SECRET not configured");
      return new Response("Server configuration error", { status: 500 });
    }

    if (authHeader !== `Bearer ${webhookSecret}`) {
      console.warn("Unauthorized webhook attempt");
      return new Response("Unauthorized", { status: 401 });
    }

    // Parse event payload
    const payload: RevenueCatEvent = await req.json();
    const { event } = payload;
    const { type, app_user_id, product_id, expiration_at_ms, transaction_id } = event;

    console.log(`Processing RevenueCat event: ${type} for user: ${app_user_id}`);

    // Initialize Supabase client with service role key
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseKey) {
      console.error("Supabase credentials not configured");
      return new Response("Server configuration error", { status: 500 });
    }

    const supabase = createClient(supabaseUrl, supabaseKey);

    // Map event type to subscription update
    let update: Partial<SubscriptionUpdate> | null = null;

    switch (type) {
      case "INITIAL_PURCHASE":
      case "RENEWAL":
      case "NON_RENEWING_PURCHASE":
        update = {
          tier: "premium",
          status: event.is_trial_conversion === false ? "trial" : "active",
          expires_at: expiration_at_ms
            ? new Date(expiration_at_ms).toISOString()
            : undefined,
          billing_cycle: product_id?.includes("yearly") ? "yearly" : "monthly",
          transaction_id: transaction_id || event.original_transaction_id,
          payment_provider: "revenuecat",
          updated_at: new Date().toISOString(),
        };
        break;

      case "CANCELLATION":
        // User cancelled but subscription may still be active until expiry
        update = {
          status: "cancelled",
          payment_provider: "revenuecat",
          updated_at: new Date().toISOString(),
        };
        break;

      case "EXPIRATION":
      case "BILLING_ISSUE":
        // Subscription has expired or failed to renew
        update = {
          tier: "free",
          status: "expired",
          payment_provider: "revenuecat",
          updated_at: new Date().toISOString(),
        };
        break;

      case "PRODUCT_CHANGE":
        // User upgraded/downgraded plan
        update = {
          tier: "premium",
          status: "active",
          billing_cycle: product_id?.includes("yearly") ? "yearly" : "monthly",
          transaction_id: transaction_id || event.original_transaction_id,
          payment_provider: "revenuecat",
          updated_at: new Date().toISOString(),
        };
        break;

      default:
        console.log(`Ignoring event type: ${type}`);
        return new Response("Event ignored", { status: 200 });
    }

    if (!update) {
      return new Response("No update required", { status: 200 });
    }

    // Update subscription in database
    const { data, error } = await supabase
      .from("subscriptions")
      .update(update)
      .eq("user_id", app_user_id)
      .select();

    if (error) {
      console.error("Database update error:", error);
      return new Response(`Database error: ${error.message}`, { status: 500 });
    }

    console.log(`Successfully updated subscription for user: ${app_user_id}`, data);

    return new Response(
      JSON.stringify({
        success: true,
        event_type: type,
        user_id: app_user_id,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Webhook processing error:", error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
