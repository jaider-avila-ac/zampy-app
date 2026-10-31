import 'package:flutter/material.dart';

import '../../../../shared/app_colors.dart';

/// Los botones para avanzar un pedido: cancelar (pendiente o en preparación), preparar (pendiente) y entregado (en
/// preparación). [actualizando]: el estado al que se está cambiando (spinner en su botón).
class AccionesPedido extends StatelessWidget {
  const AccionesPedido({super.key, required this.estado, required this.actualizando, required this.onCambiar});

  final String estado;
  final String? actualizando;
  final ValueChanged<String> onCambiar;

  @override
  Widget build(BuildContext context) {
    final ocupado = actualizando != null;
    Widget contenido(String accion, String texto, Color color) => actualizando == accion
        ? SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 1.8, color: color))
        : Text(texto);
    const estilo = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
    const padding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (estado == 'pendiente' || estado == 'en_proceso')
          TextButton(
            onPressed: ocupado ? null : () => onCambiar('cancelado'),
            style: TextButton.styleFrom(foregroundColor: AppColors.kRed, textStyle: estilo, padding: padding, minimumSize: Size.zero),
            child: contenido('cancelado', 'Cancelar', AppColors.kRed),
          ),
        if (estado == 'pendiente')
          OutlinedButton(
            onPressed: ocupado ? null : () => onCambiar('en_proceso'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.kBlue,
              side: const BorderSide(color: Color(0xFFC7D2FE)),
              textStyle: estilo,
              padding: padding,
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: contenido('en_proceso', 'Preparar', AppColors.kBlue),
          ),
        if (estado == 'en_proceso')
          FilledButton(
            onPressed: ocupado ? null : () => onCambiar('entregado'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.kTextPrimary,
              textStyle: estilo,
              padding: padding,
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: contenido('entregado', 'Entregado', Colors.white),
          ),
      ],
    );
  }
}
