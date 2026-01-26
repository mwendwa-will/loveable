import 'dart:io' show Platform;
import 'package:flutter/material.dart';

/// Modern overlay notification system for non-critical feedback
/// Appears at top of screen with smooth animations
class OverlayNotification {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    // Remove existing notification
    _currentOverlay?.remove();

    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) {
      debugPrint(
        'Warning: Could not show OverlayNotification because no Overlay was found in the context.',
      );
      return;
    }

    _currentOverlay = OverlayEntry(
      builder: (context) => _NotificationWidget(
        message: message,
        type: type,
        onDismiss: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
        onTap: onTap,
      ),
    );

    overlayState.insert(_currentOverlay!);

    // Auto-dismiss (skip scheduling timers when running unit/widget tests)
    final bool isRunningTests = Platform.environment['FLUTTER_TEST'] == 'true';
    if (!isRunningTests) {
      Future.delayed(duration, () {
        if (_currentOverlay != null && _currentOverlay!.mounted) {
          _currentOverlay?.remove();
          _currentOverlay = null;
        }
      });
    }
  }

  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _NotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const _NotificationWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    this.onTap,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: widget.type.backgroundColor(context),
            shadowColor: Colors.black.withValues(alpha: 0.3),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      widget.type.icon,
                      color: widget.type.color(context),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: widget.type.textColor(context),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: widget.type.textColor(context),
                      ),
                      onPressed: _dismiss,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum NotificationType {
  success,
  error,
  warning,
  info;

  IconData get icon {
    switch (this) {
      case success:
        return Icons.check_circle;
      case error:
        return Icons.error;
      case warning:
        return Icons.warning_amber;
      case info:
        return Icons.info;
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case success:
        return Colors.green;
      case error:
        return Theme.of(context).colorScheme.error;
      case warning:
        return Colors.orange;
      case info:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color backgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2C2C2C) : Colors.white;
  }

  Color textColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : Colors.black87;
  }
}
