import 'package:flutter/material.dart';
import 'package:lovely/widgets/overlay_notification.dart';
import 'package:lovely/core/exceptions/app_exceptions.dart';

/// Modern feedback service for user notifications
/// Replaces SnackBars with context-aware, accessible feedback
class FeedbackService {
  /// Show success message (brief, non-intrusive)
  static void showSuccess(
    BuildContext context,
    String message, {
    VoidCallback? onTap,
  }) {
    OverlayNotification.show(
      context,
      message: message,
      type: NotificationType.success,
      duration: const Duration(seconds: 2),
      onTap: onTap,
    );
  }

  /// Show error message (persistent with Material Banner for critical errors)
  static void showError(
    BuildContext context,
    Object error, {
    VoidCallback? onRetry,
  }) {
    final errorMessage = _getErrorMessage(error);
    final isRetryable = _isRetryable(error);

    if (isRetryable && onRetry != null) {
      // Use Material Banner for retryable errors
      final messengerState = ScaffoldMessenger.of(context);
      messengerState.clearMaterialBanners();
      messengerState.showMaterialBanner(
        MaterialBanner(
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: Theme.of(
            context,
          ).colorScheme.error.withValues(alpha: 0.1),
          actions: [
            TextButton(
              onPressed: () {
                messengerState.hideCurrentMaterialBanner();
                onRetry();
              },
              child: const Text('RETRY'),
            ),
            TextButton(
              onPressed: () => messengerState.hideCurrentMaterialBanner(),
              child: const Text('DISMISS'),
            ),
          ],
        ),
      );
    } else {
      // Use overlay notification for non-retryable errors
      OverlayNotification.show(
        context,
        message: errorMessage,
        type: NotificationType.error,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Show warning message
  static void showWarning(BuildContext context, String message) {
    OverlayNotification.show(
      context,
      message: message,
      type: NotificationType.warning,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show info message
  static void showInfo(BuildContext context, String message) {
    OverlayNotification.show(
      context,
      message: message,
      type: NotificationType.info,
      duration: const Duration(seconds: 3),
    );
  }

  /// Hide current material banner
  static void hideBanner(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
  }

  /// Get user-friendly error message from exception
  static String getErrorMessage(Object error) {
    return _getErrorMessage(error);
  }

  /// Internal: Get user-friendly error message from exception
  static String _getErrorMessage(Object error) {
    // Handle typed app exceptions first (highest priority)
    if (error is AuthException) {
      return error.message;
    }

    if (error is NetworkException) {
      return error.message;
    }

    if (error is DatabaseException) {
      return error.message;
    }

    if (error is ValidationException) {
      return error.message;
    }

    if (error is AppException) {
      return error.message;
    }

    // Handle Dart built-in exceptions
    if (error is FormatException) {
      return 'Data format issue - try again?';
    }

    if (error is RangeError) {
      return 'No data available';
    }

    if (error is StateError) {
      return 'Operation not allowed at this time';
    }

    // String-based pattern matching for external exceptions
    final errorStr = error.toString();

    // Network errors
    if (errorStr.contains('SocketException')) {
      return 'No internet connection';
    }
    if (errorStr.contains('TimeoutException')) {
      return 'Request timed out - try again?';
    }

    // Auth errors
    if (errorStr.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    }
    if (errorStr.contains('User already registered')) {
      return 'This email is already registered';
    }
    if (errorStr.contains('Email not confirmed')) {
      return 'Let\'s verify your email first ✉️';
    }

    // Database/Supabase errors - check specific errors first
    if (errorStr.contains('duplicate key')) {
      return 'This record already exists';
    }
    if (errorStr.contains('violates foreign key')) {
      return 'Cannot delete - related data exists';
    }
    if (errorStr.contains('violates not-null') || errorStr.contains('null value')) {
      return 'Required information is missing';
    }
    if (errorStr.contains('relation') && errorStr.contains('does not exist')) {
      return 'Database table not found - contact support if this continues';
    }
    if (errorStr.contains('column') && errorStr.contains('does not exist')) {
      return 'App needs updating - check the app store 🔄';
    }
    if (errorStr.contains('permission denied') || errorStr.contains('RLS')) {
      return 'Access denied - try logging in again?';
    }
    if (errorStr.contains('connection') || errorStr.contains('ECONNREFUSED')) {
      return 'Cannot connect to database. Check your internet connection.';
    }
    if (errorStr.contains('multiple') && errorStr.contains('rows returned')) {
      return 'Duplicate data found - contact support if this continues';
    }
    if (errorStr.contains('no rows returned') || errorStr.contains('0 rows')) {
      return 'No data found';
    }
    if (errorStr.contains('PostgrestException')) {
      // Log for debugging - this is a catch-all for unhandled DB errors
      debugPrint('Unhandled PostgrestException: $errorStr');
      return 'Couldn\'t complete that - try again?';
    }

    // Storage errors
    if (errorStr.contains('StorageException')) {
      return 'File operation failed';
    }
    if (errorStr.contains('file size') || errorStr.contains('too large')) {
      return 'File is too large';
    }
    if (errorStr.contains('invalid file type') || errorStr.contains('mime type')) {
      return 'Invalid file type';
    }

    // HTTP status code errors
    if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
      return 'Session expired - log in again?';
    }
    if (errorStr.contains('403') || errorStr.contains('Forbidden')) {
      return 'Access denied';
    }
    if (errorStr.contains('404') || errorStr.contains('Not Found')) {
      return 'Requested resource not found';
    }
    if (errorStr.contains('429') || errorStr.contains('Too Many Requests')) {
      return 'Slow down - wait a moment and try again';
    }
    if (errorStr.contains('500') || errorStr.contains('Internal Server Error')) {
      return 'Server hiccup - try again in a moment?';
    }
    if (errorStr.contains('502') || errorStr.contains('503') || errorStr.contains('504')) {
      return 'Service temporarily unavailable - try again soon';
    }

    // Permission errors
    if (errorStr.contains('permission') || errorStr.contains('Permission')) {
      return 'Permission denied';
    }
    if (errorStr.contains('PlatformException')) {
      return 'Device feature unavailable';
    }

    // Generic fallback
    return 'Something went wrong - try again?';
  }

  /// Check if error is retryable
  static bool _isRetryable(Object error) {
    if (error is NetworkException) {
      return error.isRetryable;
    }
    if (error is DatabaseException) {
      return true;
    }
    if (error is AuthException) {
      // Session expired is retryable (user can re-login)
      return error.code == 'AUTH_003';
    }
    return false;
  }
}
