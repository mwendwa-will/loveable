import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunara/constants/app_colors.dart';
import 'package:lunara/providers/subscription_provider.dart';
import 'package:lunara/utils/responsive_utils.dart';
import 'package:lunara/widgets/upgrade_sheet.dart';

/// Banner displayed during active trial period
class TrialBanner extends ConsumerWidget {
  const TrialBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionProvider);

    return subscriptionAsync.when(
      data: (subscription) {
        // Only show banner if trial is active
        if (subscription == null || !subscription.isTrialActive) {
          return const SizedBox.shrink();
        }

        final hoursRemaining = subscription.trialHoursRemaining;
        final isUrgent = hoursRemaining <= 6;

        return _buildBanner(
          context,
          subscription: subscription,
          isUrgent: isUrgent,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildBanner(
    BuildContext context, {
    required subscription,
    required bool isUrgent,
  }) {
    final theme = Theme.of(context);
    final responsive = ResponsiveSizing.of(context);
    final primaryColor = AppColors.getPrimaryColor(context);

    final gradient = isUrgent
        ? LinearGradient(
            colors: [
              Colors.orange.shade400,
              Colors.red.shade400,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
        : LinearGradient(
            colors: [
              primaryColor,
              primaryColor.withAlpha(200),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          );

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: responsive.spacingMd,
        vertical: responsive.spacingSm,
      ),
      padding: EdgeInsets.all(responsive.spacingMd),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(responsive.spacingSm),
      ),
      child: Row(
        children: [
          Icon(
            isUrgent ? Icons.timer_outlined : Icons.workspace_premium_rounded,
            color: Colors.white,
            size: responsive.iconSize,
          ),
          SizedBox(width: responsive.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isUrgent ? 'Trial ending soon!' : 'Premium Trial Active',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subscription.trialRemainingDisplay,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withAlpha(230),
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => UpgradeSheet.show(context),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(51),
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}
