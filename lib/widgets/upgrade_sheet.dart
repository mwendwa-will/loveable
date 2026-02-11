import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunara/constants/app_colors.dart';
import 'package:lunara/constants/subscription_config.dart';
import 'package:lunara/providers/subscription_provider.dart';
import 'package:lunara/utils/responsive_utils.dart';

/// Upgrade sheet to promote Premium subscription
class UpgradeSheet extends ConsumerStatefulWidget {
  final String? featureName;

  const UpgradeSheet({
    super.key,
    this.featureName,
  });

  /// Show the upgrade sheet as a modal bottom sheet
  static Future<void> show(
    BuildContext context, {
    String? featureName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UpgradeSheet(featureName: featureName),
    );
  }

  @override
  ConsumerState<UpgradeSheet> createState() => _UpgradeSheetState();
}

class _UpgradeSheetState extends ConsumerState<UpgradeSheet> {
  bool _isYearly = true; // Default to yearly (better value)
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = ResponsiveSizing.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(responsive.spacingLg),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(responsive.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(responsive, colorScheme),
              SizedBox(height: responsive.spacingMd),
              _buildHeader(theme, responsive),
              SizedBox(height: responsive.spacingLg),
              _buildBillingToggle(theme, responsive, colorScheme),
              SizedBox(height: responsive.spacingLg),
              _buildPriceCard(theme, responsive, context),
              SizedBox(height: responsive.spacingLg),
              _buildFeatureChecklist(theme, responsive, context),
              SizedBox(height: responsive.spacingLg),
              _buildCTA(theme, responsive, colorScheme),
              SizedBox(height: responsive.spacingSm),
              _buildSubtitle(theme, responsive, colorScheme),
              SizedBox(height: responsive.spacingMd),
              _buildMaybeLater(theme, responsive),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(ResponsiveSizing responsive, ColorScheme colorScheme) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant.withAlpha(77),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ResponsiveSizing responsive) {
    return Column(
      children: [
        Icon(
          Icons.workspace_premium_rounded,
          size: responsive.iconSize * 2,
          color: AppColors.getPrimaryColor(context),
        ),
        SizedBox(height: responsive.spacingSm),
        Text(
          'Upgrade to Premium',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.featureName != null) ...[
          SizedBox(height: responsive.spacingXs),
          Text(
            'Unlock "${widget.featureName}" and all premium features',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildBillingToggle(
    ThemeData theme,
    ResponsiveSizing responsive,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(responsive.spacingSm),
      ),
      padding: EdgeInsets.all(responsive.spacingXs),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleOption(
              label: 'Monthly',
              isSelected: !_isYearly,
              onTap: () => setState(() => _isYearly = false),
              theme: theme,
              responsive: responsive,
              colorScheme: colorScheme,
            ),
          ),
          SizedBox(width: responsive.spacingXs),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildToggleOption(
                  label: 'Yearly',
                  isSelected: _isYearly,
                  onTap: () => setState(() => _isYearly = true),
                  theme: theme,
                  responsive: responsive,
                  colorScheme: colorScheme,
                ),
                Positioned(
                  top: -responsive.spacingSm,
                  right: -responsive.spacingXs,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacingXs,
                      vertical: responsive.spacingXs / 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(responsive.spacingXs),
                    ),
                    child: Text(
                      'Save 33%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required ResponsiveSizing responsive,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: responsive.spacingSm),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(responsive.spacingXs),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPriceCard(
    ThemeData theme,
    ResponsiveSizing responsive,
    BuildContext context,
  ) {
    final price = _isYearly
        ? '\$${premiumTier.yearlyPrice.toStringAsFixed(2)} / year'
        : '\$${premiumTier.monthlyPrice.toStringAsFixed(2)} / month';

    final subtitle = _isYearly
        ? '\$${premiumTier.yearlyMonthlyEquivalent.toStringAsFixed(2)}/mo when billed annually'
        : 'Billed monthly';

    return Container(
      padding: EdgeInsets.all(responsive.spacingMd),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.getPrimaryColor(context),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(responsive.spacingSm),
      ),
      child: Column(
        children: [
          Text(
            price,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.getPrimaryColor(context),
            ),
          ),
          SizedBox(height: responsive.spacingXs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChecklist(
    ThemeData theme,
    ResponsiveSizing responsive,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: premiumTier.features.map((feature) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: responsive.spacingXs),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: responsive.iconSize,
                color: AppColors.getPrimaryColor(context),
              ),
              SizedBox(width: responsive.spacingSm),
              Expanded(
                child: Text(
                  feature,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCTA(
    ThemeData theme,
    ResponsiveSizing responsive,
    ColorScheme colorScheme,
  ) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isLoading ? null : _handleStartTrial,
        child: _isLoading
            ? SizedBox(
                height: responsive.iconSize,
                width: responsive.iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.onPrimary,
                  ),
                ),
              )
            : Text('Start 48-Hour Free Trial'),
      ),
    );
  }

  Widget _buildSubtitle(
    ThemeData theme,
    ResponsiveSizing responsive,
    ColorScheme colorScheme,
  ) {
    return Text(
      'Cancel anytime. 48-hour full access.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMaybeLater(ThemeData theme, ResponsiveSizing responsive) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Maybe Later'),
    );
  }

  Future<void> _handleStartTrial() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(subscriptionProvider.notifier).startFreeTrial();

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎉 Trial activated! Enjoy 48 hours of Premium'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to start trial: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
