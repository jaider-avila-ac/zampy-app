import 'package:flutter/material.dart';

import '../../../shared/app_colors.dart';
import '../models/mesa_mesero.dart';

/// Una mesa en la cuadrícula del mesero: libre, con órdenes activas, dividida o bloqueada por otro mesero.
class MesaCard extends StatelessWidget {
  const MesaCard({super.key, required this.mesa, required this.seleccionada, required this.onTap});

  final MesaMesero mesa;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bloqueada = mesa.abiertaPorOtro;
    final activos = mesa.pedidosActivos > 0;
    final borde = bloqueada
        ? const Color(0xFFF1F5F9)
        : seleccionada
            ? AppColors.kBlueLight
            : activos
                ? const Color(0xFFC7D2FE)
                : AppColors.kCardBorder;

    final tarjeta = Material(
      color: !bloqueada && seleccionada ? const Color(0xFFEEF2FF) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: borde, width: 2)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: bloqueada ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(children: [
                      Flexible(
                        child: Text(mesa.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.kTextPrimary)),
                      ),
                      if (mesa.dividida) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.call_split, size: 14, color: Color(0xFFF59E0B)),
                      ],
                    ]),
                  ),
                  if (activos && !bloqueada)
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.kBlue, shape: BoxShape.circle),
                      child: Text('${mesa.pedidosActivos}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(children: [
                if (mesa.capacidad != null) ...[
                  const Icon(Icons.people_outline, size: 13, color: AppColors.kTextMuted),
                  const SizedBox(width: 3),
                  Text('${mesa.capacidad}', style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
                ],
                const Spacer(),
                Flexible(
                  child: bloqueada
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.lock_outline, size: 12, color: AppColors.kTextMuted),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(mesa.atendidaPor ?? 'Ocupada',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.kTextMuted)),
                          ),
                        ])
                      : Text(
                          activos ? '${mesa.pedidosActivos} orden${mesa.pedidosActivos > 1 ? 'es' : ''}' : 'Libre',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: activos ? AppColors.kBlue : AppColors.kTextMuted),
                        ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    return Opacity(
      opacity: bloqueada ? 0.6 : 1,
      child: bloqueada ? Tooltip(message: 'Ocupada por ${mesa.atendidaPor ?? 'otro mesero'}', child: tarjeta) : tarjeta,
    );
  }
}
