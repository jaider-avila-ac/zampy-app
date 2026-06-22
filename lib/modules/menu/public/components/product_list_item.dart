import 'package:flutter/material.dart' hide MenuTheme;
import '../models/public_menu_model.dart';

// Equivalente a src/components/ProductListItem.jsx en React
// Fila de producto en modo lista

class ProductListItem extends StatelessWidget {
  const ProductListItem({
    super.key,
    required this.product,
    required this.theme,
    required this.onTap,
  });

  final MenuProduct product;
  final MenuTheme   theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            // Imagen — 72x72
            if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrl!,
                  width: 72, height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, st) => _imgFallback(),
                ),
              )
            else
              _imgFallback(),
            const SizedBox(width: 12),

            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: theme.text,
                    ),
                  ),
                  if (product.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: theme.textMuted),
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Precio
                  if (product.hasPromo)
                    Row(children: [
                      Text('\$${_fmt(product.price)}',
                          style: TextStyle(fontSize: 11, color: theme.textMuted,
                              decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: 6),
                      Text('\$${_fmt(product.promoPrice!)}',
                          style: const TextStyle(fontWeight: FontWeight.w900,
                              fontSize: 14, color: Color(0xFF22C55E))),
                    ])
                  else
                    Text('\$${_fmt(product.price)}',
                        style: TextStyle(fontWeight: FontWeight.w900,
                            fontSize: 14, color: theme.primary)),
                ],
              ),
            ),

            // Botón ver
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: theme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _imgFallback() => Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
            color: theme.surfaceAlt, borderRadius: BorderRadius.circular(8)),
      );

  String _fmt(double p) {
    final s = p == p.toInt() ? p.toInt().toString() : p.toString();
    return s.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}
