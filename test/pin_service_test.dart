import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/services/pin_service.dart';

// Simple in-memory fake storage implementing the minimal API used by PinService
class FakeStorage implements SecureStorageInterface {
  final Map<String, String> _store = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _store[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _store.remove(key);
  }
}

void main() {
  group('PinService', () {
    late FakeStorage inner;
    late PinService service;

    setUp(() {
      inner = FakeStorage();
      service = PinService(storage: inner);
    });

    test('setPin enforces 4 digits', () async {
      expect(() => service.setPin('123'), throwsA(isA<Exception>()));
      expect(() => service.setPin('abcd'), throwsA(isA<Exception>()));
      // valid
      await service.setPin('1234');
      expect(await service.hasPin(), isTrue);
    });

    test('verifyPin works and changePin updates', () async {
      await service.setPin('0000');
      expect(await service.verifyPin('0000'), isTrue);
      expect(await service.verifyPin('1111'), isFalse);

      final changed = await service.changePin('0000', '1234');
      expect(changed, isTrue);
      expect(await service.verifyPin('1234'), isTrue);
    });

    test('setPinEnabled and isPinEnabled', () async {
      await service.setPinEnabled(false);
      expect(await service.isPinEnabled(), isFalse);
      await service.setPinEnabled(true);
      expect(await service.isPinEnabled(), isTrue);
    });

    test('lock timestamp and timeout', () async {
      // write old timestamp (31 minutes ago)
      final old = DateTime.now().subtract(Duration(minutes: 31)).millisecondsSinceEpoch.toString();
      await inner.write(key: 'lock_timestamp', value: old);

      expect(await service.hasTimeoutExceeded(), isTrue);

      // clear and set recent timestamp
      await service.clearLockTimestamp();
      await service.saveLockTimestamp();
      expect(await service.hasTimeoutExceeded(), isFalse);
    });

    test('removePin disables pin', () async {
      await service.setPin('9999');
      expect(await service.hasPin(), isTrue);
      await service.removePin();
      expect(await service.hasPin(), isFalse);
      expect(await service.isPinEnabled(), isFalse);
    });
  });
}
