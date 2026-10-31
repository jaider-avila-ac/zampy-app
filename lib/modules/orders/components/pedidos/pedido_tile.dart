import 'package:flutter/material.dart';

import '../../../../shared/app_colors.dart';
import '../../../../shared/responsive.dart';
import '../../models/pedido_negocio.dart';
import '../../utils/estado_pedido.dart';
import '../../utils/formato.dart';
import 'acciones_pedido.dart';
import 'detalle_pedido.dart';
import 'valor_pagado.dart';

/// Un pedido en la lista del negocio: tarjeta en el teléfono y fila de tabla en tablet; al tocarlo se despliega el
/// detalle.
class PedidoTile extends StatefulWidget {
  const PedidoTile({
    super.key,
    required this.pedido,
    required this.actualizando,
    required this.repartidores,
    required this.onCambiarEstado,
    required this.onValorPagado,
    required this.onAsignarRepartidor,
  });

  final PedidoNegocio pedido;
  final String? actualizando; // estado al que se está cambiando este pedido
  final List<Repartidor> repartidores;
  final ValueChanged<String> onCambiarEstado;
  final ValueChanged<num> onValorPagado;
  final ValueChanged<String> onAsignarRepartidor;

  @override
  State<PedidoTile> createState() => _PedidoTileState();
}

class _PedidoTileState extends State<PedidoTile> {
  bool _abierto = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;
    final estado = estadoPedido(p.estado);
    final resumen = p.items.isEmpty
        ? null
        : '${resumenItems(p.items)}${p.items.length > 2 ? ' +${p.items.length - 2} más' : ''}';

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: estado.fondo, borderRadius: BorderRadius.circular(20)),
      child: Text(estado.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: estado.texto)),
    );
    final barra = Container(
      width: 4,
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(color: estado.barra, borderRadius: BorderRadius.circular(4)),
    );
    final cliente = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(p.clienteNombre ?? 'Cliente',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.kTextPrimary)),
        if (p.clienteTelefono != null) _linea(p.clienteTelefono!),
        if (p.repartidorNombre != null) _linea('Repartidor: ${p.repartidorNombre}'),
        if (resumen != null) _linea(resumen),
      ],
    );
    final acciones = p.tieneAcciones
        ? AccionesPedido(estado: p.estado, actualizando: widget.actualizando, onCambiar: widget.onCambiarEstado)
        : p.estado == 'entregado'
            ? ValorPagado(codigo: p.codigo, valorActual: p.valorPagado, onGuardado: widget.onValorPagado)
            : null;
    final chevron = Icon(_abierto ? Icons.expand_more : Icons.chevron_right, size: 18, color: AppColors.kTextMuted);
    final total = Text(precio(p.total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900));

    final cabecera = esTablet(context)
        ? Row(
            children: [
              barra,
              const SizedBox(width: 12),
              SizedBox(width: 112, child: Align(alignment: Alignment.centerLeft, child: badge)),
              SizedBox(
                width: 76,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hora(p.creadoEn), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kTextSecondary)),
                    Text('#${p.codigo}', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: AppColors.kTextMuted, fontFamily: 'monospace')),
                  ],
                ),
              ),
              Expanded(child: cliente),
              const SizedBox(width: 8),
              SizedBox(width: 96, child: Align(alignment: Alignment.centerRight, child: total)),
              const SizedBox(width: 8),
              if (acciones != null) ConstrainedBox(constraints: const BoxConstraints(maxWidth: 240), child: acciones),
              chevron,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    barra,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            badge,
                            const SizedBox(width: 8),
                            Flexible(child: _linea('${hora(p.creadoEn)} · #${p.codigo}')),
                          ]),
                          const SizedBox(height: 4),
                          cliente,
                        ],
                      ),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [total, chevron]),
                  ],
                ),
              ),
              if (acciones != null) ...[
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: acciones),
              ],
            ],
          );

    return Opacity(
      opacity: p.estado == 'cancelado' ? 0.5 : 1,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _abierto = !_abierto),
            child: Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 12), child: cabecera),
          ),
          if (_abierto && p.items.isNotEmpty)
            DetallePedido(pedido: p, repartidores: widget.repartidores, onAsignarRepartidor: widget.onAsignarRepartidor),
        ],
      ),
    );
  }

  Widget _linea(String texto) => Text(texto,
      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted));
}
