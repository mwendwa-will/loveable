import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lovely/services/pin_service.dart';
import 'package:lovely/constants/app_colors.dart';
import 'package:lovely/utils/responsive_utils.dart';

class PinUnlockScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;

  const PinUnlockScreen({super.key, this.onUnlocked});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  final _pinService = PinService();
  final _pin = List<String>.filled(4, '');
  int _currentIndex = 0;
  int _failedAttempts = 0;
  bool _isVerifying = false;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    // Prevent going back without unlocking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // This prevents the back button from working
        SystemChannels.platform.setMethodCallHandler((call) async {
          if (call.method == 'SystemNavigator.pop') {
            // Don't allow back navigation
            return;
          }
        });
      }
    });
  }

  void _onNumberPressed(String number) {
    if (_isVerifying) return;

    setState(() {
      if (_currentIndex < 4) {
        _pin[_currentIndex] = number;
        _currentIndex++;
        _showError = false;
        
        if (_currentIndex == 4) {
          _verifyPin();
        }
      }
    });
    
    HapticFeedback.lightImpact();
  }

  void _onBackspace() {
    if (_isVerifying) return;

    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
        _pin[_currentIndex] = '';
        _showError = false;
      }
    });
    
    HapticFeedback.lightImpact();
  }

  Future<void> _verifyPin() async {
    setState(() => _isVerifying = true);

    final pinString = _pin.join();
    final isCorrect = await _pinService.verifyPin(pinString);

    if (isCorrect) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        debugPrint('PIN verified successfully');
        // Call callback if provided (from main.dart)
        // This will handle unlocking and navigation
        widget.onUnlocked?.call();
        
        // If not opened as a route (i.e., initial widget), nothing more needed
        // If opened as a route, the onUnlocked callback should pop
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _failedAttempts++;
        _showError = true;
        _isVerifying = false;
      });

      // Auto clear after showing error
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _pin.fillRange(0, 4, '');
          _currentIndex = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.responsive.spacingLg),
          child: Column(
            children: [
              const Spacer(),
              
              // App logo/icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.heart,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              
              SizedBox(height: context.responsive.spacingLg),
              
              // Title
              Text(
                'Lovely',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: context.responsive.spacingSm),
              
              // Instructions
              Text(
                'Enter your PIN to continue',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              
              if (_showError) ...[
                SizedBox(height: context.responsive.spacingSm),
                Text(
                  _failedAttempts >= 3
                      ? 'Too many failed attempts. Please try again.'
                      : 'Incorrect PIN. Try again.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              
              SizedBox(height: context.responsive.spacingXl),
              
              // PIN dots display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = _pin[index].isNotEmpty;
                  final hasError = _showError && index < _currentIndex;
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(
                      horizontal: context.responsive.spacingSm,
                    ),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? (hasError ? AppColors.error : AppColors.primary)
                          : Colors.transparent,
                      border: Border.all(
                        color: isFilled
                            ? (hasError ? AppColors.error : AppColors.primary)
                            : Theme.of(context).dividerColor,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              
              const Spacer(),
              
              // Number pad
              _buildNumberPad(),
              
              SizedBox(height: context.responsive.spacingLg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        _buildNumberRow(['1', '2', '3']),
        SizedBox(height: context.responsive.spacingMd),
        _buildNumberRow(['4', '5', '6']),
        SizedBox(height: context.responsive.spacingMd),
        _buildNumberRow(['7', '8', '9']),
        SizedBox(height: context.responsive.spacingMd),
        _buildNumberRow(['', '0', 'backspace']),
      ],
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        if (number.isEmpty) {
          return const SizedBox(width: 72, height: 72);
        }
        
        if (number == 'backspace') {
          return _buildButton(
            onTap: _onBackspace,
            child: FaIcon(
              FontAwesomeIcons.deleteLeft,
              size: 24,
              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
            ),
          );
        }
        
        return _buildButton(
          onTap: () => _onNumberPressed(number),
          child: Text(
            number,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isVerifying ? null : onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
