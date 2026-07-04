class AgricultureAdvisor {
  static String getIrrigationAdvice({
    required double temp,
    required int humidity,
    required double windSpeed,
    required double rainProbability,
  }) {
    if (rainProbability > 50) {
      return "🌧 لا تسقي اليوم - متوقع مطر";
    }
    if (temp > 38) {
      return "🔥 حرارة عالية - اسقِ في المساء";
    }
    if (windSpeed > 25) {
      return "🌬 رياح قوية - تجنب الرش";
    }
    if (humidity < 30) {
      return "💧 رطوبة منخفضة - يفضل الري";
    }
    return "🟢 الظروف مناسبة للري";
  }

  static String getStressLevel(double temp, int humidity) {
    if (temp > 40 && humidity < 30) return "مرتفع";
    if (temp > 35) return "متوسط";
    return "منخفض";
  }
}
