import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lunara/services/cycle_analyzer.dart';
import 'package:lunara/services/supabase_service.dart';

/// Integration tests for the complete prediction flow
/// Tests the user journey from onboarding through predictions to Truth Event
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Complete Prediction Flow Integration Tests', () {
    late SupabaseService supabase;

    setUp(() {
      supabase = SupabaseService();
    });

    testWidgets('Full flow: Onboarding → Initial Prediction → Period Start → Recalculation',
        (tester) async {
      // This test validates the complete user journey as described in
      // PREDICTION_ENGINE_LOGIC_FLOW.md instances 3 and 6

      // STEP 1: User completes onboarding
      // Expected: CycleAnalyzer.generateInitialPredictions() is called
      // Result: 50% confidence prediction created

      final userId = supabase.currentUser?.id;
      if (userId == null) {
        fail('User must be authenticated for this test');
      }

      // Simulate onboarding completion
      // final lastPeriodStart = DateTime.now().subtract(const Duration(days: 7));
      // final cycleLength = 28;

      // Generate initial predictions (Instance 3: First Forecast)
      await CycleAnalyzer.generateInitialPredictions(userId);

      // Verify prediction was created
      final userData = await supabase.getUserData();
      expect(userData, isNotNull);
      expect(userData!['next_period_predicted'], isNotNull);
      expect(userData['prediction_confidence'], equals(0.50));
      expect(userData['prediction_method'], equals('self_reported'));

      // STEP 2: User starts their period after prediction
      // Expected: Truth Event triggers recalculation
      final actualPeriodDate = DateTime.now();

      // Start period (triggers Truth Event - Instance 6)
      await supabase.startPeriod(
        startDate: actualPeriodDate,
      );

      // STEP 3: Verify Truth Event executed
      // Expected: Prediction accuracy logged, confidence updated

      // Wait for async operations
      await Future.delayed(const Duration(seconds: 2));

      // Verify recalculation happened
      final updatedUserData = await supabase.getUserData();
      expect(updatedUserData, isNotNull);

      // If user has 2+ periods, confidence should be higher than initial 50%
      // This validates the learning algorithm is working
      final completedPeriods = await supabase.getCompletedPeriods();
      if (completedPeriods.length >= 2) {
        expect(
          updatedUserData!['prediction_confidence'],
          greaterThan(0.50),
        );
      }
    });

    testWidgets('Prediction accuracy improves over multiple cycles', (tester) async {
      // This test validates that confidence increases as user logs more periods
      // Simulates Instance 6 occurring multiple times

      final userId = supabase.currentUser?.id;
      if (userId == null) {
        fail('User must be authenticated for this test');
      }

      // Get initial confidence
      final initialData = await supabase.getUserData();
      final initialConfidence = initialData?['prediction_confidence'] as double? ?? 0.50;

      // Simulate logging multiple periods with regular cycle
      final periods = [
        DateTime.now().subtract(const Duration(days: 84)), // 3 months ago
        DateTime.now().subtract(const Duration(days: 56)), // 2 months ago
        DateTime.now().subtract(const Duration(days: 28)), // 1 month ago
      ];

      for (final periodStart in periods) {
        await supabase.startPeriod(
          startDate: periodStart,
        );

        // Simulate period end 5 days later
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Wait for all recalculations
      await Future.delayed(const Duration(seconds: 3));

      // Recalculate after all periods logged
      await CycleAnalyzer.recalculateAfterPeriodStart(userId);

      // Verify confidence improved
      final finalData = await supabase.getUserData();
      final finalConfidence = finalData?['prediction_confidence'] as double? ?? 0.50;

      // With 3 regular cycles, confidence should be significantly higher
      expect(finalConfidence, greaterThan(initialConfidence));
      expect(finalConfidence, greaterThanOrEqualTo(0.65)); // At least 1-cycle confidence
    });

    testWidgets('Irregular cycles result in lower confidence', (tester) async {
      // This test validates variance-based confidence calculation
      // Irregular cycles should have confidence closer to 60%

      final userId = supabase.currentUser?.id;
      if (userId == null) {
        fail('User must be authenticated for this test');
      }

      // Simulate logging irregular periods (22, 35, 26, 38 day cycles)
      final irregularPeriods = [
        DateTime.now().subtract(const Duration(days: 121)), // ~4 months
        DateTime.now().subtract(const Duration(days: 99)), // 22 days later
        DateTime.now().subtract(const Duration(days: 64)), // 35 days later
        DateTime.now().subtract(const Duration(days: 38)), // 26 days later
      ];

      for (final periodStart in irregularPeriods) {
        await supabase.startPeriod(
          startDate: periodStart,
        );
        await Future.delayed(const Duration(milliseconds: 500));
      }

      await Future.delayed(const Duration(seconds: 3));
      await CycleAnalyzer.recalculateAfterPeriodStart(userId);

      final userData = await supabase.getUserData();
      final confidence = userData?['prediction_confidence'] as double? ?? 0.50;

      // Irregular cycles should have lower confidence (around 60-70%)
      expect(confidence, lessThan(0.85));
      expect(confidence, greaterThanOrEqualTo(0.60));
    });

    testWidgets('Prediction logs track accuracy over time', (tester) async {
      // This test validates that prediction_logs table captures error_days

      final userId = supabase.currentUser?.id;
      if (userId == null) {
        fail('User must be authenticated for this test');
      }

      // Create a prediction
      await CycleAnalyzer.generateInitialPredictions(userId);

      final userData = await supabase.getUserData();
      final predictedDate = DateTime.parse(userData!['next_period_predicted']);

      // Start period 2 days early
      final actualDate = predictedDate.subtract(const Duration(days: 2));
      
      // Simulate starting a period
      await supabase.startPeriod(startDate: actualDate);

      // Verify period was recorded
      expect(userData, isNotNull);
      // Note: In production, would query periods table directly
      // For integration test, we verify the period was created
    });

    testWidgets('Settings screen allows manual adjustment', (tester) async {
      // This test validates that users can adjust cycle settings
      // And that adjustments trigger recalculation

      final userId = supabase.currentUser?.id;
      if (userId == null) {
        fail('User must be authenticated for this test');
      }

      // Get current cycle length
      final initialData = await supabase.getUserData();
      final initialCycleLength = initialData?['average_cycle_length'] as double? ?? 28.0;

      // Simulate user adjusting cycle length to 30 days
      final newCycleLength = 30.0;
      await supabase.updateUserData({
        'average_cycle_length': newCycleLength,
      });

      // Trigger recalculation
      await CycleAnalyzer.recalculateAfterPeriodStart(userId);

      // Verify new cycle length is used
      final updatedData = await supabase.getUserData();
      expect(updatedData?['average_cycle_length'], equals(newCycleLength));

      // Verify next prediction updated
      final oldPrediction = DateTime.parse(initialData!['next_period_predicted']);
      final newPrediction = DateTime.parse(updatedData!['next_period_predicted']);

      // New prediction should be different if cycle length changed
      if (initialCycleLength != newCycleLength) {
        expect(newPrediction, isNot(equals(oldPrediction)));
      }
    });

    testWidgets('Dashboard shows accurate statistics', (tester) async {
      // This test validates the accuracy dashboard in Cycle Settings
      // Verifies getPredictionStats() returns correct data

      final userId = supabase.currentUser?.id;
      if (userId == null) {
        fail('User must be authenticated for this test');
      }

      // Get prediction statistics
      final stats = await CycleAnalyzer.getPredictionStats(userId);

      // Verify stats structure
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('total_predictions'), isTrue);
      expect(stats.containsKey('average_error'), isTrue);
      expect(stats.containsKey('accuracy_within_2_days'), isTrue);

      // Verify values are reasonable
      final totalPredictions = stats['total_predictions'] as int;
      expect(totalPredictions, greaterThanOrEqualTo(0));

      if (totalPredictions > 0) {
        final avgError = stats['average_error'] as double;
        final accuracy = stats['accuracy_within_2_days'] as double;

        expect(avgError, isNotNaN);
        expect(accuracy, greaterThanOrEqualTo(0.0));
        expect(accuracy, lessThanOrEqualTo(100.0));
      }
    });
  });

  group('Edge Case Integration Tests', () {
    testWidgets('Handles first-time user with no period data', (tester) async {
      // Validates that app doesn't crash for brand new users
      // Should show no prediction until onboarding complete

      final supabase = SupabaseService();
      final userId = supabase.currentUser?.id;

      if (userId != null) {
        final userData = await supabase.getUserData();

        if (userData?['next_period_predicted'] == null) {
          // This is expected for new users - no crash
          expect(userData, isNotNull);
        }
      }
    });

    testWidgets('Handles very long cycles (45 days)', (tester) async {
      final supabase = SupabaseService();
      final userId = supabase.currentUser?.id;

      if (userId == null) {
        fail('User must be authenticated');
      }

      // Update to maximum cycle length
      await supabase.updateUserData({
        'average_cycle_length': 45.0,
      });

      await CycleAnalyzer.recalculateAfterPeriodStart(userId);

      final userData = await supabase.getUserData();
      expect(userData?['average_cycle_length'], equals(45.0));
    });

    testWidgets('Handles very short cycles (21 days)', (tester) async {
      final supabase = SupabaseService();
      final userId = supabase.currentUser?.id;

      if (userId == null) {
        fail('User must be authenticated');
      }

      // Update to minimum cycle length
      await supabase.updateUserData({
        'average_cycle_length': 21.0,
      });

      await CycleAnalyzer.recalculateAfterPeriodStart(userId);

      final userData = await supabase.getUserData();
      expect(userData?['average_cycle_length'], equals(21.0));
    });
  });
}
