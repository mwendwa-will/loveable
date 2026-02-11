import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lunara/services/pin_service.dart';
import 'package:lunara/constants/app_colors.dart';
import 'package:lunara/utils/responsive_utils.dart';
import 'package:lunara/core/feedback/feedback_service.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isChangeMode;
  const PinSetupScreen({super.key, this.isChangeMode = false});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pinService = PinService();
  final _oldPin = List<String>.filled(4, '');
  final _pin = List<String>.filled(4, '');
  final _confirmPin = List<String>.filled(4, '');

  bool _isVerifyingOldPin = false;
  bool _isConfirmMode = false;
  int _currentIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isVerifyingOldPin = widget.isChangeMode;
  }

  void _onNumberPressed(String number) {
    if (_isLoading) return;

    setState(() {
      if (_isVerifyingOldPin) {
        if (_currentIndex < 4) {
          _oldPin[_currentIndex] = number;
          _currentIndex++;
          if (_currentIndex == 4) {
            _verifyOldPin();
          }
        }
      } else if (!_isConfirmMode) {
        if (_currentIndex < 4) {
          _pin[_currentIndex] = number;
          _currentIndex++;

          if (_currentIndex == 4) {
            // Move to confirm mode
            Future.delayed(const Duration(milliseconds: 300), () {
              setState(() {
                _isConfirmMode = true;
                _currentIndex = 0;
              });
            });
          }
        }
      } else {
        if (_currentIndex < 4) {
          _confirmPin[_currentIndex] = number;
          _currentIndex++;

          if (_currentIndex == 4) {
            // Verify PINs match
            _verifyAndSetPin();
          }
        }
      }
    });

    HapticFeedback.lightImpact();
  }

  Future<void> _verifyOldPin() async {
    setState(() => _isLoading = true);
    final isCorrect = await _pinService.verifyPin(_oldPin.join());

    if (mounted) {
      if (isCorrect) {
        HapticFeedback.mediumImpact();
        setState(() {
          _isVerifyingOldPin = false;
          _currentIndex = 0;
          _isLoading = false;
        });
      } else {
        HapticFeedback.heavyImpact();
        FeedbackService.showError(context, Exception('Incorrect current PIN'));
        setState(() {
          _oldPin.fillRange(0, 4, '');
          _currentIndex = 0;
          _isLoading = false;
        });
      }
    }
  }

  void _onBackspace() {
    if (_isLoading) return;

    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
        if (!_isConfirmMode) {
          _pin[_currentIndex] = '';
        } else {
          _confirmPin[_currentIndex] = '';
        }
      }
    });

    HapticFeedback.lightImpact();
  }

  Future<void> _verifyAndSetPin() async {
    setState(() => _isLoading = true);

    final pinString = _pin.join();
    final confirmString = _confirmPin.join();

    if (pinString != confirmString) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        FeedbackService.showError(
          context,
          Exception('PINs don\'t match - let\'s try again'),
        );
      }

      // Reset to start
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _pin.fillRange(0, 4, '');
        _confirmPin.fillRange(0, 4, '');
        _isConfirmMode = false;
        _currentIndex = 0;
        _isLoading = false;
      });
      return;
    }

    try {
      await _pinService.setPin(pinString);
      HapticFeedback.mediumImpact();

      if (mounted) {
        FeedbackService.showSuccess(
          context,
          'PIN enabled! Your data is now protected',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        FeedbackService.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up PIN'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.responsive.spacingLg),
          child: Column(
            children: [
              const Spacer(),

              // Title and instructions
              FaIcon(FontAwesomeIcons.lock, size: 48, color: AppColors.primary),
              SizedBox(height: context.responsive.spacingLg),
              Text(
                _isVerifyingOldPin
                    ? 'Verify Current PIN'
                    : (_isConfirmMode
                          ? 'Confirm your PIN'
                          : 'Create a 4-digit PIN'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.responsive.spacingSm),
              Text(
                _isVerifyingOldPin
                    ? 'Enter your current PIN to continue'
                    : (_isConfirmMode
                          ? 'Enter your PIN again to confirm'
                          : 'Keep your wellness data private and secure'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: context.responsive.spacingXl),

              // PIN dots display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final pins = _isVerifyingOldPin
                      ? _oldPin
                      : (_isConfirmMode ? _confirmPin : _pin);
                  final isFilled = pins[index].isNotEmpty;

                  return Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: context.responsive.spacingSm,
                    ),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isFilled
                            ? AppColors.primary
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
            child: const FaIcon(FontAwesomeIcons.deleteLeft, size: 24),
          );
        }

        return _buildButton(
          onTap: () => _onNumberPressed(number),
          child: Text(
            number,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildButton({required VoidCallback onTap, required Widget child}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
