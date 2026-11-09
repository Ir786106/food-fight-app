import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_language.dart';
import '../common/network_image_view.dart';

class HomeFeatureBanner extends StatelessWidget {
  const HomeFeatureBanner({
    super.key,
    required this.onBrowse,
    this.imageUrl,
  });

  final VoidCallback onBrowse;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = imageUrl?.trim().isNotEmpty ?? false;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF201110), Color(0xFF642823)],
                ),
              ),
              child: hasPhoto
                  ? ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (rect) => LinearGradient(
                        begin: AlignmentDirectional.centerStart.resolve(
                          Directionality.of(context),
                        ),
                        end: AlignmentDirectional.centerEnd.resolve(
                          Directionality.of(context),
                        ),
                        colors: const [Colors.transparent, Colors.white],
                        stops: const [0.30, 0.93],
                      ).createShader(rect),
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FractionallySizedBox(
                          widthFactor: 0.65,
                          heightFactor: 1,
                          child: NetworkImageView(imageUrl: imageUrl),
                        ),
                      ),
                    )
                  : Align(
                      alignment: Alignment(rtl ? -0.85 : 0.85, 0),
                      child: Icon(
                        Icons.local_pizza_outlined,
                        size: 112,
                        color: AppColors.brandYellow.withValues(alpha: 0.20),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FOOD FIGHT',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.brandYellow,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('What are you craving?'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandYellow,
                      foregroundColor: AppColors.brandMaroon,
                    ),
                    onPressed: onBrowse,
                    icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                    label: Text(context.tr('Explore the menu')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
