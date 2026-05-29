import 'package:flutter/material.dart';
import '../models/menu_publico_model.dart';

/// Equivalente a MenuCarouselView.jsx — tarjetas deslizables con peek lateral,
/// flechas, puntos indicadores y contador numérico.
class MenuCarouselView extends StatefulWidget {
  const MenuCarouselView({
    super.key,
    required this.products,
    required this.theme,
    required this.onProductClick,
  });

  final List<Producto> products;
  final MenuPublicoTheme theme;
  final void Function(Producto) onProductClick;

  @override
  State<MenuCarouselView> createState() => _MenuCarouselViewState();
}

class _MenuCarouselViewState extends State<MenuCarouselView> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.84);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = (_index + delta).clamp(0, widget.products.length - 1);
    if (next == _index) return;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _goTo(int i) {
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final th = widget.theme;
    final total = widget.products.length;
    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: [
        // ── Pista de tarjetas ───────────────────────────────────
        SizedBox(
          height: 440,
          child: PageView.builder(
            controller: _controller,
            itemCount: total,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) =>
                _buildCard(widget.products[i], th),
          ),
        ),

        const SizedBox(height: 14),

        // ── Flechas + puntos ────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NavArrow(
              dir: 'left',
              theme: th,
              onTap: () => _go(-1),
            ),
            const SizedBox(width: 12),

            // Dots
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(total, (i) {
                    final isActive = i == _index;
                    return GestureDetector(
                      onTap: () => _goTo(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isActive ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isActive ? th.primary : th.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(width: 12),
            _NavArrow(
              dir: 'right',
              theme: th,
              onTap: () => _go(1),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // ── Contador numérico ───────────────────────────────────
        Text(
          '${_index + 1} / $total',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: th.textMuted,
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCard(Producto product, MenuPublicoTheme th) {
    final hasImage = product.image != null && product.image!.isNotEmpty;
    final hasRating = product.rating != null;
    final hasTags = product.tags.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => widget.onProductClick(product),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen o fondo de color
              if (hasImage)
                Image.network(
                  product.image!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _colorBg(th),
                )
              else
                _colorBg(th),

              // Gradiente — igual que el JSX:
              // linear-gradient(to top, black 0%, primary55 38%, transparent 65%)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.78),
                      th.primary.withValues(alpha: 0.33),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.38, 0.65],
                  ),
                ),
              ),

              // Tags — esquina superior izquierda
              if (hasTags)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: product.tags.take(2).map((tag) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: th.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Rating — esquina superior derecha
              if (hasRating)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: Color(0xFFFFD700)),
                        const SizedBox(width: 4),
                        Text(
                          product.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Contenido inferior
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nombre
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.black54),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (product.description != null &&
                          product.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.description!,
                          style: const TextStyle(
                            color: Color(0xD1FFFFFF),
                            fontSize: 13,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Precio + botón "Ver más"
                      Row(
                        children: [
                          Text(
                            '\$${MenuPublicoTheme.fmtPrice(product.displayPrice)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(blurRadius: 12, color: Colors.black38),
                              ],
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => widget.onProductClick(product),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: th.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_outlined,
                                      color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ver más',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorBg(MenuPublicoTheme th) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [th.primary, th.primary.withValues(alpha: 0.6)],
          ),
        ),
      );
}

// ── Flecha de navegación ────────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  const _NavArrow({
    required this.dir,
    required this.theme,
    required this.onTap,
  });

  final String dir;
  final MenuPublicoTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.primary, width: 2),
        ),
        child: Icon(
          dir == 'left'
              ? Icons.chevron_left_rounded
              : Icons.chevron_right_rounded,
          color: theme.primary,
          size: 22,
        ),
      ),
    );
  }
}
