import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../shared/app_colors.dart';

// Equivalente a src/modules/menu/public/edicion/producto/AjustarFoto.jsx en React.

/// La foto del producto con la MISMA caja del "ver más" (detalle): ancho completo × 200px de alto, para que lo que se
/// elige sea exactamente lo que se ve al abrir el producto. Se arrastra la foto y se guarda la posición {x, y} en
/// porcentaje (imagePosition), que usan la tarjeta, la lista y el detalle.
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
          builder: (context, caja) {
            // misma caja que el detalle "ver más": ancho completo × 200px de alto (ver product_modal.dart)
            const alto = 200.0;
            final ancho = caja.maxWidth;
            return GestureDetector(
              // tocar la foto = cambiarla (abre el selector); arrastrarla = elegir qué parte se ve
              onTap: widget.onCambiar,
              onPanUpdate: (d) {
                widget.onPosicion(Offset(
                  _limitar(widget.posicion.dx - d.delta.dx / ancho * 100),
                  _limitar(widget.posicion.dy - d.delta.dy / alto * 100),
                ));
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: alto,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imagen,
                      if (widget.onCambiar != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.photo_camera_outlined, size: 15, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        const Row(
          children: [
            Icon(Icons.open_with, size: 14, color: AppColors.kTextMuted),
            SizedBox(width: 4),
            Expanded(
              child: Text('Toca la foto para cambiarla · arrástrala para elegir qué parte se ve',
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
