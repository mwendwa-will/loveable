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

    // Generic fallback
    final errorStr = error.toString();
    if (errorStr.contains('SocketException')) {
      return 'No internet connection';
    }
    if (errorStr.contains('TimeoutException')) {
      return 'Request timed out';
    }
    if (errorStr.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    }

    return 'An error occurred. Please try again.';
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
