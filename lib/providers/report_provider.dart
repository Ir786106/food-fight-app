import 'package:flutter/material.dart';
import 'package:food_fight/models/report_model.dart';
import 'package:food_fight/services/report_service.dart';
import 'package:food_fight/core/utils/logger.dart';

/// Provider for managing sales reports and analytics
class ReportProvider extends ChangeNotifier {
  ReportModel? _report;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedPreset = 'month'; // 'today', 'week', 'month', 'custom'
  DateTime? _startDate;
  DateTime? _endDate;

  ReportModel? get report => _report;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedPreset => _selectedPreset;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  ReportProvider() {
    setPreset('month');
  }

  /// Change preset date range and fetch report
  void setPreset(String preset) {
    _selectedPreset = preset;
    final now = DateTime.now();

    switch (preset) {
      case 'today':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'week':
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case 'month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'all':
        _startDate = null;
        _endDate = null;
        break;
      default:
        break;
    }

    fetchReport(startDate: _startDate, endDate: _endDate);
  }

  /// Set custom date range
  void setCustomDateRange(DateTime start, DateTime end) {
    _selectedPreset = 'custom';
    _startDate = start;
    _endDate = end;
    fetchReport(startDate: start, endDate: end);
  }

  /// Fetch sales report
  Future<void> fetchReport({DateTime? startDate, DateTime? endDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _report = await ReportService.fetchSalesReport(
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load report: $e';
      AppLogger.error('ReportProvider error: $e', tag: 'ReportProvider');
      notifyListeners();
    }
  }
}
