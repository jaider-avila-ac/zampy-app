import 'package:flutter/material.dart';
import '../models/menu_publico_model.dart';

class MenuPriceWidget extends StatelessWidget {
  const MenuPriceWidget({super.key, required this.product, required this.theme});
  final Producto product;
  final MenuPublicoTheme theme;

  @override
  Widget build(BuildContext context) {
    if (product.hasPromo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '\$${MenuPublicoTheme.fmtPrice(product.price)}',
            style: TextStyle(
              fontSize: 9,
              color: theme.textMuted,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Text(
            '\$${MenuPublicoTheme.fmtPrice(product.promoPrice!)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF22C55E),
            ),
          ),
        ],
      );
    }
    return Text(
      '\$${MenuPublicoTheme.fmtPrice(product.price)}',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: theme.primary,
      ),
    );
  }
}
