import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunara/services/pin_service.dart';

/// State for PIN lock feature
class PinLockState {
  final bool isEnabled;
  final bool isLocked;
  final bool hasPin;

  const PinLockState({
    required this.isEnabled,
    required this.isLocked,
    required this.hasPin,
  });

  PinLockState copyWith({
    bool? isEnabled,
    bool? isLocked,
    bool? hasPin,
  }) {
    return PinLockState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
      hasPin: hasPin ?? this.hasPin,
    );
  }
}

/// Provider for managing PIN lock state
class PinLockNotifier extends Notifier<PinLockState> {
  PinService get _pinService => PinService();

  @override
  PinLockState build() {
    _initialize();
    return const PinLockState(
      isEnabled: false,
      isLocked: false,
      hasPin: false,
    );
  }

  Future<void> _initialize() async {
    final isEnabled = await _pinService.isPinEnabled();
    final hasPin = await _pinService.hasPin();
    
    state = PinLockState(
      isEnabled: isEnabled,
      isLocked: isEnabled, // Lock immediately if enabled
      hasPin: hasPin,
    );
  }

  /// Unlock the app (after successful PIN entry)
  Future<void> unlock() async {
    state = state.copyWith(isLocked: false);
    // Clear lock timestamp when successfully unlocked
    await _pinService.clearLockTimestamp();
  }

  /// Lock the app (when app goes to background)
  Future<void> lock() async {
    if (state.isEnabled) {
      state = state.copyWith(isLocked: true);
      // Save timestamp for timeout tracking
      await _pinService.saveLockTimestamp();
    }
  }

  /// Enable PIN lock
  Future<void> enablePin() async {
    await _pinService.setPinEnabled(true);
    final hasPin = await _pinService.hasPin();
    state = state.copyWith(
      isEnabled: true,
      hasPin: hasPin,
      isLocked: true,
    );
  }

  /// Disable PIN lock
  Future<void> disablePin() async {
    await _pinService.removePin();
    state = state.copyWith(
      isEnabled: false,
      isLocked: false,
      hasPin: false,
    );
  }

  /// Refresh state (after PIN setup/change)
  Future<void> refresh() async {
    await _initialize();
  }

  /// Check if timeout has been exceeded
  /// Returns true if user should be logged out
  Future<bool> shouldLogoutDueToTimeout() async {
    if (!state.isEnabled || !state.isLocked) {
      return false;
    }
    return await _pinService.hasTimeoutExceeded();
  }
}

/// Provider instance
final pinLockProvider = NotifierProvider<PinLockNotifier, PinLockState>(() {
  return PinLockNotifier();
});
