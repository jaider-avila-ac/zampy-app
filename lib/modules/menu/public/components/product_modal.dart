import 'package:flutter/material.dart' hide MenuTheme;
import '../models/public_menu_model.dart';

// Equivalente a src/components/ProductModal.jsx en React
// Bottom sheet con detalle completo del producto

class ProductModal extends StatelessWidget {
  const ProductModal({
    super.key,
    required this.product,
    required this.theme,
  });

  final MenuProduct product;
  final MenuTheme   theme;

  static Future<void> show(
      BuildContext context, MenuProduct product, MenuTheme theme) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductModal(product: product, theme: theme),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen
                    if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                      SizedBox(
                        height: 240,
                        width: double.infinity,
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, st) =>
                              Container(height: 240, color: theme.surfaceAlt),
                        ),
                      )
                    else
                      Container(
                        height: 160,
                        color: theme.surfaceAlt,
                        child: Center(
                          child: Icon(Icons.restaurant_menu,
                              size: 48, color: theme.primary.withValues(alpha: 0.3)),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tags
                          if (product.tags.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              children: product.tags.map((tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.primary,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(tag, style: const TextStyle(
                                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                              )).toList(),
                            ),
                          if (product.tags.isNotEmpty) const SizedBox(height: 12),

                          // Nombre
                          Text(
                            product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: theme.text,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Rating
                          if (product.rating != null && product.rating! > 0)
                            Row(children: [
                              const Icon(Icons.star, size: 14, color: Color(0xFFFFD700)),
                              const SizedBox(width: 4),
                              Text(product.rating!.toStringAsFixed(1),
                                  style: TextStyle(fontSize: 13,
                                      fontWeight: FontWeight.w600, color: theme.text)),
                              if (product.totalVotos != null && product.totalVotos! > 0)
                                Text(' (${product.totalVotos} votos)',
                                    style: TextStyle(fontSize: 11, color: theme.textMuted)),
                            ]),

                          // Descripción
                          if (product.description?.trim().isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            Text(
                              product.description!,
                              style: TextStyle(fontSize: 14, color: theme.textMuted, height: 1.6),
                            ),
                          ],

                          // Componentes
                          if (product.components.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(product.components.join(', '),
                                style: TextStyle(fontSize: 12, color: theme.textMuted)),
                          ],

                          // Variantes
                          if (product.variants.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text('Variantes',
                                style: TextStyle(fontWeight: FontWeight.w700,
                                    fontSize: 13, color: theme.text)),
                            const SizedBox(height: 8),
                            ...product.variants.map((v) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(v.name, style: TextStyle(fontSize: 13, color: theme.text)),
                                  if (v.price != null)
                                    Text('\$${_fmt(v.price!)}',
                                        style: TextStyle(fontSize: 13,
                                            fontWeight: FontWeight.w700, color: theme.primary)),
                                ],
                              ),
                            )),
                          ],

                          // Precio
                          const SizedBox(height: 20),
                          Divider(color: theme.border),
                          const SizedBox(height: 12),
                          if (product.hasPromo)
                            Row(children: [
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('\$${_fmt(product.price)}',
                                    style: TextStyle(fontSize: 13, color: theme.textMuted,
                                        decoration: TextDecoration.lineThrough)),
                                Text('\$${_fmt(product.promoPrice!)}',
                                    style: const TextStyle(fontWeight: FontWeight.w900,
                                        fontSize: 24, color: Color(0xFF22C55E))),
                              ]),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('PROMO',
                                    style: TextStyle(color: Color(0xFF22C55E),
                                        fontWeight: FontWeight.w900, fontSize: 11)),
                              ),
                            ])
                          else
                            Text('\$${_fmt(product.price)}',
                                style: TextStyle(fontWeight: FontWeight.w900,
                                    fontSize: 24, color: theme.primary)),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double p) {
    final s = p == p.toInt() ? p.toInt().toString() : p.toString();
    return s.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}
