import 'package:flutter/material.dart';
import '../../../shared/app_colors.dart';
import '../../menu_publico/public_menu_screen.dart';
import '../models/menu_feed_item.dart';

/// Tarjeta de menú en formato lista (una columna).
/// Logo a la izquierda centrado, información a la derecha.
/// Alto fijo garantizado por los SizedBox internos → todos los items iguales.
class MenuCardWidget extends StatelessWidget {
  const MenuCardWidget({
    super.key,
    required this.menu,
    this.liked = false,
  });

  final MenuFeedItem menu;
  final bool liked;

  void _open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicMenuScreen(slug: menu.slug),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CardLogo(logoUrl: menu.logoUrl, icono: menu.iconoCategoria),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CardName(name: menu.nombreNegocio),
                const SizedBox(height: 3),
                _CardSlogan(slogan: menu.slogan),
                const SizedBox(height: 5),
                _CardFooter(
                  ciudad: menu.ciudad,
                  meEncantas: menu.meEncantas,
                  liked: liked,
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

// ── Sub-widgets (responsabilidad única) ──────────────────────────────────────

class _CardLogo extends StatelessWidget {
  const _CardLogo({required this.logoUrl, required this.icono});
  final String? logoUrl;
  final String? icono;

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl != null && logoUrl!.isNotEmpty;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.kBgPage,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      clipBehavior: Clip.hardEdge,
      child: hasLogo
          ? Image.network(
              logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    final hasIcono = icono != null && icono!.isNotEmpty;
    return Center(
      child: hasIcono
          ? Text(icono!, style: const TextStyle(fontSize: 22))
          : const Icon(Icons.restaurant_menu_outlined,
              size: 22, color: AppColors.kTextMuted),
    );
  }
}

class _CardName extends StatelessWidget {
  const _CardName({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.kTextPrimary,
        fontSize: 13,
        height: 1.3,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Alto fijo de 28 px → reserva siempre 2 líneas aunque el slogan esté vacío.
class _CardSlogan extends StatelessWidget {
  const _CardSlogan({required this.slogan});
  final String? slogan;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Text(
        slogan ?? '',
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.kTextMuted,
          height: 1.4,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({
    required this.ciudad,
    required this.meEncantas,
    required this.liked,
  });

  final String? ciudad;
  final int meEncantas;
  final bool liked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (ciudad != null && ciudad!.isNotEmpty) ...[
          const Icon(Icons.location_on_outlined,
              size: 10, color: AppColors.kTextMuted),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              ciudad!,
              style: const TextStyle(fontSize: 10, color: AppColors.kTextMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ] else
          const Spacer(),
        if (meEncantas > 0 || liked) ...[
          Icon(
            liked ? Icons.favorite : Icons.favorite_border,
            size: 10,
            color: liked ? AppColors.kBlue : AppColors.kTextMuted,
          ),
          if (meEncantas > 0) ...[
            const SizedBox(width: 2),
            Text(
              '$meEncantas',
              style: TextStyle(
                fontSize: 10,
                color: liked ? AppColors.kBlue : AppColors.kTextMuted,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
