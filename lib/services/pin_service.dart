import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service for managing app-specific PIN security
/// Provides secure PIN storage and verification for app privacy
class PinService {
  static const _storage = FlutterSecureStorage();
  static const _pinKey = 'app_pin_hash';
  static const _pinEnabledKey = 'pin_enabled';
  static const _lockTimestampKey = 'lock_timestamp';
  
  /// Timeout duration before automatic logout (30 minutes)
  /// Similar to banking apps for enhanced security
  static const timeoutDuration = Duration(minutes: 30);

  /// Check if PIN lock is enabled
  Future<bool> isPinEnabled() async {
    final enabled = await _storage.read(key: _pinEnabledKey);
    return enabled == 'true';
  }

  /// Set PIN enabled/disabled state
  Future<void> setPinEnabled(bool enabled) async {
    await _storage.write(key: _pinEnabledKey, value: enabled.toString());
  }

  /// Hash PIN using SHA-256 for secure storage
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Set new PIN (hashed before storage)
  Future<void> setPin(String pin) async {
    if (pin.length != 4) {
      throw Exception('PIN must be exactly 4 digits');
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw Exception('PIN must contain only digits');
    }
    
    final hashedPin = _hashPin(pin);
    await _storage.write(key: _pinKey, value: hashedPin);
    await setPinEnabled(true);
  }

  /// Verify entered PIN against stored hash
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _pinKey);
    if (storedHash == null) {
      return false;
    }
    
    final enteredHash = _hashPin(pin);
    return storedHash == enteredHash;
  }

  /// Check if PIN is set
  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _pinKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Remove PIN (for disabling or changing)
  Future<void> removePin() async {
    await _storage.delete(key: _pinKey);
    await setPinEnabled(false);
  }

  /// Change existing PIN (requires old PIN verification)
  Future<bool> changePin(String oldPin, String newPin) async {
    final isOldPinCorrect = await verifyPin(oldPin);
    if (!isOldPinCorrect) {
      return false;
    }
    
    await setPin(newPin);
    return true;
  }

  /// Save timestamp when app is locked
  Future<void> saveLockTimestamp() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _storage.write(key: _lockTimestampKey, value: timestamp);
  }

  /// Check if timeout has been exceeded
  /// Returns true if app has been locked longer than timeout duration
  Future<bool> hasTimeoutExceeded() async {
    final timestampStr = await _storage.read(key: _lockTimestampKey);
    if (timestampStr == null) {
      return false;
    }

    final lockTime = DateTime.fromMillisecondsSinceEpoch(
      int.parse(timestampStr),
    );
    final now = DateTime.now();
    final elapsed = now.difference(lockTime);

    return elapsed > timeoutDuration;
  }

  /// Clear lock timestamp
  Future<void> clearLockTimestamp() async {
    await _storage.delete(key: _lockTimestampKey);
  }
}
