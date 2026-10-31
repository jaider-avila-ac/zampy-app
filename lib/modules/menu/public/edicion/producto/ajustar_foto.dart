import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../shared/app_colors.dart';

// Equivalente a src/modules/menu/public/edicion/producto/AjustarFoto.jsx en React.

/// La foto del producto con la proporción con que se ve en la tarjeta (~9:7), para elegir qué parte se ve: se arrastra
/// la foto y se guarda la posición {x, y} en porcentaje (imagePosition), que usan la tarjeta, la lista y el detalle.
class AjustarFoto extends StatefulWidget {
  const AjustarFoto({
    super.key,
    this.url,
    this.archivo,
    required this.posicion,
    required this.onPosicion,
    this.onCambiar,
    this.onQuitar,
  });

  final String? url;
  final File? archivo;
  final Offset posicion; // x, y en 0-100
  final ValueChanged<Offset> onPosicion;
  final VoidCallback? onCambiar;
  final VoidCallback? onQuitar;

  @override
  State<AjustarFoto> createState() => _AjustarFotoState();
}

class _AjustarFotoState extends State<AjustarFoto> {
  double _limitar(double n) => n.clamp(0, 100).roundToDouble();

  @override
  Widget build(BuildContext context) {
    final p = widget.posicion;
    final alineacion = Alignment(p.dx / 50 - 1, p.dy / 50 - 1);
    final imagen = widget.archivo != null
        ? Image.file(widget.archivo!, fit: BoxFit.cover, alignment: alineacion)
        : Image.network(widget.url!, fit: BoxFit.cover, alignment: alineacion);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Foto del producto', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, caja) => GestureDetector(
            onPanUpdate: (d) {
              final ancho = caja.maxWidth;
              final alto = ancho * 7 / 9;
              // arrastrar a la derecha muestra más de la izquierda de la foto (como al acomodar una foto de perfil)
              widget.onPosicion(Offset(
                _limitar(widget.posicion.dx - d.delta.dx / ancho * 100),
                _limitar(widget.posicion.dy - d.delta.dy / alto * 100),
              ));
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(aspectRatio: 9 / 7, child: imagen),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Row(
          children: [
            Icon(Icons.open_with, size: 14, color: AppColors.kTextMuted),
            SizedBox(width: 4),
            Expanded(
              child: Text('Arrastra la foto para elegir qué parte se ve en la tarjeta',
                  style: TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
            ),
          ],
        ),
        Wrap(
          spacing: 4,
          children: [
            TextButton.icon(
              onPressed: () => widget.onPosicion(const Offset(50, 50)),
              icon: const Icon(Icons.center_focus_strong_outlined, size: 15),
              label: const Text('Centrar'),
            ),
            if (widget.onCambiar != null)
              TextButton.icon(
                onPressed: widget.onCambiar,
                icon: const Icon(Icons.image_outlined, size: 15),
                label: const Text('Cambiar foto'),
              ),
            if (widget.onQuitar != null)
              TextButton.icon(
                onPressed: widget.onQuitar,
                style: TextButton.styleFrom(foregroundColor: AppColors.kRed),
                icon: const Icon(Icons.delete_outline, size: 15),
                label: const Text('Quitar'),
              ),
          ],
        ),
      ],
    );
  }
}
