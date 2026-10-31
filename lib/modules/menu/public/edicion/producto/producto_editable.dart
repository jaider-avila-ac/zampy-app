import 'package:flutter/material.dart';

import '../../../../../shared/app_colors.dart';
import '../../models/public_menu_model.dart';
import '../edicion_menu.dart';
import 'acciones_producto.dart';

// Equivalente a src/modules/menu/public/edicion/producto/ProductoEditable.jsx en React.

/// Envuelve la tarjeta de un producto cuando el dueño (o un editor) edita su menú: agrega el botón "⋯" con cada parte
/// del producto y las acciones que se aplican de una vez. Un producto oculto se ve atenuado y marcado. Sin edición
/// activa devuelve la tarjeta tal cual.
class ProductoEditable extends StatefulWidget {
  const ProductoEditable({super.key, required this.producto, required this.child});

  final MenuProduct producto;
  final Widget child;

  @override
  State<ProductoEditable> createState() => _ProductoEditableState();
}

class _ProductoEditableState extends State<ProductoEditable> {
  bool _ocupado = false;

  static const _grises = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final edicion = EdicionMenu.of(context);
    if (edicion == null) return widget.child;
    final oculto = !widget.producto.isVisible;
    final opciones = accionesProducto(
      context,
      widget.producto,
      edicion,
      onOcupado: (v) {
        if (mounted) setState(() => _ocupado = v);
      },
    );

    return Stack(
      children: [
        oculto ? ColorFiltered(colorFilter: _grises, child: widget.child) : widget.child,
        if (oculto)
          Positioned(
            left: 8,
            bottom: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(99)),
                child: const Text('Oculto', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(side: BorderSide(color: AppColors.kCardBorder)),
            elevation: 2,
            child: SizedBox(
              width: 34,
              height: 34,
              child: _ocupado
                  ? const Padding(padding: EdgeInsets.all(9), child: CircularProgressIndicator(strokeWidth: 2))
                  : PopupMenuButton<int>(
                      tooltip: 'Opciones de ${widget.producto.name}',
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.kTextPrimary),
                      onSelected: (i) => opciones[i].accion(),
                      itemBuilder: (_) => [
                        for (var i = 0; i < opciones.length; i++) ...[
                          if (opciones[i].separado) const PopupMenuDivider(),
                          PopupMenuItem<int>(
                            value: i,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(opciones[i].icono, size: 18, color: opciones[i].peligro ? AppColors.kRed : AppColors.kBlue),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(opciones[i].texto,
                                      style: TextStyle(color: opciones[i].peligro ? AppColors.kRed : AppColors.kTextPrimary)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
