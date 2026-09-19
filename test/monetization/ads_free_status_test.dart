import 'package:flutter_test/flutter_test.dart';
import 'package:test_1/monetization/ads_free_status.dart';

void main() {
  group('AdsFreeStatus', () {
    test('inactif quand suppressedUntil est null', () {
      const status = AdsFreeStatus(null);
      final now = DateTime(2026, 1, 1, 12, 0);

      expect(status.isActive(now: now), isFalse);
      expect(status.remaining(now: now), isNull);
    });

    test('actif quand suppressedUntil est dans le futur', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      final until = now.add(const Duration(minutes: 30));
      final status = AdsFreeStatus(until);

      expect(status.isActive(now: now), isTrue);
      expect(status.remaining(now: now), const Duration(minutes: 30));
    });

    test('inactif dès l\'instant d\'expiration (limite stricte)', () {
      final until = DateTime(2026, 1, 1, 12, 0);
      final status = AdsFreeStatus(until);

      // now == until : DateTime.isAfter est strict, plus d'expiration.
      expect(status.isActive(now: until), isFalse);
    });

    test('inactif après expiration', () {
      final until = DateTime(2026, 1, 1, 12, 0);
      final now = until.add(const Duration(seconds: 1));
      final status = AdsFreeStatus(until);

      expect(status.isActive(now: now), isFalse);
      expect(status.remaining(now: now), isNull);
    });
  });
}
