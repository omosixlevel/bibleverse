import 'package:flutter/material.dart';

enum AlertIntent {
  revelation, // Indigo/Star
  prayer, // Blue/Hands
  mission, // Gold/Crown
  warning, // Red/Flame
}

class InspiredAlert {
  final String message;
  final AlertIntent intent;
  final String? subMessage;
  final VoidCallback? onTap;

  InspiredAlert({
    required this.message,
    required this.intent,
    this.subMessage,
    this.onTap,
  });
}

class InspiredAlertService extends ChangeNotifier {
  InspiredAlert? _currentAlert;
  InspiredAlert? get currentAlert => _currentAlert;

  void showAlert({
    required String message,
    required AlertIntent intent,
    String? subMessage,
    VoidCallback? onTap,
  }) {
    _currentAlert = InspiredAlert(
      message: message,
      intent: intent,
      subMessage: subMessage,
      onTap: onTap,
    );
    notifyListeners();

    // Auto-dismiss after 6 seconds to allow reading
    final alertToDismiss = _currentAlert;
    Future.delayed(const Duration(seconds: 6), () {
      if (_currentAlert == alertToDismiss) {
        dismiss();
      }
    });
  }

  void dismiss() {
    if (_currentAlert != null) {
      _currentAlert = null;
      notifyListeners();
    }
  }
}
