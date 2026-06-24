import 'package:flutter/material.dart' hide MenuTheme;
import '../models/public_menu_model.dart';

// Equivalente a src/modules/menu/public/components/CarouselView.jsx en React
// Carrusel horizontal con peek cards a los lados, dots y flechas de navegación

class CarouselView extends StatefulWidget {
  const CarouselView({
    super.key,
    required this.products,
    required this.theme,
    required this.onProductTap,
  });
  final List<MenuProduct> products;
  final MenuTheme         theme;
  final ValueChanged<MenuProduct> onProductTap;

  @override
  State<CarouselView> createState() => _CarouselViewState();
}

class _CarouselViewState extends State<CarouselView> {
  int     _index     = 0;
  double? _dragStart;

  int get _total => widget.products.length;

  void _go(int delta) {
    if (_total == 0) return;
    setState(() => _index = (_index + delta + _total) % _total);
  }

  @override
  Widget build(BuildContext context) {
    if (_total == 0) return const SizedBox.shrink();
    final t    = widget.theme;
    final prods = widget.products;
    final p    = prods[_index];
    final prev = prods[(_index - 1 + _total) % _total];
    final next = prods[(_index + 1) % _total];

    return Column(
      children: [
        // ── Área principal con peek cards ──────────────────────────────
        GestureDetector(
          onHorizontalDragStart: (d) => _dragStart = d.globalPosition.dx,
          onHorizontalDragEnd: (d) {
            if (_dragStart == null) return;
            final diff = _dragStart! - d.globalPosition.dx;
            if (diff.abs() > 45) _go(diff > 0 ? 1 : -1);
            _dragStart = null;
          },
          child: SizedBox(
            height: 460,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Peek izquierda
                Positioned(left: 0, child: _PeekCard(product: prev, onTap: () => _go(-1), theme: t)),
                // Peek derecha
                Positioned(right: 0, child: _PeekCard(product: next, onTap: () => _go(1), theme: t)),
                // Tarjeta principal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 44),
                  child: _MainCard(
                    product: p,
                    theme:   t,
                    onTap:   () => widget.onProductTap(p),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── Flechas + dots ────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NavArrow(left: true,  theme: t, onTap: () => _go(-1)),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: _buildDots(t),
            ),
            const SizedBox(width: 12),
            _NavArrow(left: false, theme: t, onTap: () => _go(1)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${_index + 1} / $_total',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.textMuted),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  List<Widget> _buildDots(MenuTheme t) {
    final List<int> indices = _total <= 3
        ? List.generate(_total, (i) => i)
        : _index == 0
            ? [0, 1, 2]
            : _index == _total - 1
                ? [_total - 3, _total - 2, _total - 1]
                : [_index - 1, _index, _index + 1];

    return indices.map((i) => GestureDetector(
      onTap: () => setState(() => _index = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width:  i == _index ? 24 : 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color:        i == _index ? t.primary : t.border,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    )).toList();
  }
}

// ── Tarjeta principal ────────────────────────────────────────────────────────
class _MainCard extends StatelessWidget {
  const _MainCard({required this.product, required this.theme, required this.onTap});
  final MenuProduct product;
  final MenuTheme   theme;
  final VoidCallback onTap;

  static String _fmt(double price) {
    final s = price.toStringAsFixed(0);
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
    final t   = theme;
    final p   = product;
    final img = p.imageUrl;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(t.cardRadius),
        child: SizedBox(
          height: 420,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen
              if (img != null && img.isNotEmpty)
                Image.network(img, fit: BoxFit.cover,
                  errorBuilder: (ctx, e, st) => Container(color: t.surfaceAlt))
              else
                Container(color: t.surfaceAlt, child: Icon(Icons.fastfood_outlined, size: 64, color: t.border)),

              // Gradiente igual que React
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end:   Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      t.primary.withValues(alpha: 0.33),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                    stops: const [0.35, 0.62, 1.0],
                  ),
                ),
              ),

              // Rating badge arriba derecha
              if (p.rating != null)
                Positioned(
                  top: 14, right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star, size: 12, color: Color(0xFFFFD700)),
                      const SizedBox(width: 3),
                      Text(p.rating!.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),

              // Tags arriba izquierda
              if (p.tags.isNotEmpty)
                Positioned(
                  top: 14, left: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: p.tags.take(2).map((tag) => Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: t.primary,
                        borderRadius: BorderRadius.circular(t.badgeRadius),
                      ),
                      child: Text(tag,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                    )).toList(),
                  ),
                ),

              // Info abajo
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900,
                          color: Colors.white, height: 1.2,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                        ),
                      ),
                      if (p.description != null && p.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          p.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12, height: 1.4,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${_fmt(p.effectivePrice)}',
                            style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 12, color: Colors.black45)],
                            ),
                          ),
                          GestureDetector(
                            onTap: onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: t.primary,
                                borderRadius: BorderRadius.circular(t.buttonRadius),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.visibility_outlined, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                const Text('Ver más',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                              ]),
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
      ),
    );
  }
}

// ── Peek card (tarjeta lateral borrosa) ──────────────────────────────────────
class _PeekCard extends StatelessWidget {
  const _PeekCard({required this.product, required this.theme, required this.onTap});
  final MenuProduct  product;
  final MenuTheme    theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final img = product.imageUrl;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: 0.4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(theme.cardRadius),
          child: SizedBox(
            width: 52, height: 320,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (img != null && img.isNotEmpty)
                  Image.network(img, fit: BoxFit.cover,
                    errorBuilder: (ctx, e, st) => Container(color: theme.surfaceAlt))
                else
                  Container(color: theme.surfaceAlt),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end:   Alignment.bottomCenter,
                      colors: [Colors.transparent, theme.bg.withValues(alpha: 0.8)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Flecha de navegación ──────────────────────────────────────────────────────
class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.left, required this.theme, required this.onTap});
  final bool         left;
  final MenuTheme    theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color:        theme.surface,
        borderRadius: BorderRadius.circular(theme.buttonRadius),
        border:       Border.all(color: theme.primary, width: 2),
      ),
      child: Icon(
        left ? Icons.chevron_left : Icons.chevron_right,
        size: 20, color: theme.primary,
      ),
    ),
  );
}
