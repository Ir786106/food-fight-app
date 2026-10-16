import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/branch_model.dart';
import '../services/branch_service.dart';
import '../core/utils/logger.dart';
import '../core/utils/safe_change_notifier.dart';
import '../widgets/common/location_primer_dialog.dart';
import '../widgets/common/city_picker_sheet.dart';

enum BranchSortField { revenue, orderCount, profit, name }
typedef BranchSortOption = BranchSortField;

/// Manages multi-branch states for Customer storefront, Admin branch-scoping, and Super Admin oversight.
/// Includes automatic nearest-branch GPS selection, coverage radius checking, and city fallbacks.
class BranchProvider extends ChangeNotifier with SafeChangeNotifier {
  static const String _prefBranchKey = 'foodfight_saved_branch_id';
  static const String _prefLatKey = 'foodfight_saved_lat';
  static const String _prefLngKey = 'foodfight_saved_lng';
  static const String _prefCityKey = 'foodfight_saved_city';
  static const String _prefPrimerShownKey = 'foodfight_location_primer_shown';

  List<BranchModel> _branches = [];
  BranchModel? _selectedBranch;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<BranchModel>>? _branchesSub;
  BranchSortField _sortField = BranchSortField.revenue;
  bool _sortAscending = false;

  bool _initialized = false;
  bool _isResolvingLocation = false;

  // Auto-selection & Location states
  double? _userLatitude;
  double? _userLongitude;
  bool _isOutOfDeliveryArea = false;
  double? _distanceToNearestKm;
  BranchModel? _nearestBranchOutOfRange;
  String? _closedBranchFallbackNotice;
  String? _savedCity;

  List<BranchModel> get branches {
    if (!_initialized && _branchesSub == null) {
      ensureInitialized();
    }
    return List.unmodifiable(_branches);
  }

  List<BranchModel> get activeBranches {
    if (!_initialized && _branchesSub == null) {
      ensureInitialized();
    }
    return _branches.where((b) => b.isActive).toList();
  }

  BranchModel? get selectedBranch => _selectedBranch ?? (_branches.isNotEmpty ? _branches.first : null);
  bool get isLoading => _isLoading;
  bool get isResolvingLocation => _isResolvingLocation;
  String? get errorMessage => _errorMessage;
  BranchSortField get sortField => _sortField;
  bool get sortAscending => _sortAscending;

  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  bool get isOutOfDeliveryArea => _isOutOfDeliveryArea;
  double? get distanceToNearestKm => _distanceToNearestKm;
  BranchModel? get nearestBranchOutOfRange => _nearestBranchOutOfRange;
  String? get closedBranchFallbackNotice => _closedBranchFallbackNotice;
  String? get savedCity => _savedCity;

