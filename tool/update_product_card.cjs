const fs = require('node:fs');
const p = 'lib/widgets/home/product_card.dart';
let s = fs.readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
s = s.replace("import 'package:flutter/services.dart';", "import 'package:flutter/services.dart';\nimport '../../core/constants/app_dimens.dart';\nimport '../../core/utils/app_snackbar.dart';");
s = s.replace('    cart.addToCart(widget.food);\n  }', `    cart.addToCart(widget.food);
    AppSnackbar.showSuccess(context, 'Added to cart', action: SnackBarAction(
      label: 'View', onPressed: () => Navigator.of(context, rootNavigator: true).pushNamed('/cart')));
  }`);
const start = s.indexOf('  @override\n  Widget build(');
if (start < 0) throw Error('Product build marker missing');
s = s.slice(0,start) + `  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final hasOptions = food.hasVariants || (food.variants?.isNotEmpty ?? false);
    final price = 'Rs. ' + food.startingPrice.toStringAsFixed(0);
    return SizedBox(
      width: widget.inGrid ? null : widget.width,
      child: Card(
        margin: const EdgeInsets.all(AppDimens.space4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AspectRatio(aspectRatio: 1.5, child: Hero(
              tag: widget.heroTag ?? 'food-' + food.id,
              child: NetworkImageView(imageUrl: food.imageUrl, borderRadius: 0),
            )),
            Expanded(child: Padding(
              padding: const EdgeInsets.all(AppDimens.space12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(food.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(food.reviewCount > 0
                    ? '★ ' + food.rating.toStringAsFixed(1) + ' (' + food.reviewCount.toString() + ')' : 'New',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium),
                const SizedBox(height: AppDimens.space4),
                Text(hasOptions ? 'From $price' : price, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: AppDimens.space8),
                SizedBox(width: double.infinity, height: AppDimens.minTouchTarget,
                  child: ScaleTransition(scale: _scaleAnimation,
                    child: Semantics(label: 'Add ' + food.name + ' to cart', button: true,
                      child: FilledButton.tonal(
                        onPressed: food.isAvailable ? () => _handleAddTap(context, cart) : null,
                        style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                        child: Text(food.isAvailable ? (hasOptions ? 'Choose' : 'Add') : 'Unavailable',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                ),
              ]),
            )),
          ]),
        ),
      ),
    );
  }
}
`;
fs.writeFileSync(p,s);
