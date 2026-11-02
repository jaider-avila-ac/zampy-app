import 'package:flutter/material.dart';

import '../../../../shared/app_colors.dart';
import '../../../orders/models/cuenta_mesa.dart';
import '../../../orders/utils/formato.dart';
import '../../utils/estado_ronda.dart';

/// Una ronda de la cuenta: estado, nota, ítems, total y los botones para avanzarla o cancelarla.
class RondaCard extends StatelessWidget {
  const RondaCard({
    super.key,
    required this.ronda,
    required this.actualizando,
    required this.onCambiarEstado,
    required this.onCancelar,
  });

  final RondaCuenta ronda;
  final String? actualizando; // código de la ronda que está cambiando (deshabilita todas)
  final ValueChanged<String> onCambiarEstado;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final estado = estadoRonda(ronda.estado);
    final ocupada = actualizando != null;
    final cargandoEsta = actualizando == ronda.codigo;

    Widget avanzar(String destino, String texto, Color color) => Expanded(
          child: FilledButton.icon(
            onPressed: ocupada ? null : () => onCambiarEstado(destino),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: Size.zero,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: cargandoEsta
                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.8, color: Colors.white))
                : const Icon(Icons.chevron_right, size: 15),
            label: Text(texto),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Text(hora(ronda.creadoEn), style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: estado.fondo, borderRadius: BorderRadius.circular(20)),
              child: Text(estado.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: estado.texto)),
            ),
          ]),
          if (ronda.nota != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text('Nota: ${ronda.nota}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
            ),
          if (ronda.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final it in ronda.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${it.cantidad}× ${it.nombre}', style: const TextStyle(fontSize: 12, color: AppColors.kTextSecondary)),
                          if (it.detalle != null) Text(it.detalle!, style: const TextStyle(fontSize: 10, color: AppColors.kTextMuted)),
                          if (it.nota != null)
                            Text('Nota: ${it.nota}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                        ],
                      ),
                    ),
                    if (it.precioUnit > 0)
                      Text(precio(it.precioUnit * it.cantidad), style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
                  ],
                ),
              ),
          ],
          if (ronda.total > 0) ...[
            const Divider(height: 16, color: Color(0xFFF1F5F9)),
            Row(children: [
              const Expanded(child: Text('Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kTextSecondary))),
              Text(precio(ronda.total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
            ]),
          ],
          if (ronda.activa) ...[
            const SizedBox(height: 10),
            Row(children: [
              if (ronda.estado == 'pendiente') avanzar('en_proceso', 'En preparación', AppColors.kBlue),
              if (ronda.estado == 'en_proceso') avanzar('entregado', 'Entregado', AppColors.kBlue),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: ocupada ? null : onCancelar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.kTextSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancelar'),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}
