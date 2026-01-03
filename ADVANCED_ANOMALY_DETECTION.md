# Advanced Anomaly Detection Design: Statistical + Context-Aware

This document outlines the sophisticated anomaly detection system for Lovely, based on modern period tracking algorithms that use statistical analysis, biological insights, and machine learning principles.

## Core Principles

1. **Exponential Moving Average**: Recent cycles matter MORE than old ones (decaying weights)
2. **Luteal Constant vs Follicular Variable**: Split cycle into two distinct phases
3. **Symptom-Based Overrides**: The body knows before the spreadsheet does
4. **Context-Aware Classification**: Ask WHY anomalies happen, then exclude intelligently
5. **Confidence Clouds**: Use Gaussian distribution instead of hard predictions

---

## Architecture: Multi-Layer Anomaly Detection

### Layer 1: Statistical Anomaly Detection (The Math)

```dart
// lib/services/cycle_anomaly_detector.dart

class CycleAnomalyDetector {
  /// Detect anomalies using multiple statistical methods
  static Future<AnomalyReport> analyzeForAnomalies(String userId) async {
    final periods = await SupabaseService().getCompletedPeriods(limit: 12);
    
    if (periods.length < 3) {
      return AnomalyReport.notEnoughData();
    }
    
    // 1. EXTRACT CYCLE VECTORS
    final cycleVectors = _buildCycleVectors(periods);
    
    // 2. APPLY WEIGHTED AVERAGING (Exponential Moving Average)
    final weightedMean = _calculateEMA(cycleVectors);
    
    // 3. SPLIT PHASES: Luteal Constant vs Follicular Variable
    final lutealPhases = _extractLutealPhases(cycleVectors);
    final follicularPhases = _extractFollicularPhases(cycleVectors);
    
    // 4. DETECT OUTLIERS
    final cycleLengthOutliers = _detectOutliers(
      cycleVectors.map((v) => v.totalLength).toList(),
      method: OutlierMethod.modifiedZScore,
    );
    
    final lutealOutliers = _detectOutliers(
      lutealPhases,
      method: OutlierMethod.IQR,
    );
    
    final follicularOutliers = _detectOutliers(
      follicularPhases,
      method: OutlierMethod.standardDeviation,
    );
    
    // 5. BUILD ANOMALY REPORT
    return AnomalyReport(
      totalCycles: periods.length,
      cycleLengthAnomalies: cycleLengthOutliers,
      lutealPhaseAnomalies: lutealOutliers,
      follicularPhaseAnomalies: follicularOutliers,
      weightedMean: weightedMean,
      confidenceScore: _calculateConfidence(cycleVectors),
    );
  }
  
  /// Build cycle vectors (multi-dimensional data per cycle)
  static List<CycleVector> _buildCycleVectors(List<Period> periods) {
    final vectors = <CycleVector>[];
    
    for (int i = 0; i < periods.length - 1; i++) {
      final currentPeriod = periods[i];
      final nextPeriod = periods[i + 1];
      
      // Calculate cycle metrics
      final totalLength = nextPeriod.startDate.difference(currentPeriod.startDate).inDays;
      final periodLength = currentPeriod.endDate!.difference(currentPeriod.startDate).inDays + 1;
      
      // LUTEAL CONSTANT: Assume 14 days (can be personalized later)
      final lutealLength = 14;
      
      // FOLLICULAR VARIABLE: Everything else
      final follicularLength = totalLength - lutealLength;
      
      vectors.add(CycleVector(
        cycleNumber: i + 1,
        startDate: currentPeriod.startDate,
        totalLength: totalLength,
        periodLength: periodLength,
        follicularLength: follicularLength,
        lutealLength: lutealLength,
        timestamp: currentPeriod.startDate,
      ));
    }
    
    return vectors;
  }
  
  /// Exponential Moving Average (decaying weights)
  /// Recent cycles matter MORE than old ones
  static double _calculateEMA(List<CycleVector> vectors) {
    if (vectors.isEmpty) return 28.0;
    
    // Alpha = 0.3 (30% weight to new data, 70% to existing trend)
    const alpha = 0.3;
    
    // Start with first cycle
    double ema = vectors.first.totalLength.toDouble();
    
    // Apply exponential decay
    for (int i = 1; i < vectors.length; i++) {
      ema = (alpha * vectors[i].totalLength) + ((1 - alpha) * ema);
    }
    
    return ema;
  }
  
  /// Extract luteal phase lengths (should be CONSTANT ~14 days)
  static List<int> _extractLutealPhases(List<CycleVector> vectors) {
    return vectors.map((v) => v.lutealLength).toList();
  }
  
  /// Extract follicular phase lengths (VARIABLE - stress affects this)
  static List<int> _extractFollicularPhases(List<CycleVector> vectors) {
    return vectors.map((v) => v.follicularLength).toList();
  }
  
  /// Detect outliers using Modified Z-Score (robust to small datasets)
  static List<Outlier> _detectOutliers(
    List<int> data,
    {required OutlierMethod method}
  ) {
    if (data.length < 3) return [];
    
    switch (method) {
      case OutlierMethod.modifiedZScore:
        return _modifiedZScoreMethod(data);
      case OutlierMethod.IQR:
        return _IQRMethod(data);
      case OutlierMethod.standardDeviation:
        return _standardDeviationMethod(data);
    }
  }
  
  /// Modified Z-Score: More robust than regular Z-score
  /// Uses Median Absolute Deviation (MAD) instead of standard deviation
  static List<Outlier> _modifiedZScoreMethod(List<int> data) {
    final outliers = <Outlier>[];
    
    // Calculate median
    final sorted = List<int>.from(data)..sort();
    final median = sorted[sorted.length ~/ 2].toDouble();
    
    // Calculate MAD (Median Absolute Deviation)
    final deviations = data.map((x) => (x - median).abs()).toList()..sort();
    final mad = deviations[deviations.length ~/ 2].toDouble();
    
    // Modified Z-Score threshold: 3.5 (more lenient than regular 3.0)
    const threshold = 3.5;
    
    for (int i = 0; i < data.length; i++) {
      final modifiedZScore = (0.6745 * (data[i] - median)) / mad;
      
      if (modifiedZScore.abs() > threshold) {
        outliers.add(Outlier(
          index: i,
          value: data[i],
          score: modifiedZScore.abs(),
          severity: modifiedZScore.abs() > 5.0 ? Severity.extreme : Severity.moderate,
          method: 'Modified Z-Score',
        ));
      }
    }
    
    return outliers;
  }
  
  /// IQR Method (Interquartile Range) - Classic statistical approach
  static List<Outlier> _IQRMethod(List<int> data) {
    final outliers = <Outlier>[];
    final sorted = List<int>.from(data)..sort();
    
    final q1 = sorted[sorted.length ~/ 4].toDouble();
    final q3 = sorted[(sorted.length * 3) ~/ 4].toDouble();
    final iqr = q3 - q1;
    
    final lowerBound = q1 - (1.5 * iqr);
    final upperBound = q3 + (1.5 * iqr);
    
    for (int i = 0; i < data.length; i++) {
      if (data[i] < lowerBound || data[i] > upperBound) {
        // Calculate severity based on how far outside bounds
        final distance = data[i] < lowerBound 
            ? lowerBound - data[i] 
            : data[i] - upperBound;
        final severity = distance > iqr ? Severity.extreme : Severity.moderate;
        
        outliers.add(Outlier(
          index: i,
          value: data[i],
          score: distance / iqr,
          severity: severity,
          method: 'IQR',
        ));
      }
    }
    
    return outliers;
  }
  
  /// Standard Deviation Method
  static List<Outlier> _standardDeviationMethod(List<int> data) {
    final outliers = <Outlier>[];
    
    final mean = data.reduce((a, b) => a + b) / data.length;
    final variance = data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    final stdDev = sqrt(variance);
    
    // 2 standard deviations = 95% confidence interval
    const threshold = 2.0;
    
    for (int i = 0; i < data.length; i++) {
      final zScore = (data[i] - mean).abs() / stdDev;
      
      if (zScore > threshold) {
        outliers.add(Outlier(
          index: i,
          value: data[i],
          score: zScore,
          severity: zScore > 3.0 ? Severity.extreme : Severity.moderate,
          method: 'Standard Deviation',
        ));
      }
    }
    
    return outliers;
  }
  
  /// Calculate confidence score (0-1)
  /// High confidence = low variance = regular cycles
  static double _calculateConfidence(List<CycleVector> vectors) {
    if (vectors.length < 3) return 0.0;
    
    final lengths = vectors.map((v) => v.totalLength).toList();
    final mean = lengths.reduce((a, b) => a + b) / lengths.length;
    final variance = lengths.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / lengths.length;
    final stdDev = sqrt(variance);
    
    // Inverse relationship: lower stdDev = higher confidence
    // stdDev < 2: confidence = 1.0 (very regular)
    // stdDev = 5: confidence = 0.5 (moderate)
    // stdDev > 10: confidence = 0.0 (very irregular)
    
    if (stdDev < 2) return 1.0;
    if (stdDev > 10) return 0.0;
    
    return 1.0 - (stdDev / 10);
  }
}
```

