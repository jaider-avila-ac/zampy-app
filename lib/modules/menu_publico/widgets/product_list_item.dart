import 'package:flutter/material.dart';
import '../models/menu_publico_model.dart';
import 'price_widget.dart';

/// Equivalente a ProductListItem.jsx — ítem horizontal con thumbnail 76x76.
class ProductListItem extends StatelessWidget {
  const ProductListItem({
    super.key,
    required this.product,
    required this.theme,
    required this.onTap,
  });

  final Producto product;
  final MenuPublicoTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            // Thumbnail 76×76
            if (product.image != null && product.image!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: Image.network(
                    product.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                        color: theme.surfaceAlt,
                        alignment: Alignment.center,
                        child: Icon(Icons.restaurant_outlined,
                            color: theme.textMuted, size: 24)),
                  ),
                ),
              ),
            if (product.image != null && product.image!.isNotEmpty)
              const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre + rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: theme.text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product.rating != null && product.rating! > 0) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.star_rounded,
                            size: 12, color: const Color(0xFFFFD700)),
                        Text(
                          product.rating!.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: theme.text),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description ?? '',
                    style: TextStyle(
                        fontSize: 11, color: theme.textMuted, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      MenuPriceWidget(product: product, theme: theme),
                      const Spacer(),
                      Icon(Icons.chevron_right,
                          size: 16, color: theme.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
