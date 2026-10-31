import 'package:flutter/material.dart';

import '../../../../shared/app_colors.dart';
import '../../../../shared/responsive.dart';
import 'mesa_model.dart';

/// Una mesa en la lista: fila con columnas en tablet y tarjeta compacta en el teléfono.
class MesaTile extends StatelessWidget {
  const MesaTile({super.key, required this.mesa, required this.onEditar, required this.onAlternar, required this.onEliminar});

  final Mesa mesa;
  final VoidCallback onEditar;
  final VoidCallback onAlternar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final estado = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: mesa.activo ? const Color(0xFFE0E7FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(mesa.activo ? 'Activa' : 'Inactiva',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: mesa.activo ? AppColors.kBlueDark : AppColors.kTextMuted)),
    );
    final acciones = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Editar',
          onPressed: onEditar,
          icon: const Icon(Icons.edit_outlined, size: 18),
          color: AppColors.kTextMuted,
        ),
        IconButton(
          tooltip: mesa.activo ? 'Desactivar' : 'Activar',
          onPressed: onAlternar,
          icon: Icon(mesa.activo ? Icons.toggle_on : Icons.toggle_off_outlined, size: 24),
          color: mesa.activo ? AppColors.kBlue : AppColors.kTextMuted,
        ),
        IconButton(
          tooltip: mesa.ocupada ? 'Tiene pedidos activos' : 'Eliminar',
          onPressed: mesa.ocupada ? null : onEliminar,
          icon: const Icon(Icons.delete_outline, size: 18),
          color: AppColors.kTextMuted,
        ),
      ],
    );
    final activos = Text('${mesa.pedidosActivos}',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: mesa.ocupada ? AppColors.kBlue : AppColors.kTextMuted));
    final nombre = Text(mesa.nombre,
        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
      child: esTablet(context)
          ? Row(children: [
              Expanded(child: nombre),
              SizedBox(
                  width: 90,
                  child: Text(mesa.capacidad?.toString() ?? '—',
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.kTextSecondary))),
              SizedBox(width: 100, child: Center(child: estado)),
              SizedBox(width: 120, child: activos),
              acciones,
            ])
          : Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    nombre,
                    const SizedBox(height: 4),
                    Row(children: [
                      estado,
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${mesa.capacidad == null ? '' : '${mesa.capacidad} pers. · '}${mesa.pedidosActivos} activos',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.kTextSecondary),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              acciones,
            ]),
    );
  }
}

/// Encabezado de columnas (solo tablet).
class MesasEncabezado extends StatelessWidget {
  const MesasEncabezado({super.key});

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: AppColors.kTextSecondary);
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: const Row(children: [
        Expanded(child: Text('NOMBRE', style: estilo)),
        SizedBox(width: 90, child: Text('CAPACIDAD', textAlign: TextAlign.center, style: estilo)),
        SizedBox(width: 100, child: Text('ESTADO', textAlign: TextAlign.center, style: estilo)),
        SizedBox(width: 120, child: Text('PEDIDOS ACTIVOS', textAlign: TextAlign.center, style: estilo)),
        SizedBox(width: 132, child: Text('ACCIONES', textAlign: TextAlign.right, style: estilo)),
      ]),
    );
  }
}
