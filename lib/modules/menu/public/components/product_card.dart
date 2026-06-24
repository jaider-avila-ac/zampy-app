import 'package:flutter/material.dart' hide MenuTheme;
import '../models/public_menu_model.dart';

// Equivalente a src/components/ProductCard.jsx en React
// Altura fija 280px: imagen 140px arriba + cuerpo 140px abajo

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.theme,
    required this.onTap,
  });

  final MenuProduct  product;
  final MenuTheme    theme;
  final VoidCallback onTap;

  // Mismo formato colombiano que React: 18000 → "18.000"
  static String _fmt(double p) {
    final s = p.toStringAsFixed(0);
    final buf = StringBuffer();
    int c = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (c > 0 && c % 3 == 0) buf.write('.');
      buf.write(s[i]);
      c++;
    }
    return buf.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final t = theme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // altura fija 280px igual que React
        height: 280,
        decoration: BoxDecoration(
          color:        t.surface,
          borderRadius: BorderRadius.circular(t.cardRadius),
          border:       Border.all(color: t.border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Bloque superior: imagen 140px ────────────────────────────
            SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen o fondo fallback
                  (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, e, st) => Container(color: t.surfaceAlt),
                        )
                      : Container(color: t.surfaceAlt),

                  // Gradiente sutil inferior — React: c.surface con 80% opacidad → transparent
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end:   Alignment.topCenter,
                          colors: [
                            t.surface.withValues(alpha: 0.80),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Rating badge — top-right — solo si rating > 0
                  if (product.rating != null && product.rating! > 0)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:        Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 10, color: Color(0xFFFFD700)),
                            const SizedBox(width: 3),
                            Text(
                              product.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Tag badge — top-left — solo si hay al menos un tag
                  if (product.tags.isNotEmpty)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:        t.primary,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          product.tags.first,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Bloque inferior: cuerpo 140px ────────────────────────────
            // React: px-3 pt-2 pb-3 → 12px horizontal, 8px arriba, 12px abajo
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Nombre — font-bold 14px, máx 2 líneas, minHeight 2.6em (~36px)
                    SizedBox(
                      height: 36,
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize:   14,
                          color:      t.text,
                          height:     1.3,
                        ),
                      ),
                    ),

                    // Descripción — 12px, flex-1, máx 2 líneas
                    // Si no hay description, muestra components unidos por coma
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _descriptionText(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color:    t.textMuted,
                            height:   1.5,
                          ),
                        ),
                      ),
                    ),

                    // Precio + botón — siempre al fondo, con separador
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: t.border)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

                          // Precio: promo tachado + verde, o precio normal en primary
                          if (product.hasPromo) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\$${_fmt(product.price)}',
                                  style: TextStyle(
                                    fontSize:   11,
                                    color:      t.textMuted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                Text(
                                  '\$${_fmt(product.promoPrice!)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize:   16,
                                    color:      Color(0xFF22C55E),
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            Text(
                              '\$${_fmt(product.price)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize:   16,
                                color:      t.primary,
                              ),
                            ),

                          const Spacer(),

                          // Botón "Ver más" — fondo transparente, borde primary 1.5px
                          GestureDetector(
                            onTap: onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:        Colors.transparent,
                                border:       Border.all(color: t.primary, width: 1.5),
                                borderRadius: BorderRadius.circular(t.buttonRadius),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_outlined, size: 10, color: t.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ver más',
                                    style: TextStyle(
                                      fontSize:   10,
                                      fontWeight: FontWeight.w700,
                                      color:      t.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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

  // Descripción: usa description si existe y no está vacía, sino components con coma
  String _descriptionText() {
    final desc = product.description?.trim() ?? '';
    if (desc.isNotEmpty) return desc;
    if (product.components.isNotEmpty) return product.components.join(', ');
    return '';
  }
}
