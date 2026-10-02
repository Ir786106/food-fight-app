import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/safe_change_notifier.dart';
import '../models/option_template_model.dart';
import '../services/option_template_service.dart';

class OptionTemplateProvider extends ChangeNotifier with SafeChangeNotifier {
  final OptionTemplateService _service;

  OptionTemplateProvider({OptionTemplateService? service})
      : _service = service ?? OptionTemplateService();

  List<OptionTemplateModel> _templates = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<OptionTemplateModel>>? _subscription;
  String? _currentBranchId;

  List<OptionTemplateModel> get templates => _templates;
  List<OptionTemplateModel> get sizeSets => _templates.where((t) => t.isSizeSet).toList();
  List<OptionTemplateModel> get extrasGroups => _templates.where((t) => t.isExtrasGroup).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Watch templates available for current branch
  void watchTemplates({String? branchId}) {
    if (_currentBranchId == branchId && _subscription != null) return;
    _currentBranchId = branchId;
    _isLoading = true;
    _error = null;
    notifyListenersPostFrame();

    // Auto-seed defaults if database is brand new
    _service.seedDefaultTemplatesIfEmpty();

    _subscription?.cancel();
    _subscription = _service.streamTemplates(branchId: branchId).listen(
      (data) {
        _templates = data;
        _isLoading = false;
        _error = null;
        notifyListenersPostFrame();
      },
      onError: (err) {
        _isLoading = false;
        _error = err.toString();
        notifyListenersPostFrame();
      },
    );
  }

  /// Create a new template
  Future<bool> createTemplate(OptionTemplateModel template) async {
    try {
      _isLoading = true;
      notifyListenersPostFrame();
      await _service.createTemplate(template);
      _isLoading = false;
      notifyListenersPostFrame();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListenersPostFrame();
      return false;
    }
  }

  /// Update a template
  Future<bool> updateTemplate(OptionTemplateModel template) async {
    try {
      _isLoading = true;
      notifyListenersPostFrame();
      await _service.updateTemplate(template);
      _isLoading = false;
      notifyListenersPostFrame();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListenersPostFrame();
      return false;
    }
  }

  /// Delete a template
  Future<bool> deleteTemplate(String templateId) async {
    try {
      await _service.deleteTemplate(templateId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListenersPostFrame();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
