import 'package:flutter/material.dart';

import '../../../../shared/app_colors.dart';
import '../../utils/formato.dart';

/// Rango de fechas (yyyy-MM-dd) y "Buscar" (equivale a FiltroFechas.jsx). Elegir una fecha no busca sola: se busca
/// con el botón, igual que en la web.
class FiltroFechas extends StatelessWidget {
  const FiltroFechas({
    super.key,
    required this.desde,
    required this.hasta,
    required this.onDesde,
    required this.onHasta,
    required this.onBuscar,
    this.cargando = false,
  });

  final String desde;
  final String hasta;
  final ValueChanged<String> onDesde;
  final ValueChanged<String> onHasta;
  final VoidCallback onBuscar;
  final bool cargando;

  Future<void> _elegir(BuildContext context, {required bool esDesde}) async {
    final hoy = DateTime.parse(bogotaHoy());
    final d = DateTime.tryParse(desde) ?? hoy;
    final h = DateTime.tryParse(hasta) ?? hoy;
    final elegido = await showDatePicker(
      context: context,
      initialDate: esDesde ? d : h,
      firstDate: esDesde ? DateTime(2020) : d,
      lastDate: esDesde ? h : hoy,
      helpText: esDesde ? 'Desde' : 'Hasta',
    );
    if (elegido == null) return;
    (esDesde ? onDesde : onHasta)(fechaIso(elegido));
  }

  @override
  Widget build(BuildContext context) {
    Widget campo(String etiqueta, String valor, bool esDesde) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _elegir(context, esDesde: esDesde),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.kCardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta, style: const TextStyle(fontSize: 10, color: AppColors.kTextMuted)),
                  Text(
                    fechaCorta(valor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.kTextPrimary),
                  ),
                ],
              ),
            ),
          ),
        );

    return Row(
      children: [
        campo('Desde', desde, true),
        const SizedBox(width: 8),
        campo('Hasta', hasta, false),
        const SizedBox(width: 8),
        SizedBox(
          height: 46,
          child: FilledButton(
            onPressed: cargando ? null : onBuscar,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.kBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: cargando
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Buscar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
