-- Alternative Migration: Account Deletion using Service Role
-- Date: 2026-01-31
-- Description: If the main migration fails with permission errors, use this approach
-- This creates the function with postgres role ownership

-- ============================================================================
-- IMPORTANT: Run this in Supabase SQL Editor as the postgres user
-- ============================================================================

-- First, ensure the function is owned by postgres (superuser)
ALTER FUNCTION IF EXISTS public.delete_my_account() OWNER TO postgres;

-- Or recreate the function with explicit postgres ownership
CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  current_user_id uuid;
  deletion_result jsonb;
BEGIN
  -- Get the authenticated user's ID
  current_user_id := auth.uid();
  
  -- Verify user is authenticated
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated. Please log in to delete your account.';
  END IF;
  
  -- Log the deletion attempt
  RAISE NOTICE 'User % requested account deletion', current_user_id;
  
  -- Delete all user data from application tables
  DELETE FROM public.cycle_anomalies WHERE user_id = current_user_id;
  DELETE FROM public.cycles WHERE user_id = current_user_id;
  DELETE FROM public.daily_flows WHERE user_id = current_user_id;
  DELETE FROM public.moods WHERE user_id = current_user_id;
  DELETE FROM public.symptoms WHERE user_id = current_user_id;
  DELETE FROM public.sexual_activities WHERE user_id = current_user_id;
  DELETE FROM public.notes WHERE user_id = current_user_id;
  DELETE FROM public.periods WHERE user_id = current_user_id;
  DELETE FROM public.prediction_logs WHERE user_id = current_user_id;
  DELETE FROM public.entitlements WHERE user_id = current_user_id;
  DELETE FROM public.users WHERE id = current_user_id;
  
  -- Delete the user from auth.users
  DELETE FROM auth.users WHERE id = current_user_id;
  
  -- Check if deletion was successful
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Failed to delete user account. User may not exist.';
  END IF;
  
  -- Return success response
  deletion_result := jsonb_build_object(
    'success', true,
    'message', 'Account successfully deleted',
    'user_id', current_user_id,
    'deleted_at', NOW()
  );
  
  RETURN deletion_result;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Error deleting account for user %: %', current_user_id, SQLERRM;
    RAISE;
END;
$$;

-- Ensure function is owned by postgres
ALTER FUNCTION public.delete_my_account() OWNER TO postgres;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.delete_my_account() IS 
  'RPC function that allows authenticated users to delete their own account and all associated data. Uses SECURITY DEFINER with postgres ownership to delete from auth.users.';
