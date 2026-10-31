import 'package:flutter/material.dart';

import '../../../../shared/app_colors.dart';
import '../../../../shared/confirmar_dialog.dart';
import '../../hooks/use_pedidos_negocio.dart';
import '../../utils/estado_pedido.dart';
import '../../utils/formato.dart';
import '../comun/estados_lista.dart';
import '../comun/filtro_fechas.dart';
import 'pedido_tile.dart';

/// Pestaña "Pedidos": nota, rango, métricas del rango y la lista de pedidos de clientes (equivale a VistaPedidos.jsx).
class VistaPedidos extends StatelessWidget {
  const VistaPedidos({super.key, required this.pedidos, required this.filtro});

  final UsePedidosNegocio pedidos;
  final FiltroFechas filtro;

  Future<void> _cambiar(BuildContext context, String codigo, String estado) async {
    final c = confirmacionEstado[estado];
    if (c == null || !await confirmar(context, c, cancelar: 'No, volver')) return;
    await pedidos.cambiarEstado(codigo, estado);
  }

  @override
  Widget build(BuildContext context) {
    final p = pedidos;
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _NotaPagos(),
          const SizedBox(height: 12),
          filtro,
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Metrica(icono: Icons.receipt_long_outlined, titulo: 'Pedidos', valor: '${p.metricas.cantidad}', pie: 'en el período')),
              const SizedBox(width: 8),
              // totalEntregado es la suma del total de los pedidos entregados (no del valor pagado registrado)
              Expanded(
                child: _Metrica(
                  icono: Icons.check_circle_outline,
                  titulo: 'Entregado',
                  valor: precio(p.metricas.totalEntregado),
                  pie: 'total de pedidos entregados',
                  destacada: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _Metrica(icono: Icons.cancel_outlined, titulo: 'Cancelados', valor: '${p.metricas.cancelados}', pie: 'pedidos cancelados')),
            ],
          ),
          const SizedBox(height: 16),
          if (p.error != null) ErrorLista(p.error!),
          // los refrescos en vivo son silenciosos: el spinner solo aparece al buscar
          if (p.cargando)
            const CargandoLista()
          else if (p.items.isEmpty && p.error == null)
            const ListaVacia(icono: Icons.assignment_outlined, texto: 'Sin pedidos en este rango de fechas')
          else if (p.items.isNotEmpty)
            TarjetaLista(children: [
              for (var i = 0; i < p.items.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                PedidoTile(
                  key: ValueKey(p.items[i].codigo),
                  pedido: p.items[i],
                  actualizando: p.actualizando?.codigo == p.items[i].codigo ? p.actualizando!.estado : null,
                  repartidores: p.repartidores,
                  onCambiarEstado: (estado) => _cambiar(context, p.items[i].codigo, estado),
                  onValorPagado: (v) => p.valorPagadoGuardado(p.items[i].codigo, v),
                  onAsignarRepartidor: (r) => p.asignarRepartidor(p.items[i].codigo, r),
                ),
              ],
              CargarMasBoton(hayMas: p.hayMas, cargando: p.cargandoMas, onPressed: p.cargarMas),
            ]),
        ],
      ),
    );
  }
}

class _NotaPagos extends StatelessWidget {
  const _NotaPagos();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E7FF)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 14, color: AppColors.kBlueLight),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Zammpy no gestiona pagos. El cobro queda entre el restaurante y el cliente.',
                style: TextStyle(fontSize: 12, color: AppColors.kBlueDark),
              ),
            ),
          ],
        ),
      );
}

class _Metrica extends StatelessWidget {
  const _Metrica({required this.icono, required this.titulo, required this.valor, required this.pie, this.destacada = false});

  final IconData icono;
  final String titulo;
  final String valor;
  final String pie;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final suave = destacada ? const Color(0xFFC7D2FE) : AppColors.kTextMuted;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: destacada ? AppColors.kBlue : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: destacada ? AppColors.kBlueLight : AppColors.kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icono, size: 13, color: suave),
            const SizedBox(width: 4),
            Flexible(
              child: Text(titulo.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: suave)),
            ),
          ]),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: destacada ? Colors.white : AppColors.kTextPrimary)),
          ),
          const SizedBox(height: 2),
          Text(pie, maxLines: 2, style: TextStyle(fontSize: 10, color: suave)),
        ],
      ),
    );
  }
}
