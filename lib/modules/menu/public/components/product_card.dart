import 'package:flutter/material.dart' hide MenuTheme;
import '../models/public_menu_model.dart';

// Equivalente a src/components/ProductCard.jsx en React
// Tarjeta de producto en grid — altura fija 280px igual que React

class ProductCard extends StatelessWidget {
  const ProductCard({
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
        height: 280,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagen — height 140px igual que React ─────────────────────
            SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                    Image.network(product.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, e, st) => _imageFallback())
                  else
                    _imageFallback(),

                  // Gradiente inferior sutil
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.surface, Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),

                  // Rating badge — top right
                  if (product.rating != null && product.rating! > 0)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 10, color: Color(0xFFFFD700)),
                            const SizedBox(width: 3),
                            Text(product.rating!.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white,
                                    fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),

                  // Tag — top left
                  if (product.tags.isNotEmpty)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(product.tags.first,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),

            // ── Cuerpo — height 140px igual que React ─────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre — 2 líneas máx, minHeight 2.6em
                    SizedBox(
                      height: 38,
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: theme.text,
                          height: 1.3,
                        ),
                      ),
                    ),

                    // Descripción — 2 líneas máx, flex-1
                    Expanded(
                      child: Text(
                        product.description?.trim().isNotEmpty == true
                            ? product.description!
                            : product.components.join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textMuted,
                          height: 1.5,
                        ),
                      ),
                    ),

                    // Precio + botón "Ver más" — siempre al fondo
                    Divider(color: theme.border, height: 16, thickness: 1),
                    Row(
                      children: [
                        // Precio (con promo si aplica)
                        if (product.hasPromo) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\$${_fmtPrice(product.price)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Text(
                                '\$${_fmtPrice(product.promoPrice!)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: Color(0xFF22C55E),
                                ),
                              ),
                            ],
                          ),
                        ] else
                          Text(
                            '\$${_fmtPrice(product.price)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: theme.primary,
                            ),
                          ),

                        const Spacer(),

                        // Botón "Ver más"
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.primary, width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_outlined, size: 10, color: theme.primary),
                                const SizedBox(width: 4),
                                Text('Ver más',
                                    style: TextStyle(fontSize: 10,
                                        fontWeight: FontWeight.w700, color: theme.primary)),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _imageFallback() => Container(color: theme.surfaceAlt);

  String _fmtPrice(double p) {
    final s = p == p.toInt()
        ? p.toInt().toString()
        : p.toString();
    return s.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}
