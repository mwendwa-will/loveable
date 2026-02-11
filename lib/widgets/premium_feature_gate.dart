import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunara/constants/app_colors.dart';
import 'package:lunara/providers/subscription_provider.dart';
import 'package:lunara/utils/responsive_utils.dart';
import 'package:lunara/widgets/upgrade_sheet.dart';

/// Feature gate that restricts access to premium features
class PremiumFeatureGate extends ConsumerWidget {
  final PremiumFeature feature;
  final Widget child;
  final String? featureName;
  final bool showLockedOverlay;

  const PremiumFeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.featureName,
    this.showLockedOverlay = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(featureGateProvider(feature));

    // If user has access, render child directly
    if (hasAccess) {
      return child;
    }

    // If locked, show overlay or dimmed variant
    if (showLockedOverlay) {
      return _buildLockedOverlay(context);
    } else {
      return _buildDimmedChild(context);
    }
  }

  Widget _buildLockedOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = ResponsiveSizing.of(context);
    final colorScheme = theme.colorScheme;
    final displayName = featureName ?? _getFeatureDisplayName(feature);

    return Stack(
      children: [
        // Dimmed child
        Opacity(
          opacity: 0.3,
          child: child,
        ),
        // Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withAlpha(230),
              border: Border.all(
                color: AppColors.getPrimaryColor(context).withAlpha(77),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(responsive.spacingSm),
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(responsive.spacingMd),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: responsive.iconSize * 2,
                      color: AppColors.getPrimaryColor(context),
                    ),
                    SizedBox(height: responsive.spacingSm),
                    Text(
                      'Premium Feature',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: responsive.spacingXs),
                    Text(
                      'Upgrade to edit $displayName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: responsive.spacingMd),
                    FilledButton.icon(
                      onPressed: () => UpgradeSheet.show(
                        context,
                        featureName: displayName,
                      ),
                      icon: const Icon(Icons.star_rounded),
                      label: const Text('Upgrade'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDimmedChild(BuildContext context) {
    final displayName = featureName ?? _getFeatureDisplayName(feature);

    return GestureDetector(
      onTap: () => UpgradeSheet.show(
        context,
        featureName: displayName,
      ),
      child: Opacity(
        opacity: 0.5,
        child: child,
      ),
    );
  }

  String _getFeatureDisplayName(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.editCycleSettings:
        return 'Cycle Settings';
      case PremiumFeature.unlimitedHistory:
        return 'Unlimited History';
      case PremiumFeature.advancedInsights:
        return 'Advanced Insights';
      case PremiumFeature.exportReports:
        return 'Export Reports';
      case PremiumFeature.customAffirmations:
        return 'Custom Affirmations';
      case PremiumFeature.adFree:
        return 'Ad-Free Experience';
    }
  }
}
