import 'package:flutter/material.dart';

import '../../../shared/app_colors.dart';
import '../models/explore_models.dart';
import 'acciones_tarjeta.dart';

// Equivalente a src/modules/explore/components/ProductoCard.jsx en React

class ProductoCard extends StatelessWidget {
  const ProductoCard({
    super.key,
    required this.producto,
    this.liked = false,
    this.conSesion = false,
    this.onTap,
    this.onToggleLike,
    this.onRequireLogin,
  });

  final TarjetaProducto producto;
  final bool liked;
  final bool conSesion;
  final VoidCallback? onTap;
  final VoidCallback? onToggleLike;
  final VoidCallback? onRequireLogin;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Proporción fija por producto: la altura se reserva desde el inicio, así el tablero
                // (MasonryGridView, que reparte en la columna más corta) queda alineado sin saltos al cargar.
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: _aspect(producto.codigo),
                    child:
                        producto.imagenUrl != null &&
                            producto.imagenUrl!.isNotEmpty
                        ? Image.network(
                            producto.imagenUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) =>
                                _sinImagen(),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : _sinImagen(),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    producto.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          producto.menuNombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.kTextSecondary,
                          ),
                        ),
                      ),
                      if (producto.meEncantas > 0 || liked) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.favorite,
                          size: 11,
                          color: Color(0xFFE11D48),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${producto.meEncantas}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.kTextMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: AccionesTarjeta(
            encanta: liked,
            conSesion: conSesion,
            onVerMas: onTap ?? () {},
            onEncanta: onToggleLike ?? () {},
            onRequireLogin: onRequireLogin ?? () {},
          ),
        ),
      ],
    );
  }

  Widget _sinImagen() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(
          Icons.restaurant_outlined,
          size: 30,
          color: Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  // proporciones variadas (estilo Pinterest) pero estables por producto, para que el tablero no salte
  static const _aspects = [0.80, 0.72, 1.0, 0.85, 0.75];
  double _aspect(String codigo) => _aspects[codigo.hashCode.abs() % _aspects.length];
}
