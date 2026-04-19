import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _service = AnalyticsService.instance;

  Map<String, dynamic>? _studentAnalytics;
  Map<String, dynamic>? _classAnalytics;
  Map<String, dynamic>? _aiPrediction;
  bool _isLoading = false;

  Map<String, dynamic>? get studentAnalytics => _studentAnalytics;
  Map<String, dynamic>? get classAnalytics => _classAnalytics;
  Map<String, dynamic>? get aiPrediction => _aiPrediction;
  bool get isLoading => _isLoading;

  Future<void> loadStudentAnalytics(String studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _studentAnalytics = await _service.getStudentAnalytics(studentId);
      _aiPrediction = await _service.getAIPrediction(studentId);
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadClassAnalytics(String classId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _classAnalytics = await _service.getClassAnalytics(classId);
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }
}