---

### Layer 2: Context-Aware Classification (The Intelligence)

```dart
/// When anomaly is detected, ASK the user WHY
class AnomalyContextCollector {
  static Future<void> presentAnomalyDialog(Outlier outlier, Period period) async {
    final context = await showDialog<AnomalyContext>(
      builder: (context) => AlertDialog(
        title: Text('Unusual Cycle Detected'),
        content: Column(
          children: [
            Text('This cycle was ${outlier.value} days long'),
            Text('Your typical range: 26-30 days'),
            SizedBox(height: 16),
            Text('Was there a specific reason?', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            
            // CONTEXTUAL OPTIONS
            _buildContextOption(
              icon: Icons.flight_takeoff,
              label: 'Travel / Time Zone Change',
              context: AnomalyReason.travel,
            ),
            _buildContextOption(
              icon: Icons.local_hospital,
              label: 'Illness / Medication',
              context: AnomalyReason.illness,
            ),
            _buildContextOption(
              icon: Icons.mood_bad,
              label: 'High Stress / Major Life Event',
              context: AnomalyReason.stress,
            ),
            _buildContextOption(
              icon: Icons.medication,
              label: 'Emergency Contraception (Plan B)',
              context: AnomalyReason.emergencyContraception,
            ),
            _buildContextOption(
              icon: Icons.fitness_center,
              label: 'Intense Exercise / Diet Change',
              context: AnomalyReason.lifestyle,
            ),
            _buildContextOption(
              icon: Icons.help_outline,
              label: 'Unknown / No Specific Reason',
              context: AnomalyReason.unknown,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Keep in Calculations'),
            onPressed: () => Navigator.pop(context, AnomalyContext.normal()),
          ),
        ],
      ),
    );
    
    if (context != null && context.shouldExclude) {
      // EXCLUDE from future calculations
      await SupabaseService().markPeriodAsAnomaly(
        periodId: period.id,
        reason: context.reason,
        excludeFromStats: true,
      );
      
      // RECALCULATE without this cycle
      await CycleAnalyzer.analyzeCycles(userId);
      
      // SHOW CONFIRMATION
      showSnackBar('Cycle marked as unusual. Your predictions remain accurate.');
    }
  }
}
```

