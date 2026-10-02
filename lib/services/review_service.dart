import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/logger.dart';
import '../models/review_model.dart';
import 'interfaces/review_service_interface.dart';

class ReviewService implements IReviewService {
  final FirebaseFirestore? _customFirestore;
  ReviewService({FirebaseFirestore? firestore}) : _customFirestore = firestore;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  final String _collection = 'reviews';

  CollectionReference<Map<String, dynamic>> get _reviewsRef =>
      _firestore.collection(_collection);

  @override
  Future<List<ReviewModel>> getReviewsForItem(String itemId) async {
    try {
      final snapshot = await _reviewsRef
          .where('itemId', isEqualTo: itemId)
          .where('isHidden', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ReviewModel.fromJson(data);
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching reviews for $itemId: $e', tag: 'ReviewService');
      return [];
    }
  }

  Stream<List<ReviewModel>> streamReviewsForItem(String itemId) {
    try {
      return _reviewsRef
          .where('itemId', isEqualTo: itemId)
          .where('isHidden', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return ReviewModel.fromJson(data);
        }).toList();
      });
    } catch (e) {
      AppLogger.error('Error streaming reviews for item $itemId: $e', tag: 'ReviewService');
      return Stream.value(<ReviewModel>[]);
    }
  }

  @override
  Future<List<ReviewModel>> getReviewsForItemPaginated(
    String itemId,
    int page,
    int limit,
  ) async {
    try {
      final query = _reviewsRef
          .where('itemId', isEqualTo: itemId)
          .where('isHidden', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ReviewModel.fromJson(data);
      }).toList();
    } catch (e) {
      AppLogger.error('Error in paginated reviews: $e', tag: 'ReviewService');
      return [];
    }
  }

  @override
  Future<ReviewModel?> getReviewById(String reviewId) async {
    try {
      final doc = await _reviewsRef.doc(reviewId).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return ReviewModel.fromJson(data);
    } catch (e) {
      AppLogger.error('Error fetching review $reviewId: $e', tag: 'ReviewService');
      return null;
    }
  }

  @override
  Future<List<ReviewModel>> getReviewsByUser(String userId) async {
    try {
      final snapshot = await _reviewsRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ReviewModel.fromJson(data);
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching user reviews: $e', tag: 'ReviewService');
      return [];
    }
  }

  @override
  Future<ReviewModel?> createReview(ReviewModel review) async {
    try {
      final docRef = review.id.isNotEmpty ? _reviewsRef.doc(review.id) : _reviewsRef.doc();
      final toSave = review.copyWith(id: docRef.id);
      await docRef.set(toSave.toJson());

      // Update aggregate rating for item asynchronously
      if (review.itemId.isNotEmpty && review.targetType == 'item') {
        _updateItemAggregateRating(review.itemId);
      }

      AppLogger.info('Review created: ${docRef.id}', tag: 'ReviewService');
      return toSave;
    } catch (e) {
      AppLogger.error('Error creating review: $e', tag: 'ReviewService');
      return null;
    }
  }

  @override
  Future<void> updateReview(ReviewModel review) async {
    try {
      await _reviewsRef.doc(review.id).update(review.toJson());
      if (review.itemId.isNotEmpty && review.targetType == 'item') {
        _updateItemAggregateRating(review.itemId);
      }
      AppLogger.info('Review updated: ${review.id}', tag: 'ReviewService');
    } catch (e) {
      AppLogger.error('Error updating review: $e', tag: 'ReviewService');
      rethrow;
    }
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    try {
      final review = await getReviewById(reviewId);
      await _reviewsRef.doc(reviewId).delete();
      if (review != null && review.itemId.isNotEmpty) {
        _updateItemAggregateRating(review.itemId);
      }
      AppLogger.info('Review deleted: $reviewId', tag: 'ReviewService');
    } catch (e) {
      AppLogger.error('Error deleting review: $e', tag: 'ReviewService');
      rethrow;
    }
  }

  @override
  Future<double> getAverageRating(String itemId) async {
    try {
      final reviews = await getReviewsForItem(itemId);
      if (reviews.isEmpty) return 4.8; // default
      final total = reviews.fold(0.0, (acc, r) => acc + r.rating);
      return total / reviews.length;
    } catch (e) {
      return 4.8;
    }
  }

  @override
  Future<int> getReviewCount(String itemId) async {
    try {
      final reviews = await getReviewsForItem(itemId);
      return reviews.length;
    } catch (e) {
      return 0;
    }
  }

  // --- Admin Moderation Helpers ---

  /// Stream reviews for a specific branch (or all branches for Super Admin)
  Stream<List<ReviewModel>> streamBranchReviews({String? branchId}) {
    try {
      Query<Map<String, dynamic>> query = _reviewsRef.orderBy('createdAt', descending: true);
      if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
        query = query.where('branchId', isEqualTo: branchId);
      }
      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return ReviewModel.fromJson(data);
        }).toList();
      });
    } catch (e) {
      AppLogger.error('Error streaming branch reviews: $e', tag: 'ReviewService');
      return Stream.value(<ReviewModel>[]);
    }
  }

  /// Toggle review hidden state for moderation
  Future<void> setReviewHidden(String reviewId, bool isHidden) async {
    await _reviewsRef.doc(reviewId).update({'isHidden': isHidden});
  }

  /// Admin reply to review
  Future<void> addAdminReply(String reviewId, String reply) async {
    await _reviewsRef.doc(reviewId).update({
      'adminReply': reply,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Update item average rating in menuItems
  Future<void> _updateItemAggregateRating(String itemId) async {
    try {
      final reviews = await getReviewsForItem(itemId);
      if (reviews.isEmpty) return;

      final avgRating = reviews.fold(0.0, (acc, r) => acc + r.rating) / reviews.length;
      final roundedRating = double.parse(avgRating.toStringAsFixed(1));

      await _firestore.collection('menuItems').doc(itemId).update({
        'rating': roundedRating,
      });
      AppLogger.info('Item $itemId rating updated to $roundedRating', tag: 'ReviewService');
    } catch (e) {
      AppLogger.error('Failed to update item aggregate rating: $e', tag: 'ReviewService');
    }
  }
}
