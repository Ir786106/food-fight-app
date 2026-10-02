import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/safe_change_notifier.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

class ReviewProvider extends ChangeNotifier with SafeChangeNotifier {
  final ReviewService _reviewService;

  ReviewProvider({ReviewService? reviewService})
      : _reviewService = reviewService ?? ReviewService();

  List<ReviewModel> _itemReviews = [];
  List<ReviewModel> _branchReviews = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<ReviewModel>>? _itemSubscription;
  StreamSubscription<List<ReviewModel>>? _branchSubscription;
  String? _currentItemId;
  String? _currentBranchId;

  List<ReviewModel> get itemReviews => _itemReviews;
  List<ReviewModel> get branchReviews => _branchReviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get averageRating {
    if (_itemReviews.isEmpty) return 4.8;
    final sum = _itemReviews.fold(0.0, (acc, r) => acc + r.rating);
    return double.parse((sum / _itemReviews.length).toStringAsFixed(1));
  }

  Map<int, int> get ratingDistribution {
    final dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in _itemReviews) {
      final star = r.rating.round().clamp(1, 5);
      dist[star] = (dist[star] ?? 0) + 1;
    }
    return dist;
  }

  /// Watch real-time customer reviews for a specific menu item
  void watchItemReviews(String itemId) {
    if (itemId.isEmpty) {
      _itemReviews = [];
      notifyListenersPostFrame();
      return;
    }

    if (_currentItemId == itemId && _itemSubscription != null) return;
    _currentItemId = itemId;
    _isLoading = true;
    _error = null;
    notifyListenersPostFrame();

    _itemSubscription?.cancel();
    _itemSubscription = _reviewService.streamReviewsForItem(itemId).listen(
      (data) {
        _itemReviews = data;
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

  /// Watch branch reviews for admin moderation
  void watchBranchReviews(String? branchId) {
    if (_currentBranchId == branchId && _branchSubscription != null) return;
    _currentBranchId = branchId;
    _isLoading = true;
    notifyListenersPostFrame();

    _branchSubscription?.cancel();
    _branchSubscription = _reviewService.streamBranchReviews(branchId: branchId).listen(
      (data) {
        _branchReviews = data;
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

  /// Submit a customer review
  Future<bool> submitReview(ReviewModel review) async {
    try {
      _isLoading = true;
      notifyListenersPostFrame();
      final res = await _reviewService.createReview(review);
      _isLoading = false;
      notifyListenersPostFrame();
      return res != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListenersPostFrame();
      return false;
    }
  }

  /// Moderate review (hide/unhide)
  Future<void> setReviewHidden(String reviewId, bool isHidden) async {
    try {
      await _reviewService.setReviewHidden(reviewId, isHidden);
    } catch (e) {
      _error = e.toString();
      notifyListenersPostFrame();
    }
  }

  /// Admin reply to review
  Future<void> addAdminReply(String reviewId, String reply) async {
    try {
      await _reviewService.addAdminReply(reviewId, reply);
    } catch (e) {
      _error = e.toString();
      notifyListenersPostFrame();
    }
  }

  @override
  void dispose() {
    _itemSubscription?.cancel();
    _branchSubscription?.cancel();
    super.dispose();
  }
}
