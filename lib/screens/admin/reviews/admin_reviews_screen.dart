import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/review_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/review_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/admin/admin_scaffold.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branchId = context.read<AuthProvider>().currentUser?.branchId;
      context.read<ReviewProvider>().watchBranchReviews(branchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = context.watch<ReviewProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final reviews = reviewProvider.branchReviews;

    return AdminScaffold(
      currentRoute: '/admin/reviews',
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Customer Reviews & Ratings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Reviews',
            onPressed: () {
              final branchId = context.read<AuthProvider>().currentUser?.branchId;
              reviewProvider.watchBranchReviews(branchId);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: reviewProvider.isLoading && reviews.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : reviews.isEmpty
              ? _buildEmptyState(context)
              : _buildReviewsList(context, reviews, isDark, colorScheme),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.brandYellow.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                size: 64,
                color: AppColors.brandYellow,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Customer Reviews Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'When customers receive delivered orders and rate their meals,\ntheir real reviews and feedback will appear here for branch moderation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList(
    BuildContext context,
    List<ReviewModel> reviews,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (ctx, index) {
        final review = reviews[index];
        return _buildReviewCard(context, review, isDark, colorScheme);
      },
    );
  }

  Widget _buildReviewCard(
    BuildContext context,
    ReviewModel review,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final reviewProvider = context.read<ReviewProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2128) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: review.isHidden
              ? AppColors.error.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.brandYellow,
                child: Text(
                  (review.userName != null && review.userName!.isNotEmpty)
                      ? review.userName![0].toUpperCase()
                      : 'U',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.onYellow),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? 'Verified Customer',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year} • Order #${review.orderId}',
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              // Stars
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 18,
                    color: AppColors.brandYellow,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Review comment
          if (review.reviewText != null && review.reviewText!.isNotEmpty)
            Text(
              review.reviewText!,
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),

          // Admin reply (if already replied)
          if (review.adminReply != null && review.adminReply!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandYellow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.reply_rounded, size: 14, color: AppColors.brandYellow),
                      SizedBox(width: 6),
                      Text(
                        'Branch Management Reply:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandYellow,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.adminReply!,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Moderation actions
          Row(
            children: [
              if (review.isHidden)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'HIDDEN FROM PUBLIC',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.reply_rounded, size: 16),
                label: Text(review.adminReply == null ? 'Reply' : 'Edit Reply'),
                onPressed: () => _openReplyDialog(context, review),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  review.isHidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  size: 18,
                  color: review.isHidden ? AppColors.success : Colors.grey,
                ),
                tooltip: review.isHidden ? 'Make Public' : 'Hide from Public',
                onPressed: () {
                  reviewProvider.setReviewHidden(review.id, !review.isHidden);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openReplyDialog(BuildContext context, ReviewModel review) {
    final ctrl = TextEditingController(text: review.adminReply ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reply to Customer Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Responding to: "${review.reviewText ?? '5-star rating'}"',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Thank you for your feedback! We are thrilled to serve you...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandYellow,
              foregroundColor: AppColors.onYellow,
            ),
            onPressed: () async {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                await context.read<ReviewProvider>().addAdminReply(review.id, text);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Submit Reply'),
          ),
        ],
      ),
    );
  }
}
