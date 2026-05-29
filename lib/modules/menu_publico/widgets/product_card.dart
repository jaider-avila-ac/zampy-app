import 'package:flutter/material.dart';
import '../models/menu_publico_model.dart';
import 'price_widget.dart';

/// Equivalente a ProductCard.jsx — carta en cuadrícula, altura fija 280px.
class ProductCard extends StatelessWidget {
  const ProductCard({
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
            // Imagen 140px
            _ProductImage(product: product, theme: theme),
            // Contenido 140px
            Expanded(child: _ProductBody(product: product, theme: theme, onTap: onTap)),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product, required this.theme});
  final Producto product;
  final MenuPublicoTheme theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (product.image != null && product.image!.isNotEmpty)
            Image.network(
              product.image!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(),
            )
          else
            _placeholder(),

          // Gradiente sutil inferior
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    theme.surface.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Rating badge
          if (product.rating != null && product.rating! > 0)
            Positioned(
              top: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 10, color: Color(0xFFFFD700)),
                    const SizedBox(width: 2),
                    Text(
                      product.rating!.toStringAsFixed(1),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // Tag principal
          if (product.tags.isNotEmpty)
            Positioned(
              top: 8, left: 8,
              child: _TagBadge(label: product.tags.first, color: theme.primary),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(color: theme.surfaceAlt);
}

class _ProductBody extends StatelessWidget {
  const _ProductBody({
    required this.product,
    required this.theme,
    required this.onTap,
  });
  final Producto product;
  final MenuPublicoTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre 2 líneas
          Text(
            product.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: theme.text,
              fontSize: 12,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Descripción 2 líneas
          Expanded(
            child: Text(
              product.description ?? '',
              style: TextStyle(
                  fontSize: 10, color: theme.textMuted, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Footer: precio + botón
          Divider(height: 1, color: theme.border),
          const SizedBox(height: 6),
          Row(
            children: [
              MenuPriceWidget(product: product, theme: theme),
              const Spacer(),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.primary, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.remove_red_eye_outlined,
                          size: 10, color: theme.primary),
                      const SizedBox(width: 3),
                      Text(
                        'Ver más',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared pequeños ──────────────────────────────────────────────────────────

class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700),
        ),
      );
}

