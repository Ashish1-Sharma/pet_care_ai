import 'package:ai_pet_care/models/ai_response_model.dart';
import 'package:ai_pet_care/models/history_model.dart';
import 'package:ai_pet_care/models/reminder.dart';
import 'package:ai_pet_care/models/user_model.dart';
import 'package:ai_pet_care/screens/payment/paywall_screen.dart';
import 'package:ai_pet_care/services/iap_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() {
  group('UserModel', () {
    test('parses plan, limits and pets from the profile response', () {
      final user = UserModel.fromJson({
        'id': 7,
        'name': 'Alex',
        'email': 'a@example.com',
        'remainingScans': 2,
        'isPlus': true,
        'plan': {
          'productId': 'petcare_plus_yearly',
          'status': 'active',
          'expiresAt': '2027-10-06T00:00:00.000Z',
          'autoRenewing': true,
          'isTrial': true,
        },
        'chatRemainingToday': null,
        'chatDailyLimit': null,
        'referralCode': 'ALEX-B2K9C1',
        'pets': [
          {'id': 'p1', 'name': 'Buddy', 'type': 'Dog', 'breed': 'Golden Retriever', 'age': '3 years'},
        ],
      });

      expect(user.isPlus, isTrue);
      expect(user.canScan, isTrue);
      expect(user.plan!.isYearly, isTrue);
      expect(user.plan!.isTrial, isTrue);
      expect(user.chatRemainingToday, isNull);
      expect(user.pets.single.subtitle, 'Dog · Golden Retriever · 3 years');
    });

    test('free user with no scans cannot scan, and survives a JSON round trip', () {
      final user = UserModel.fromJson({'id': 1, 'remainingScans': 0, 'chatRemainingToday': 3});
      expect(user.canScan, isFalse);
      final again = UserModel.fromJson(user.toJson());
      expect(again.chatRemainingToday, 3);
      expect(again.isPlus, isFalse);
    });
  });

  group('Scan responses', () {
    test('reads the true balance, scan id and series from /analyze', () {
      final response = AiResponseModel.fromJson({
        'scan': {
          'id': 42,
          'recoveryOf': 40,
          'aiResponse': {'criticality': 'Moderate', 'possibleConditions': []},
        },
        'aiResponse': {'criticality': 'Moderate'},
        'remainingScans': 4,
        'isPlus': false,
      });
      expect(response.remainingScans, 4);
      expect(response.scanId, '42');
      expect(response.recoveryOf, '40');
    });

    test('history items group into recovery series', () {
      final first = HistoryItem.fromJson({'id': 10, 'createdAt': '2026-10-01T00:00:00Z'});
      final followUp = HistoryItem.fromJson({'id': 11, 'recoveryOf': 10, 'createdAt': '2026-10-04T00:00:00Z'});
      expect(first.seriesId, '10');
      expect(followUp.seriesId, '10');
    });
  });

  group('Reminders', () {
    test('repeat intervals roll forward', () {
      final start = DateTime(2026, 1, 15, 9);
      expect(ReminderRepeat.weekly.next(start), DateTime(2026, 1, 22, 9));
      expect(ReminderRepeat.monthly.next(start), DateTime(2026, 2, 15, 9));
      expect(ReminderRepeat.quarterly.next(start), DateTime(2026, 4, 15, 9));
      expect(ReminderRepeat.yearly.next(start), DateTime(2027, 1, 15, 9));
    });

    test('round-trips through JSON', () {
      final r = Reminder(
        id: 1000,
        title: 'Hot spot',
        petName: 'Buddy',
        dueAt: DateTime(2026, 10, 9, 9),
        repeat: ReminderRepeat.monthly,
        recoveryScanId: '10',
      );
      final again = Reminder.fromJson(r.toJson());
      expect(again.isRecovery, isTrue);
      expect(again.repeat, ReminderRepeat.monthly);
      expect(again.dueAt, r.dueAt);
    });
  });

  group('Pricing', () {
    test('per-unit price keeps the store currency symbol', () {
      expect(PaywallScreen.perUnit(r'$29.99', 29.99, 52), r'$0.58');
      expect(PaywallScreen.perUnit('₹499.00', 499, 5), '₹99.80');
    });

    test('a subscription without offer details falls back to its price', () {
      final details = [
        ProductDetails(
          id: 'petcare_plus_weekly',
          title: 'Weekly',
          description: '',
          price: r'$4.99',
          rawPrice: 4.99,
          currencyCode: 'USD',
        ),
      ];
      final offers = IapService.plusOffers(details);
      expect(offers.single.plan.period, 'week');
      expect(offers.single.recurringPrice, r'$4.99');
      expect(offers.single.hasTrial, isFalse);
    });
  });
}