---

### Layer 3: The Luteal Constant Principle

**Biological Insight**: The menstrual cycle has two distinct phases:

1. **Follicular Phase** (Period start → Ovulation): **VARIABLE**
   - Affected by: stress, travel, illness, diet, exercise
   - Can be delayed by days or weeks
   - This is where irregularity happens

2. **Luteal Phase** (Ovulation → Next period): **CONSTANT**
   - Typically 12-14 days, like clockwork
   - Hormonal feedback loop maintains consistency
   - If this varies significantly → potential hormonal issue

```dart
/// ADVANCED: Detect anomalies in LUTEAL vs FOLLICULAR phases separately
class PhaseAnomalyDetector {
  static Future<PhaseAnomalyReport> analyzePhaseAnomalies(String userId) async {
    final vectors = await CycleAnomalyDetector._buildCycleVectors(...);
    
    // LUTEAL PHASE: Should be CONSTANT (12-14 days)
    final lutealPhases = vectors.map((v) => v.lutealLength).toList();
    final lutealMean = lutealPhases.reduce((a, b) => a + b) / lutealPhases.length;
    
    // If luteal phase varies by more than 2 days → RED FLAG
    final lutealAnomalies = lutealPhases.where((length) => 
      (length - lutealMean).abs() > 2
    ).toList();
    
    if (lutealAnomalies.isNotEmpty) {
      // ALERT: Potential hormonal issue
      return PhaseAnomalyReport(
        type: PhaseAnomalyType.lutealVariability,
        message: 'Your luteal phase length varies significantly. This could indicate a hormonal imbalance. Consider consulting a healthcare provider.',
        severity: Severity.high,
        cycles: lutealAnomalies,
      );
    }
    
    // FOLLICULAR PHASE: Can be VARIABLE (stress-affected)
    final follicularPhases = vectors.map((v) => v.follicularLength).toList();
    final follicularOutliers = CycleAnomalyDetector._detectOutliers(
      follicularPhases,
      method: OutlierMethod.IQR,
    );
    
    if (follicularOutliers.isNotEmpty) {
      // This is NORMAL - stress can delay ovulation
      return PhaseAnomalyReport(
        type: PhaseAnomalyType.follicularDelay,
        message: 'Your ovulation was delayed this cycle. Stress, travel, or illness can affect the follicular phase.',
        severity: Severity.low,
        cycles: follicularOutliers.map((o) => o.value).toList(),
      );
    }
    
    return PhaseAnomalyReport.normal();
  }
}
```

