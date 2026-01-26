#!/usr/bin/env bash
# Deploy Paystack webhook Edge Function and set secrets
# Usage: ./deploy_payments.sh <project-ref>

set -euo pipefail
PROJECT_REF="$1"

echo "Deploying paystack_webhook function to Supabase project: $PROJECT_REF"
cd "$(dirname "$0")/paystack_webhook"

supabase functions deploy paystack_webhook --project-ref "$PROJECT_REF"

# Prompt for secrets
read -p "Enter PAYSTACK_SECRET: " PAYSTACK_SECRET
read -p "Enter SUPABASE_SERVICE_ROLE_KEY: " SUPABASE_SERVICE_ROLE_KEY
read -p "Enter SUPABASE_URL: " SUPABASE_URL

supabase secrets set PAYSTACK_SECRET="$PAYSTACK_SECRET" SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_SERVICE_ROLE_KEY" SUPABASE_URL="$SUPABASE_URL" --project-ref "$PROJECT_REF"

echo "Deployed and secrets set. Remember to configure Paystack webhook URL in dashboard."