  BranchProvider();

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await init();
  }

  /// Initialize real-time listener and seed default branches if necessary
  Future<void> init() async {
    _isLoading = true;
    notifyListenersPostFrame();

    try {
      await BranchService.seedInitialBranchesIfEmpty();
      await BranchService.ensureBranchCoordinatesMigrated();
    } catch (e) {
      AppLogger.warn('Branch seeding check: $e', tag: 'BranchProvider');
    }

    _branchesSub?.cancel();
    _branchesSub = BranchService.watchBranches().listen(
      (list) {
        _branches = list;
        _isLoading = false;
        _errorMessage = null;

        if (_selectedBranch == null && _branches.isNotEmpty) {
          // If we have saved branch ID in prefs, try restoring it
          _restoreSavedBranchOrNearest();
        } else if (_selectedBranch != null) {
          // Update selected instance with fresh data from firestore
          final updated = _branches.where((b) => b.id == _selectedBranch!.id).firstOrNull;
          if (updated != null) {
            _selectedBranch = updated;
          }
        }

        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Failed to load branches: $e';
        AppLogger.error('Branch stream error: $e', tag: 'BranchProvider');
        notifyListeners();
      },
    );
  }

  Future<void> _restoreSavedBranchOrNearest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_prefBranchKey);
      _savedCity = prefs.getString(_prefCityKey);
      _userLatitude = prefs.getDouble(_prefLatKey);
      _userLongitude = prefs.getDouble(_prefLngKey);

      if (savedId != null && savedId.isNotEmpty) {
        final match = _branches.where((b) => b.id == savedId).firstOrNull;
        if (match != null) {
          _selectedBranch = match;
          notifyListeners();
          return;
        }
      }

      if (_userLatitude != null && _userLongitude != null) {
        _computeNearestBranch(_userLatitude!, _userLongitude!);
        return;
      }

      if (_savedCity != null && _savedCity!.isNotEmpty) {
        final cityMatch = activeBranches.where((b) => b.city.toLowerCase() == _savedCity!.toLowerCase()).firstOrNull;
        if (cityMatch != null) {
          _selectedBranch = cityMatch;
          notifyListeners();
          return;
        }
      }

      _selectedBranch = _branches.firstWhere((b) => b.isActive, orElse: () => _branches.first);
      notifyListeners();
    } catch (_) {
      if (_branches.isNotEmpty) {
        _selectedBranch = _branches.firstWhere((b) => b.isActive, orElse: () => _branches.first);
        notifyListeners();
      }
    }
  }

  /// Automatically resolves nearest branch based on GPS, with distance radius checks and fallbacks.
  Future<void> autoResolveNearestBranch({
    BuildContext? context,
    bool forcePrompt = false,
  }) async {
    if (_isResolvingLocation) return;
    _isResolvingLocation = true;
    notifyListeners();

    try {
      if (!_initialized) {
        await ensureInitialized();
      }

      final prefs = await SharedPreferences.getInstance();
      bool isServiceEnabled = false;
      try {
        isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      } catch (e) {
        AppLogger.warn('Geolocator service check failed: $e', tag: 'BranchProvider');
      }

      LocationPermission permission = LocationPermission.denied;
      try {
        permission = await Geolocator.checkPermission();
      } catch (e) {
        AppLogger.warn('Geolocator permission check failed: $e', tag: 'BranchProvider');
      }

      // If first launch and context is present, show location primer
      final primerShown = prefs.getBool(_prefPrimerShownKey) ?? false;
      if (context != null && (!primerShown || forcePrompt) && permission == LocationPermission.denied) {
        if (!context.mounted) return;
        final allow = await LocationPrimerDialog.show(context);
        await prefs.setBool(_prefPrimerShownKey, true);
        if (allow == true) {
          try {
            permission = await Geolocator.requestPermission();
          } catch (e) {
            AppLogger.warn('Geolocator requestPermission failed: $e', tag: 'BranchProvider');
          }
        } else if (allow == false) {
          // Manual city selection chosen
          if (context.mounted) {
            await _promptCityPicker(context);
          }
          _isResolvingLocation = false;
          notifyListeners();
          return;
        }
      }

      if (isServiceEnabled && (permission == LocationPermission.whileInUse || permission == LocationPermission.always)) {
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 6),
            ),
          );
          _userLatitude = pos.latitude;
          _userLongitude = pos.longitude;
          await prefs.setDouble(_prefLatKey, pos.latitude);
          await prefs.setDouble(_prefLngKey, pos.longitude);

          _computeNearestBranch(pos.latitude, pos.longitude);
          _isResolvingLocation = false;
          notifyListeners();
          return;
        } catch (e) {
          AppLogger.warn('Failed to obtain GPS position: $e', tag: 'BranchProvider');
        }
      }

      // Fallback: permission denied, service disabled, or position timed out
      // Check if user previously saved city or coordinates
      final savedLat = prefs.getDouble(_prefLatKey);
      final savedLng = prefs.getDouble(_prefLngKey);
      if (savedLat != null && savedLng != null) {
        _userLatitude = savedLat;
        _userLongitude = savedLng;
        _computeNearestBranch(savedLat, savedLng);
      } else {
        final savedCity = prefs.getString(_prefCityKey);
        if (savedCity != null && savedCity.isNotEmpty) {
          selectCityFallback(savedCity);
        } else if (context != null && context.mounted) {
          await _promptCityPicker(context);
        } else if (_selectedBranch == null && _branches.isNotEmpty) {
          _selectedBranch = _branches.firstWhere((b) => b.isActive, orElse: () => _branches.first);
        }
      }
    } catch (e) {
      AppLogger.error('autoResolveNearestBranch error: $e', tag: 'BranchProvider');
    } finally {
      _isResolvingLocation = false;
      notifyListeners();
    }
  }

  /// Internal Haversine distance evaluation across active branches
  void _computeNearestBranch(double userLat, double userLng) {
    final list = activeBranches.where((b) => b.latitude != null && b.longitude != null).toList();
    if (list.isEmpty) {
      _isOutOfDeliveryArea = false;
      if (_branches.isNotEmpty) {
        _selectedBranch = _branches.first;
      }
      return;
    }

    // Sort by distance to user
    list.sort((a, b) {
      final da = a.distanceToKm(userLat, userLng);
      final db = b.distanceToKm(userLat, userLng);
      return da.compareTo(db);
    });

    final nearest = list.first;
    final distance = nearest.distanceToKm(userLat, userLng);

    if (distance <= nearest.effectiveRadiusKm) {
      // Within delivery radius!
      _isOutOfDeliveryArea = false;
      _distanceToNearestKm = distance;
      _nearestBranchOutOfRange = null;

      if (nearest.isActive) {
        _selectedBranch = nearest;
        _closedBranchFallbackNotice = null;
      } else {
        // Nearest is closed, find next open branch in radius
        final nextOpen = list.where((b) => b.isActive).firstOrNull;
        if (nextOpen != null) {
          _selectedBranch = nextOpen;
          _closedBranchFallbackNotice = 'Branch "${nearest.name}" is temporarily closed. Serving you from "${nextOpen.name}".';
        } else {
          _selectedBranch = nearest;
          _closedBranchFallbackNotice = 'Branch "${nearest.name}" is currently closed.';
        }
      }
      _persistBranchSelection(nearest.id);
    } else {
      // Out of delivery radius! (e.g. Arifwala)
      _isOutOfDeliveryArea = true;
      _distanceToNearestKm = distance;
      _nearestBranchOutOfRange = nearest;
      _selectedBranch = nearest; // keep assigned so screens have menu data
      _persistBranchSelection(nearest.id);
    }
  }

  /// Re-evaluates nearest branch if user location shifts more than 1 km
  void checkLocationShift(double newLat, double newLng) {
    if (_userLatitude == null || _userLongitude == null) {
      _userLatitude = newLat;
      _userLongitude = newLng;
      _computeNearestBranch(newLat, newLng);
      notifyListeners();
      return;
    }

    // Calculate displacement from last resolved position
    final branchRef = BranchModel(
      id: '',
      name: '',
      address: '',
      city: '',
      phone: '',
      latitude: _userLatitude,
      longitude: _userLongitude,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final shiftKm = branchRef.distanceToKm(newLat, newLng);
    if (shiftKm >= 1.0) {
      AppLogger.info('Location shifted by ${shiftKm.toStringAsFixed(2)} km. Re-evaluating nearest branch.', tag: 'BranchProvider');
      _userLatitude = newLat;
      _userLongitude = newLng;
      _computeNearestBranch(newLat, newLng);
      notifyListeners();
    }
  }

  /// Single friendly city fallback selection
  Future<void> selectCityFallback(String cityName) async {
    _savedCity = cityName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefCityKey, cityName);

    final matches = activeBranches.where((b) => b.city.toLowerCase() == cityName.toLowerCase()).toList();
    if (matches.isNotEmpty) {
      _selectedBranch = matches.first;
      _isOutOfDeliveryArea = false;
      _distanceToNearestKm = null;
      _nearestBranchOutOfRange = null;
      _closedBranchFallbackNotice = null;
      await _persistBranchSelection(matches.first.id);
      notifyListeners();
    } else {
      // City selected has no branch
      _isOutOfDeliveryArea = true;
      _distanceToNearestKm = null;
      _nearestBranchOutOfRange = null;
      notifyListeners();
    }
  }

  /// Manually prompt customer to pick their city/area
  Future<void> promptManualCitySelection(BuildContext context) => _promptCityPicker(context);

  Future<void> _promptCityPicker(BuildContext context) async {
    final availableCities = activeBranches.map((b) => b.city).toSet().toList();
    if (availableCities.isEmpty) {
      availableCities.addAll(['Lahore', 'Islamabad', 'Rawalpindi', 'Karachi']);
    }

    final chosen = await CityPickerSheet.show(
      context,
      availableCities: availableCities,
      currentCity: _selectedBranch?.city ?? _savedCity,
    );

    if (chosen != null && chosen.isNotEmpty) {
      await selectCityFallback(chosen);
    }
  }

  Future<void> _persistBranchSelection(String branchId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefBranchKey, branchId);
    } catch (e) {
      AppLogger.warn('Failed to persist branch selection: $e', tag: 'BranchProvider');
    }
  }

  /// User-friendly read-only delivery label with estimated time
  String getDeliveryLabel() {
    final branch = selectedBranch;
    if (branch == null) return 'Select your area';
    
    // Dynamic estimated delivery time calculation
    int minutes = 20;
    if (_distanceToNearestKm != null && _distanceToNearestKm! > 0) {
      minutes = (15 + (_distanceToNearestKm! * 2.5)).round().clamp(15, 50);
    }

    return 'Delivering from Food Fight ${branch.city.isNotEmpty ? branch.city : branch.name} • $minutes min';
  }

  /// Select active branch (Customer browsing or Super Admin filtering)
  void selectBranch(BranchModel branch) {
    if (_selectedBranch?.id != branch.id) {
      _selectedBranch = branch;
      _persistBranchSelection(branch.id);
      notifyListeners();
    }
  }

  /// Select branch by ID
  void selectBranchById(String branchId) {
    if (branchId.isEmpty) return;
    final match = _branches.where((b) => b.id == branchId).firstOrNull;
    if (match != null) {
      selectBranch(match);
    }
  }

  /// Set sorting criteria for Super Admin branch performance comparison
  void setSort(BranchSortField field, {bool? ascending}) {
    if (_sortField == field && ascending == null) {
      _sortAscending = !_sortAscending;
    } else {
      _sortField = field;
      _sortAscending = ascending ?? false;
    }
    notifyListeners();
  }

  /// Get sorted list of branches for Super Admin Performance table
  List<BranchModel> get sortedBranches {
    final list = List<BranchModel>.from(_branches);
    list.sort((a, b) {
      int cmp = 0;
      switch (_sortField) {
        case BranchSortField.revenue:
          cmp = a.revenue.compareTo(b.revenue);
          break;
        case BranchSortField.orderCount:
          cmp = a.orderCount.compareTo(b.orderCount);
          break;
        case BranchSortField.profit:
          cmp = a.profit.compareTo(b.profit);
          break;
        case BranchSortField.name:
          cmp = a.name.compareTo(b.name);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  /// Platform aggregates across all branches (Super Admin HQ)
  double get totalRevenue => _branches.fold(0.0, (sum, b) => sum + b.revenue);
  int get totalOrders => _branches.fold(0, (sum, b) => sum + b.orderCount);
  double get totalExpenses => _branches.fold(0.0, (sum, b) => sum + b.expenses);
  double get totalProfit => totalRevenue - totalExpenses;

  double get totalPlatformRevenue => totalRevenue;
  double get totalPlatformExpenses => totalExpenses;
  double get totalPlatformProfit => totalProfit;
  BranchSortField get selectedSort => _sortField;
  void setSortOption(BranchSortField field) => setSort(field);

  /// Create new branch (Super Admin "Add New Branch" workflow)
  Future<String> createBranch(BranchModel branch) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = await BranchService.createBranch(branch);
      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create branch: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Update branch
  Future<void> updateBranch(BranchModel branch) async {
    _isLoading = true;
    notifyListeners();

    try {
      await BranchService.updateBranch(branch);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update branch: $e';
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _branchesSub?.cancel();
    super.dispose();
  }
}