---

### Layer 4: Smart Prediction Override (Symptom Logic Wins)

**Principle**: When symptoms historically predict period arrival with high accuracy, trust the body over the math.

```dart
/// When symptoms suggest period is coming, OVERRIDE the math
class SymptomBasedOverride {
  static Future<void> checkForSymptomOverride() async {
    // Get recent symptoms (last 3 days)
    final recentSymptoms = await SupabaseService().getSymptomsInRange(
      startDate: DateTime.now().subtract(Duration(days: 3)),
      endDate: DateTime.now(),
    );
    
    // Get learned patterns
    final patterns = await SymptomCorrelator.getStoredPatterns(userId);
    
    for (final symptom in recentSymptoms) {
      if (patterns.containsKey(symptom.type)) {
        final daysUntilPeriod = patterns[symptom.type]!;
        final predictedStart = symptom.date.add(Duration(days: daysUntilPeriod));
        
        // Get current mathematical prediction
        final userData = await SupabaseService().getUserData();
        final mathPrediction = DateTime.parse(userData['next_period_predicted']);
        
        // OVERRIDE if symptom prediction differs by more than 2 days
        if ((predictedStart.difference(mathPrediction).inDays).abs() > 2) {
          debugPrint('🧠 SYMPTOM OVERRIDE: Math says ${DateFormat('MMM d').format(mathPrediction)}, body says ${DateFormat('MMM d').format(predictedStart)}');
          
          // Update prediction in database
          await SupabaseService().updateNextPeriodPrediction(
            newDate: predictedStart,
            source: 'symptom_pattern',
            confidence: patterns[symptom.type]!['confidence'],
          );
          
          // Reschedule notifications
          await CycleReminderService.rescheduleAllCycleReminders();
          
          // Notify user
          await NotificationService().showNotification(
            title: '💡 Prediction Updated',
            body: 'Based on your ${symptom.type} symptom, your period might start around ${DateFormat('MMM d').format(predictedStart)} instead.',
          );
        }
      }
    }
  }
}
```

---

### Layer 5: Confidence Cloud (Gaussian Distribution)

**Principle**: Biology has noise. Instead of "Your period will start on Friday," show a probability curve.

