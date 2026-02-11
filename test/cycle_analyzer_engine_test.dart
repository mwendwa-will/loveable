import 'package:flutter_test/flutter_test.dart';
import 'package:lunara/services/cycle_analyzer.dart';

void main() {
  final engine = CycleAnalyzerEngine();

  test('calculateSimpleAverage returns 28.0 for empty list', () {
    expect(engine.calculateSimpleAverage(<int>[]), 28.0);
  });

  test('calculateSimpleAverage computes mean correctly', () {
    final avg = engine.calculateSimpleAverage([26, 28, 30]);
    expect(avg, closeTo(28.0, 1e-9));
  });

  test('calculateVariability is zero for single data point', () {
    expect(engine.calculateVariability([28]), 0.0);
  });

  test('calculateVariability computes non-zero for spread data', () {
    final varval = engine.calculateVariability([25, 30, 28]);
    expect(varval, greaterThan(0.0));
  });

  test('calculateConfidence high for low variance', () {
    final conf = engine.calculateConfidence([28, 28, 28]);
    expect(conf, closeTo(0.95, 1e-9));
  });

  test('calculateConfidence lower for high variance', () {
    final conf = engine.calculateConfidence([20, 30, 40, 50]);
    expect(conf, lessThan(0.8));
  });

  test('detectCycleShift true when difference >2 and low variability', () {
    final shifted = engine.detectCycleShift(
      baseline: 28.0,
      recent: 31.0,
      variability: 1.0,
    );
    expect(shifted, isTrue);
  });

  test('detectCycleShift false when variability is high', () {
    final shifted = engine.detectCycleShift(
      baseline: 28.0,
      recent: 32.0,
      variability: 5.0,
    );
    expect(shifted, isFalse);
  });
}
