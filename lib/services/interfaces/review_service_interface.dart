import 'package:food_fight/models/review_model.dart';

/// Interface for review service
abstract class IReviewService {
  /// Get all reviews for menu item
  Future<List<ReviewModel>> getReviewsForItem(String itemId);

  /// Get reviews for menu item with pagination
  Future<List<ReviewModel>> getReviewsForItemPaginated(
    String itemId,
    int page,
    int limit,
  );

  /// Get review by ID
  Future<ReviewModel?> getReviewById(String reviewId);

  /// Get reviews by user
  Future<List<ReviewModel>> getReviewsByUser(String userId);

  /// Create review
  Future<ReviewModel?> createReview(ReviewModel review);

  /// Update review
  Future<void> updateReview(ReviewModel review);

  /// Delete review
  Future<void> deleteReview(String reviewId);

  /// Get average rating for menu item
  Future<double> getAverageRating(String itemId);

  /// Count reviews for menu item
  Future<int> getReviewCount(String itemId);
}