```dart
/// Generate probability distribution for period start
class ConfidenceCloudGenerator {
  static Map<DateTime, double> generateProbabilityCloud({
    required DateTime predictedDate,
    required double confidenceScore,
  }) {
    final cloud = <DateTime, double>{};
    
    // Standard deviation based on confidence
    // High confidence (0.9+) = σ = 1 day (tight distribution)
    // Low confidence (0.3) = σ = 3 days (wide distribution)
    final sigma = confidenceScore > 0.8 ? 1.0 : 
                  confidenceScore > 0.5 ? 2.0 : 3.0;
    
    // Generate Gaussian curve for ±5 days
    for (int offset = -5; offset <= 5; offset++) {
      final date = predictedDate.add(Duration(days: offset));
      
      // Gaussian formula: (1 / (σ√2π)) * e^(-(x²)/(2σ²))
      final probability = (1 / (sigma * sqrt(2 * pi))) * 
                         exp(-pow(offset, 2) / (2 * pow(sigma, 2)));
      
      cloud[date] = probability;
    }
    
    // Normalize to percentages
    final maxProb = cloud.values.reduce((a, b) => a > b ? a : b);
    cloud.forEach((date, prob) {
      cloud[date] = (prob / maxProb) * 100; // Convert to 0-100%
    });
    
    return cloud;
  }
  
  /// Display on calendar as "red glow"
  static Color getCloudColorForDate(DateTime date, Map<DateTime, double> cloud) {
    final probability = cloud[_normalizeDate(date)] ?? 0.0;
    
    // Graduated opacity based on probability
    if (probability >= 80) return AppColors.getMenstrualPhaseColor(context); // Darkest (most likely day)
    if (probability >= 50) return AppColors.getMenstrualPhaseColor(context).withOpacity(0.7);
    if (probability >= 20) return AppColors.getMenstrualPhaseColor(context).withOpacity(0.4);
    if (probability >= 5) return AppColors.getMenstrualPhaseColor(context).withOpacity(0.2);
    
    return Colors.transparent; // No glow (unlikely)
  }
}
```

**Visual Result**:
```
Calendar View:
  Wed (Day 26): Light pink glow (20% probability)
  Thu (Day 27): Medium pink glow (50% probability)
  Fri (Day 28): DARK RED (80% probability) ← Most likely
  Sat (Day 29): Medium pink glow (50% probability)
  Sun (Day 30): Light pink glow (20% probability)
```

---

## Data Models

```dart
// lib/models/cycle_vector.dart
class CycleVector {
  final int cycleNumber;
  final DateTime startDate;
  final int totalLength;        // Full cycle length
  final int periodLength;       // Bleeding days
  final int follicularLength;   // Variable (stress-affected)
  final int lutealLength;       // Constant (~14 days)
  final DateTime timestamp;
  
  CycleVector({
    required this.cycleNumber,
    required this.startDate,
    required this.totalLength,
    required this.periodLength,
    required this.follicularLength,
    required this.lutealLength,
    required this.timestamp,
  });
}

// lib/models/outlier.dart
class Outlier {
  final int index;              // Which cycle (0-indexed)
  final int value;              // The outlier value (e.g., 45 days)
  final double score;           // Z-score or distance metric
  final Severity severity;      // moderate, high, extreme
  final String method;          // Detection method used
  
  Outlier({
    required this.index,
    required this.value,
    required this.score,
    required this.severity,
    required this.method,
  });
}

enum Severity { low, moderate, high, extreme }
enum OutlierMethod { modifiedZScore, IQR, standardDeviation }

// lib/models/anomaly_context.dart
class AnomalyContext {
  final AnomalyReason reason;
  final bool shouldExclude;
  final String? userNote;
  
  AnomalyContext({
    required this.reason,
    required this.shouldExclude,
    this.userNote,
  });
  
  factory AnomalyContext.normal() => AnomalyContext(
    reason: AnomalyReason.none,
    shouldExclude: false,
  );
}

enum AnomalyReason {
  none,
  travel,
  illness,
  stress,
  emergencyContraception,
  lifestyle,
  unknown,
}

// lib/models/anomaly_report.dart
class AnomalyReport {
  final int totalCycles;
  final List<Outlier> cycleLengthAnomalies;
  final List<Outlier> lutealPhaseAnomalies;
  final List<Outlier> follicularPhaseAnomalies;
  final double weightedMean;
  final double confidenceScore;
  
  factory AnomalyReport.notEnoughData() => AnomalyReport(
    totalCycles: 0,
    cycleLengthAnomalies: [],
    lutealPhaseAnomalies: [],
    follicularPhaseAnomalies: [],
    weightedMean: 28.0,
    confidenceScore: 0.0,
  );
}

// lib/models/phase_anomaly_report.dart
class PhaseAnomalyReport {
  final PhaseAnomalyType type;
  final String message;
  final Severity severity;
  final List<int> cycles;
  
  factory PhaseAnomalyReport.normal() => PhaseAnomalyReport(
    type: PhaseAnomalyType.none,
    message: 'No phase anomalies detected',
    severity: Severity.low,
    cycles: [],
  );
}

enum PhaseAnomalyType {
  none,
  lutealVariability,    // RED FLAG - potential hormonal issue
  follicularDelay,      // NORMAL - stress/lifestyle impact
}
```

