import 'package:flutter/material.dart';

import '../../../../shared/app_colors.dart';
import '../../models/pedido_negocio.dart';
import '../../utils/formato.dart';

/// El detalle de un pedido al desplegarlo: ítems con sus opciones, dirección de entrega y repartidor asignado.
class DetallePedido extends StatelessWidget {
  const DetallePedido({super.key, required this.pedido, required this.repartidores, required this.onAsignarRepartidor});

  final PedidoNegocio pedido;
  final List<Repartidor> repartidores;
  final ValueChanged<String> onAsignarRepartidor;

  static const _muted = TextStyle(fontSize: 12, color: AppColors.kTextSecondary);

  Widget _opcion(String etiqueta, String valor) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: '$etiqueta: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: valor),
          ]),
          style: _muted,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final asignable = pedido.asignable && repartidores.isNotEmpty;
    final actual = repartidores.any((r) => r.codigo == pedido.repartidorCodigo) ? pedido.repartidorCodigo : null;

    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in pedido.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(item.nombre,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.kTextPrimary)),
                      ),
                      Text('×${item.cantidad}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.kBlue)),
                      const SizedBox(width: 8),
                      Text(precio(item.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  if (item.tamano != null) _opcion('Tamaño', item.tamano!),
                  for (final p in item.personalizacion) _opcion('Personalización', p),
                  for (final a in item.adiciones) _opcion('Adición', a),
                  for (final (grupo, opciones) in item.grupos) _opcion(grupo, opciones),
                  if (item.nota != null) _opcion('Nota', item.nota!),
                ],
              ),
            ),
          if (pedido.direccion != null) ...[
            const Divider(height: 12),
            _opcion('Dirección',
                pedido.direccionReferencia == null ? pedido.direccion! : '${pedido.direccion} — ${pedido.direccionReferencia}'),
          ],
          if (asignable) ...[
            const Divider(height: 16),
            Row(
              children: [
                const Text('Repartidor:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kTextSecondary)),
                const SizedBox(width: 8),
                Flexible(
                  child: DropdownButton<String>(
                    value: actual,
                    isDense: true,
                    isExpanded: true,
                    hint: const Text('Sin asignar', style: TextStyle(fontSize: 13)),
                    style: const TextStyle(fontSize: 13, color: AppColors.kTextPrimary),
                    items: [
                      for (final r in repartidores) DropdownMenuItem(value: r.codigo, child: Text(r.nombre, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (codigo) {
                      if (codigo != null && codigo != actual) onAsignarRepartidor(codigo);
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
