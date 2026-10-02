import 'package:flutter/material.dart';
import 'package:food_fight/models/report_model.dart';
import 'package:food_fight/services/report_service.dart';
import 'package:food_fight/core/utils/logger.dart';
import 'package:food_fight/core/utils/safe_change_notifier.dart';

/// Provider for managing sales reports and analytics
class ReportProvider extends ChangeNotifier with SafeChangeNotifier {
  ReportModel? _report;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedPreset = 'month'; // 'today', 'week', 'month', 'custom'
  DateTime? _startDate;
  DateTime? _endDate;

  String? _currentBranchId;

  ReportModel? get report => _report;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedPreset => _selectedPreset;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get currentBranchId => _currentBranchId;

  ReportProvider() {
    setPreset('month');
  }

  void setBranchId(String? branchId) {
    if (_currentBranchId != branchId) {
      _currentBranchId = branchId;
      fetchReport(startDate: _startDate, endDate: _endDate, branchId: branchId);
    }
  }

  /// Change preset date range and fetch report
  void setPreset(String preset, {String? branchId}) {
    _selectedPreset = preset;
    if (branchId != null) _currentBranchId = branchId;
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

    fetchReport(startDate: _startDate, endDate: _endDate, branchId: _currentBranchId);
  }

  /// Set custom date range
  void setCustomDateRange(DateTime start, DateTime end, {String? branchId}) {
    _selectedPreset = 'custom';
    _startDate = start;
    _endDate = end;
    if (branchId != null) _currentBranchId = branchId;
    fetchReport(startDate: start, endDate: end, branchId: _currentBranchId);
  }

  /// Fetch sales report
  Future<void> fetchReport({DateTime? startDate, DateTime? endDate, String? branchId}) async {
    if (branchId != null) _currentBranchId = branchId;
    _isLoading = true;
    _errorMessage = null;
    notifyListenersPostFrame();

    try {
      _report = await ReportService.fetchSalesReport(
        startDate: startDate,
        endDate: endDate,
        branchId: _currentBranchId,
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