---

## Database Schema Updates

```sql
-- Enhanced periods table
ALTER TABLE periods ADD COLUMN is_anomaly BOOLEAN DEFAULT FALSE;
ALTER TABLE periods ADD COLUMN anomaly_reason TEXT;
ALTER TABLE periods ADD COLUMN exclude_from_stats BOOLEAN DEFAULT FALSE;
ALTER TABLE periods ADD COLUMN anomaly_detected_at TIMESTAMP;
ALTER TABLE periods ADD COLUMN user_note TEXT;

-- Store cycle vectors for analysis
CREATE TABLE cycle_vectors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  cycle_number INT NOT NULL,
  start_date DATE NOT NULL,
  total_length INT NOT NULL,
  period_length INT NOT NULL,
  follicular_length INT NOT NULL,
  luteal_length INT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_cycle_vectors_user ON cycle_vectors(user_id, cycle_number);

-- Store confidence scores over time
CREATE TABLE prediction_confidence (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users NOT NULL,
  prediction_date DATE NOT NULL,
  confidence_score DECIMAL(3,2), -- 0.00 to 1.00
  method TEXT, -- 'ema', 'symptom_override', 'gaussian', etc.
  standard_deviation DECIMAL(5,2),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_prediction_confidence_user ON prediction_confidence(user_id, prediction_date DESC);

-- Enable RLS
ALTER TABLE cycle_vectors ENABLE ROW LEVEL SECURITY;
ALTER TABLE prediction_confidence ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own cycle vectors" ON cycle_vectors
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own cycle vectors" ON cycle_vectors
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own confidence scores" ON prediction_confidence
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own confidence scores" ON prediction_confidence
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

---

## Comparison: Basic vs Advanced Logic

| Feature | Basic Logic | Advanced AI Logic |
|---------|-------------|-------------------|
| **Cycle Length** | Static (28 days always) | Dynamic (Exponential Moving Average with decaying weights) |
| **Ovulation** | Always Day 14 | Back-calculated from luteal phase (constant 14 days before next period) |
| **Irregularities** | Breaks predictions entirely | Isolated as anomalies with context classification |
| **Symptoms** | Just stored, ignored | Used as predictive indicators (can override math) |
| **Confidence** | Hard prediction ("Friday") | Gaussian probability cloud (gradient of likelihood) |
| **Phase Handling** | Treats cycle as single unit | Splits into Luteal (constant) vs Follicular (variable) |
| **Outlier Detection** | Simple average breaks | Multiple statistical methods (Modified Z-Score, IQR, Std Dev) |
| **User Context** | None | Asks WHY anomalies occur, excludes intelligently |

---

## Implementation Order

### Phase 1: Foundation (Week 1-2)
- [ ] Create CycleVector model
- [ ] Create Outlier model  
- [ ] Database migrations (cycle_vectors, anomaly fields)
- [ ] Build _buildCycleVectors() method
- [ ] Implement _calculateEMA() method

### Phase 2: Statistical Detection (Week 3-4)
- [ ] Implement Modified Z-Score outlier detection
- [ ] Implement IQR method
- [ ] Implement Standard Deviation method
- [ ] Create AnomalyReport model
- [ ] Build confidence score calculation

### Phase 3: Context Collection (Week 5)
- [ ] Create AnomalyContext model
- [ ] Build anomaly dialog UI
- [ ] Implement markPeriodAsAnomaly() in SupabaseService
- [ ] Add exclude_from_stats filtering in cycle calculations

### Phase 4: Phase Analysis (Week 6)
- [ ] Implement PhaseAnomalyDetector
- [ ] Split luteal vs follicular detection
- [ ] Create health alerts for luteal variability
- [ ] Add phase-specific anomaly UI

### Phase 5: Symptom Overrides (Week 7)
- [ ] Integrate with existing SymptomCorrelator
- [ ] Build checkForSymptomOverride() logic
- [ ] Add prediction override notifications
- [ ] Store override events in database

### Phase 6: Confidence Clouds (Week 8)
- [ ] Implement Gaussian distribution generator
- [ ] Create ConfidenceCloudGenerator
- [ ] Update calendar UI to show probability gradients
- [ ] Add confidence score display to home screen

---

## Testing Strategy

### Unit Tests
```dart
test('Modified Z-Score detects outliers correctly', () {
  final data = [28, 29, 27, 30, 45, 28, 29]; // 45 is outlier
  final outliers = CycleAnomalyDetector._modifiedZScoreMethod(data);
  
  expect(outliers.length, 1);
  expect(outliers.first.value, 45);
  expect(outliers.first.severity, Severity.extreme);
});

