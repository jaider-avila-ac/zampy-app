import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/app_colors.dart';
import '../../mesero/utils/estado_ronda.dart';
import '../../orders/utils/formato.dart';
import '../models/pedido_repartidor.dart';

/// Un pedido para el repartidor: si está disponible, lo toma; si ya es suyo, ve los datos de entrega (con el teléfono
/// para llamar) y lo pasa a preparación, lo marca entregado o lo cancela.
class PedidoRepartidorCard extends StatelessWidget {
  const PedidoRepartidorCard({
    super.key,
    required this.item,
    required this.actualizando,
    required this.onTomar,
    required this.onCambiarEstado,
    required this.onCancelar,
  });

  final PedidoRepartidor item;
  final String? actualizando;
  final VoidCallback onTomar;
  final ValueChanged<String> onCambiarEstado;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final p = item.pedido;
    final estado = estadoRonda(p.estado);
    final ocupado = actualizando != null;
    final cargando = actualizando == p.codigo;
    const spinner = SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 1.8, color: Colors.white));
    final boton = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      minimumSize: Size.zero,
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.clienteNombre ?? 'Pedido disponible',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.kTextPrimary)),
                if (p.direccion != null)
                  Text(p.direccion!, style: const TextStyle(fontSize: 12, color: AppColors.kTextSecondary)),
                if (p.direccionReferencia != null)
                  Text(p.direccionReferencia!, style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
                if (p.clienteTelefono != null)
                  InkWell(
                    onTap: () => launchUrl(Uri(scheme: 'tel', path: p.clienteTelefono)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.phone_outlined, size: 13, color: AppColors.kBlue),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(p.clienteTelefono!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kBlue)),
                        ),
                      ]),
                    ),
                  ),
                if (item.disponible)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Toma el pedido para ver los datos de entrega.',
                        style: TextStyle(fontSize: 11, color: Color(0xFFD97706))),
                  ),
              ]),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: estado.fondo, borderRadius: BorderRadius.circular(20)),
              child: Text(estado.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: estado.texto)),
            ),
          ]),
          const SizedBox(height: 10),
          for (final it in p.items.take(3))
            Text('${it.cantidad}× ${it.nombre}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.kTextSecondary)),
          if (p.items.length > 3)
            Text('+${p.items.length - 3} más', style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text(precio(p.total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
            Text('#${p.codigo}', style: const TextStyle(fontSize: 10, color: AppColors.kTextMuted)),
          ]),
          if (item.activo) ...[
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            if (item.disponible)
              FilledButton.icon(
                onPressed: ocupado ? null : onTomar,
                style: boton.copyWith(backgroundColor: const WidgetStatePropertyAll(AppColors.kBlue)),
                icon: cargando ? spinner : const Icon(Icons.local_shipping_outlined, size: 15),
                label: const Text('Tomar pedido'),
              )
            else
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: ocupado ? null : () => onCambiarEstado(p.estado == 'pendiente' ? 'en_proceso' : 'entregado'),
                    style: boton.copyWith(backgroundColor: const WidgetStatePropertyAll(AppColors.kTextPrimary)),
                    icon: cargando ? spinner : const Icon(Icons.check_circle_outline, size: 15),
                    label: Text(p.estado == 'pendiente' ? 'Poner en preparación' : 'Entregado'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: ocupado ? null : onCancelar,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kTextSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    minimumSize: Size.zero,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 15),
                  label: const Text('Cancelar'),
                ),
              ]),
          ],
        ],
      ),
    );
  }
}
