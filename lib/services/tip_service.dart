class TipService {
  static final TipService _instance = TipService._internal();
  factory TipService() => _instance;
  TipService._internal();

  /// Get a medically-backed tip based on the cycle day and phase
  String getTipForCycleDay(int cycleDay, int avgCycleLength, bool isPeriod) {
    if (isPeriod) {
      if (cycleDay <= 2) {
        return 'Iron-rich foods like spinach or lentils can help replenish energy during your period.';
      } else {
        return 'Gentle movement, like yoga or walking, can help reduce period-related cramping.';
      }
    }

    // Phase calculation matching CycleProgressCircle logic
    final ovulationDay = avgCycleLength - 14;
    final follicularEnd = ovulationDay - 5;

    if (cycleDay <= follicularEnd) {
      return 'Estrogen is rising! It is a great time to focus on complex tasks that require high mental energy.';
    } else if (cycleDay <= ovulationDay) {
      return 'You are in your fertile window. If you are tracking ovulation, look for changes in basal body temperature.';
    } else {
      // Luteal Phase
      if (cycleDay > avgCycleLength - 7) {
        return 'Progesterone is peaking. Magnesium-rich snacks like dark chocolate or pumpkin seeds may help with PMS.';
      } else {
        return 'Prioritizing sleep is crucial now as your body begins to prepare for the next cycle.';
      }
    }
  }
}
