import 'package:flutter/material.dart';

/// Modern, responsive dialog system for the app
/// Follows Material Design 3 principles with consistent styling
class AppDialog {
  /// Show a confirmation dialog with primary and secondary actions
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    DialogType type = DialogType.info,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _AppDialogWidget(
        title: title,
        message: message,
        type: type,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDangerous
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Show an informational dialog with single OK button
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
  }) {
    return showDialog(
      context: context,
      builder: (context) => _AppDialogWidget(
        title: title,
        message: message,
        type: DialogType.info,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Show an error dialog with detailed error message
  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    String? details,
    String buttonText = 'OK',
  }) {
    return showDialog(
      context: context,
      builder: (context) => _AppDialogWidget(
        title: title,
        message: message,
        details: details,
        type: DialogType.error,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Show a success dialog with confirmation
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Great!',
  }) {
    return showDialog(
      context: context,
      builder: (context) => _AppDialogWidget(
        title: title,
        message: message,
        type: DialogType.success,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Show a warning dialog
  static Future<bool?> showWarning(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Continue',
    String cancelText = 'Cancel',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _AppDialogWidget(
        title: title,
        message: message,
        type: DialogType.warning,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Show a custom dialog with custom content and actions
  static Future<T?> showCustom<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    required List<Widget> actions,
    DialogType type = DialogType.info,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => _AppDialogWidget(
        title: title,
        customContent: content,
        type: type,
        actions: actions,
      ),
    );
  }

  /// Show a loading dialog (non-dismissible)
  static Future<void> showLoading(
    BuildContext context, {
    String message = 'Loading...',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: _AppDialogWidget(
          title: message,
          customContent: const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          type: DialogType.info,
          actions: const [],
        ),
      ),
    );
  }

  /// Dismiss the currently showing dialog
  static void dismiss(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}

/// Dialog types with associated icons and colors
enum DialogType {
  info,
  success,
  warning,
  error,
  custom;

  IconData get icon {
    switch (this) {
      case DialogType.info:
        return Icons.info_outline;
      case DialogType.success:
        return Icons.check_circle_outline;
      case DialogType.warning:
        return Icons.warning_amber_rounded;
      case DialogType.error:
        return Icons.error_outline;
      case DialogType.custom:
        return Icons.help_outline;
    }
  }

  Color color(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (this) {
      case DialogType.info:
        return colorScheme.primary;
      case DialogType.success:
        return Colors.green;
      case DialogType.warning:
        return Colors.orange;
      case DialogType.error:
        return colorScheme.error;
      case DialogType.custom:
        return colorScheme.secondary;
    }
  }
}

/// Internal dialog widget with responsive design
class _AppDialogWidget extends StatelessWidget {
  final String title;
  final String? message;
  final String? details;
  final Widget? customContent;
  final DialogType type;
  final List<Widget> actions;

  const _AppDialogWidget({
    required this.title,
    this.message,
    this.details,
    this.customContent,
    required this.type,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? screenWidth * 0.9 : 400,
          minWidth: 280,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon and Title
              Row(
                children: [
                  Icon(type.icon, size: 28, color: type.color(context)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Content
              if (customContent != null)
                customContent!
              else if (message != null) ...[
                Text(message!, style: theme.textTheme.bodyLarge),
                if (details != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      details!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ],

              // Actions
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (int i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Flexible(child: actions[i]),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
