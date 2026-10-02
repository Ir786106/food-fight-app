import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/deal_model.dart';

/// Promotional banners carousel displaying real-time active Deals created by Admins
class HomeDealsCarousel extends StatelessWidget {
  final PageController controller;
  final int currentIndex;
  final List<DealModel> deals;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<DealModel>? onDealTap;

  const HomeDealsCarousel({
    super.key,
    required this.controller,
    required this.currentIndex,
    required this.deals,
    required this.onPageChanged,
    this.onDealTap,
  });

  @override
  Widget build(BuildContext context) {
    if (deals.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bannerCount = deals.length;

    return Column(
      children: [
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: bannerCount,
            itemBuilder: (context, index) {
              final deal = deals[index];
              return _buildDealBanner(context, deal, isDark);
            },
          ),
        ),
        if (bannerCount > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(bannerCount, (dotIndex) {
              final isActive = dotIndex == currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.brandYellow
                      : (isDark ? Colors.white24 : AppColors.border),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildDealBanner(BuildContext context, DealModel deal, bool isDark) {
    return GestureDetector(
      onTap: () => onDealTap?.call(deal),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.brandMaroon,
              AppColors.maroonDeep,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.maroonDeep.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.brandYellow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          deal.savingsPercentage > 0
                              ? '${deal.savingsPercentage.toStringAsFixed(0)}% OFF'
                              : 'SPECIAL DEAL',
                          style: const TextStyle(
                            color: AppColors.brandMaroon,
                            fontWeight: FontWeight.w900,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      if (deal.branchId != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          deal.branchId!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    deal.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    deal.description,
                    style: const TextStyle(
                      color: AppColors.yellowSoft,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Rs. ${deal.dealPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (deal.originalPrice > deal.dealPrice) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Rs. ${deal.originalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_offer_rounded,
                color: AppColors.brandYellow,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Backward compatibility alias
typedef HomePromoCarousel = HomeDealsCarousel;
