import 'inspired_alert_service.dart';

/// Gemini Coach Service - Proactive Spiritual Guidance
class GeminiCoachService {
  final InspiredAlertService alertService;

  GeminiCoachService({required this.alertService});

  /// Triggered after a successful task completion or streak
  void encourage(String action) {
    alertService.showAlert(
      message: 'Well done, good and faithful servant!',
      intent: AlertIntent.mission,
      subMessage: 'Your discipline in "$action" is strengthening your Spirit.',
    );
  }

  /// Triggered when a discipline is missed or a negative pattern is detected
  void warn(String discipline) {
    alertService.showAlert(
      message: 'Grace is sufficient, but persistence is key.',
      intent: AlertIntent.warning,
      subMessage: 'You missed your "$discipline". Strength is found in return.',
    );
  }

  /// Provides spontaneous biblical insight based on current focus
  void inspire(String topic, String verse) {
    alertService.showAlert(
      message: 'Spiritual Insight: $topic',
      intent: AlertIntent.revelation,
      subMessage: '"$verse"',
    );
  }

  /// Simple prayer invitation
  void remindPrayer() {
    alertService.showAlert(
      message: 'Moment of Stillness',
      intent: AlertIntent.prayer,
      subMessage: 'Take 60 seconds to align with the Father right now.',
    );
  }
}
