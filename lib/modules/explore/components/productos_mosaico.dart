import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../shared/app_colors.dart';
import '../models/explore_models.dart';
import 'producto_card.dart';
import 'skeleton_product_card.dart';

// Equivalente a src/modules/explore/components/ProductosMosaico.jsx en React.
// La paginación la controla ExploreController.
class ProductosMosaico extends StatefulWidget {
  const ProductosMosaico({
    super.key,
    required this.items,
    required this.loading,
    required this.hasMore,
    required this.likedIds,
    required this.conSesion,
    required this.onTap,
    required this.onToggleLike,
    required this.onRequireLogin,
    this.error,
    this.onRetry,
    this.q = '',
  });

  final List<TarjetaProducto> items;
  final bool loading;
  final bool hasMore;
  final Set<String> likedIds;
  final bool conSesion;
  final String? error;
  final VoidCallback? onRetry;
  final void Function(TarjetaProducto) onTap;
  final void Function(TarjetaProducto) onToggleLike;
  final VoidCallback onRequireLogin;
  final String q;

  @override
  State<ProductosMosaico> createState() => _ProductosMosaicoState();
}

class _ProductosMosaicoState extends State<ProductosMosaico> {
  // Productos cuya imagen falló al cargar (URL rota / 404): como React, no se muestran.
  final Set<String> _fallidos = {};

  void _marcarFallo(String codigo) {
    if (_fallidos.contains(codigo)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _fallidos.add(codigo)) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Igual que React: un producto sin foto (URL vacía) o cuya imagen falla al cargar NO se muestra.
    final visibles = widget.items
        .where((p) =>
            (p.imagenUrl ?? '').trim().isNotEmpty && !_fallidos.contains(p.codigo))
        .toList();

    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1200
        ? 5
        : width >= 900
        ? 4
        : width >= 600
        ? 3
        : 2;

    if (widget.loading && widget.items.isEmpty) {
      const heights = [190.0, 250.0, 160.0, 220.0, 270.0, 180.0, 230.0, 200.0];
      return MasonryGridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        itemCount: heights.length,
        itemBuilder: (_, index) => SkeletonProductCard(height: heights[index]),
      );
    }

    if (widget.items.isEmpty && widget.error == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Center(
          child: Text(
            widget.q.isNotEmpty
                ? 'No hay platos que coincidan con "${widget.q}".'
                : 'No hay platos con estos filtros.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.kTextMuted),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (widget.error != null && widget.items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 18, color: Color(0xFFB91C1C)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.error!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                  ),
                ),
                if (widget.onRetry != null)
                  TextButton(onPressed: widget.onRetry, child: const Text('Reintentar')),
              ],
            ),
          )
        else
          Builder(
            builder: (_) {
              // al cargar más, se agregan tarjetas-esqueleto al final del mismo tablero
              final cargandoMas = widget.loading && widget.items.isNotEmpty;
              const hs = [190.0, 250.0, 160.0, 220.0, 270.0, 180.0, 230.0, 200.0];
              final skeletons = cargandoMas ? columns * 2 : 0;
              return MasonryGridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                itemCount: visibles.length + skeletons,
                itemBuilder: (context, index) {
                  if (index >= visibles.length) {
                    return SkeletonProductCard(height: hs[index % hs.length]);
                  }
                  final producto = visibles[index];
                  return ProductoCard(
                    producto: producto,
                    liked: widget.likedIds.contains(producto.codigo),
                    conSesion: widget.conSesion,
                    onTap: () => widget.onTap(producto),
                    onToggleLike: () => widget.onToggleLike(producto),
                    onRequireLogin: widget.onRequireLogin,
                    onImageError: () => _marcarFallo(producto.codigo),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
