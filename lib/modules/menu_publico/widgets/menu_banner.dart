import 'package:flutter/material.dart';
import '../models/menu_publico_model.dart';

/// Equivalente a Banner.jsx — hero de 340px con imagen, gradiente e info del negocio.
/// El botón de presentación automática NO aparece en móvil (es `hidden md:flex` en JSX).
/// El botón "Sorpréndeme" sí aparece siempre.
class MenuBanner extends StatefulWidget {
  const MenuBanner({
    super.key,
    required this.business,
    required this.theme,
    this.surpriseProducts = const [],
    this.onSurprise,
  });

  final BusinessInfo business;
  final MenuPublicoTheme theme;
  final List<Producto> surpriseProducts;
  final void Function(Producto)? onSurprise;

  @override
  State<MenuBanner> createState() => _MenuBannerState();
}

class _MenuBannerState extends State<MenuBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _handleSurprise() {
    final products = widget.surpriseProducts;
    if (products.isEmpty || widget.onSurprise == null) return;
    _shakeController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 480), () {
      if (!mounted) return;
      final random = products[
          (products.length * (DateTime.now().millisecondsSinceEpoch % 1000 /
                  1000.0))
              .floor()
              .clamp(0, products.length - 1)];
      widget.onSurprise!(random);
    });
  }

  BusinessInfo get business => widget.business;
  MenuPublicoTheme get theme => widget.theme;

  @override
  Widget build(BuildContext context) {
    final hasBanner =
        business.bannerUrl != null && business.bannerUrl!.isNotEmpty;
    final hasProducts = widget.surpriseProducts.isNotEmpty &&
        widget.onSurprise != null;

    return SizedBox(
      height: 340,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo: imagen o gradiente del color primario
          if (hasBanner)
            Image.network(
              business.bannerUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _colorBg(),
            )
          else
            _colorBg(),

          // Gradiente oscuro sobre la imagen (móvil)
          if (hasBanner)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x4D000000),
                    Colors.transparent,
                    Color(0xB8000000),
                  ],
                  stops: [0.0, 0.28, 1.0],
                ),
              ),
            ),

          // Botón "Sorpréndeme" — esquina inferior derecha
          // (El slideshow es hidden md:flex en JSX → no aparece en móvil)
          if (hasProducts)
            Positioned(
              bottom: 16,
              right: 16,
              child: AnimatedBuilder(
                animation: _shakeController,
                builder: (_, child) {
                  final angle = (_shakeController.value < 0.5
                          ? _shakeController.value
                          : 1.0 - _shakeController.value) *
                      0.3;
                  return Transform.rotate(angle: angle, child: child);
                },
                child: GestureDetector(
                  onTap: _handleSurprise,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: theme.primary.withValues(alpha: 0.66)),
                    ),
                    child: const Icon(Icons.shuffle_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ),

          // Contenido: logo + nombre + stats + tags (alineado al fondo)
          Positioned(
            left: 16,
            right: hasProducts ? 64 : 16,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo + nombre
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildLogo(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                              height: 1.1,
                              shadows: [
                                Shadow(
                                    blurRadius: 14,
                                    color: Colors.black54),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (business.slogan != null &&
                              business.slogan!.isNotEmpty)
                            Text(
                              business.slogan!,
                              style: const TextStyle(
                                color: Color(0xD9FFFFFF),
                                fontSize: 13,
                                shadows: [
                                  Shadow(
                                      blurRadius: 6,
                                      color: Colors.black45),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Stats (rating + dirección)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (business.rating != null && business.rating! > 0)
                      _StatChip(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFFFD700),
                        label:
                            '${business.rating} · ${_fmtNum(business.reviews ?? 0)} reseñas',
                      ),
                    if (business.address != null &&
                        business.address!.isNotEmpty)
                      _StatChip(
                        icon: Icons.location_on_outlined,
                        label: business.address!,
                      ),
                  ],
                ),

                // Tags
                if (business.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: business.tags
                        .map((tag) => _TagChip(label: tag, color: theme.primary))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorBg() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.primary, _darken(theme.primary)],
          ),
        ),
      );

  Widget _buildLogo() {
    final hasLogo =
        business.logoUrl != null && business.logoUrl!.isNotEmpty;
    if (hasLogo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          business.logoUrl!,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _logoFallback(),
        ),
      );
    }
    return _logoFallback();
  }

  Widget _logoFallback() => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          business.name.isNotEmpty ? business.name[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22),
        ),
      );

  static Color _darken(Color c) => c.withValues(
      red: c.r * 0.75, green: c.g * 0.75, blue: c.b * 0.75);

  static String _fmtNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, this.iconColor});
  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12,
              color: iconColor ?? Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
