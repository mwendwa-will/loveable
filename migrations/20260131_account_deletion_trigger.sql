-- Migration: Account Deletion with RPC Function
-- Date: 2026-01-31
-- Description: Implements secure account deletion using PostgreSQL RPC function
-- Note: This approach doesn't use triggers to avoid permission issues

-- ============================================================================
-- FUNCTION: Delete My Account (RPC)
-- ============================================================================
-- This is the main function that users call to delete their own account
-- It handles all data cleanup and auth deletion in one function

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
  
  -- Log the deletion attempt (optional)
  RAISE NOTICE 'User % requested account deletion', current_user_id;
  
  -- Delete all user data from application tables
  -- Order: delete from tables without foreign key dependencies first
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
  -- This requires SECURITY DEFINER to have proper permissions
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
    -- Log the error
    RAISE WARNING 'Error deleting account for user %: %', current_user_id, SQLERRM;
    
    -- Re-raise the exception so it's returned to the client
    RAISE;
END;
$$;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================
-- Allow authenticated users to execute the delete_my_account function

GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;

-- ============================================================================
-- COMMENTS (Documentation)
-- ============================================================================

COMMENT ON FUNCTION public.delete_my_account() IS 
  'RPC function that allows authenticated users to delete their own account and all associated data. Uses SECURITY DEFINER to delete from auth.users.';

-- ============================================================================
-- VERIFICATION QUERIES (Run these to verify the migration)
-- ============================================================================

-- Verify function exists
-- SELECT proname, prosrc FROM pg_proc WHERE proname = 'delete_my_account';

-- Check function owner and security settings
-- SELECT proname, proowner::regrole, prosecdef FROM pg_proc WHERE proname = 'delete_my_account';

-- Test the function (DO NOT RUN IN PRODUCTION - creates a test account first)
-- SELECT public.delete_my_account();
