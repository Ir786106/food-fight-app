import 'dart:async';
import 'package:flutter/material.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';

class AddressProvider extends ChangeNotifier {
  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<AddressModel>>? _sub;
  String? _currentUserId;

  List<AddressModel> get addresses => List.unmodifiable(_addresses);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AddressModel? get defaultAddress {
    final matches = _addresses.where((a) => a.isDefault);
    return matches.isNotEmpty ? matches.first : (_addresses.isNotEmpty ? _addresses.first : null);
  }

  void watchAddresses(String userId) {
    if (userId.isEmpty) {
      _addresses = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (_currentUserId == userId && _sub != null) {
      return;
    }

    _currentUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _sub?.cancel();
    _sub = AddressService.watchAddresses(userId).listen(
      (list) {
        _addresses = list;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load addresses: $e';
        notifyListeners();
      },
    );
  }

  Future<AddressModel?> addAddress(AddressModel address) async {
    try {
      final saved = await AddressService.addAddress(address);
      return saved;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateAddress(AddressModel address) async {
    try {
      await AddressService.updateAddress(address);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAddress(String userId, String addressId) async {
    try {
      await AddressService.deleteAddress(userId, addressId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> setDefaultAddress(String userId, String addressId) async {
    try {
      await AddressService.setDefaultAddress(userId, addressId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