test('EMA gives more weight to recent cycles', () {
  final vectors = [
    CycleVector(totalLength: 28, ...),
    CycleVector(totalLength: 29, ...),
    CycleVector(totalLength: 30, ...), // Most recent
  ];
  
  final ema = CycleAnomalyDetector._calculateEMA(vectors);
  
  // EMA should be closer to 30 than simple average (29)
  expect(ema, greaterThan(29.0));
  expect(ema, lessThanOrEqualTo(30.0));
});

test('Confidence score decreases with variance', () {
  final regularCycles = [
    CycleVector(totalLength: 28, ...),
    CycleVector(totalLength: 29, ...),
    CycleVector(totalLength: 28, ...),
  ];
  
  final irregularCycles = [
    CycleVector(totalLength: 25, ...),
    CycleVector(totalLength: 35, ...),
    CycleVector(totalLength: 40, ...),
  ];
  
  final regularConfidence = CycleAnomalyDetector._calculateConfidence(regularCycles);
  final irregularConfidence = CycleAnomalyDetector._calculateConfidence(irregularCycles);
  
  expect(regularConfidence, greaterThan(irregularConfidence));
});
```

### Integration Tests
- Test full anomaly detection flow with real period data
- Verify anomaly dialog shows correct context options
- Test symptom override triggering and notification
- Verify confidence cloud calculation and calendar display

---

## Performance Considerations

1. **Cache cycle vectors**: Don't recalculate on every app open
2. **Batch outlier detection**: Run weekly in background, not on-demand
3. **Limit historical analysis**: Only analyze last 12 cycles (1 year)
4. **Async operations**: All statistical calculations should be async
5. **Database indexing**: Index on user_id + cycle_number for fast queries

---

## Privacy & Ethics

1. **Transparent AI**: Always show WHY predictions changed
2. **User control**: Allow manual override of all automatic classifications
3. **Health disclaimers**: Never diagnose - only suggest consulting healthcare provider
4. **Data ownership**: User can export all cycle vectors and anomaly classifications
5. **Opt-out**: Advanced features are opt-in, basic tracking always available

---

## References

- Modified Z-Score: Iglewicz, B. and Hoaglin, D. (1993). "How to Detect and Handle Outliers"
- Exponential Moving Average: NIST Engineering Statistics Handbook
- Luteal Phase Constancy: "The Menstrual Cycle" - Fehring et al., 2006
- Gaussian Distribution: Statistical modeling in reproductive health tracking

---

**Document Version**: 1.0  
**Last Updated**: January 2, 2026  
**Status**: Design Phase - Ready for Implementation
