import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _service = AnalyticsService.instance;

  Map<String, dynamic>? _studentAnalytics;
  Map<String, dynamic>? _classAnalytics;
  Map<String, dynamic>? _aiPrediction;
  bool _isLoading = false;

  // Wellness States (Optimization)
  final Map<String, Map<String, dynamic>> _wellnessCache = {};
  bool _isWellnessLoading = false;

  Map<String, dynamic>? get studentAnalytics => _studentAnalytics;
  Map<String, dynamic>? get classAnalytics => _classAnalytics;
  Map<String, dynamic>? get aiPrediction => _aiPrediction;
  bool get isLoading => _isLoading;
  bool get isWellnessLoading => _isWellnessLoading;

  Map<String, dynamic>? wellnessFor(String studentId) => _wellnessCache[studentId];

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

  Future<void> loadWellnessData(String studentId, String name, Map<String, dynamic> stats) async {
    // 1. Check Cache first
    if (_wellnessCache.containsKey(studentId)) {
      return; // Already have it
    }

    _isWellnessLoading = true;
    notifyListeners();

    try {
      final result = await _service.getUnifiedWellness(name: name, stats: stats);
      if (result != null) {
        _wellnessCache[studentId] = result;
      }
    } catch (e) {
      print('Provider Wellness Error: $e');
    }

    _isWellnessLoading = false;
    notifyListeners();
  }
}
