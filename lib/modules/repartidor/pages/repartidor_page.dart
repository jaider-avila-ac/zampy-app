import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../context/notificacion_context.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/app_header.dart';
import '../../../shared/confirmar_dialog.dart';
import '../../../shared/responsive.dart';
import '../../orders/components/comun/estados_lista.dart';
import '../../orders/hooks/eventos_pedidos.dart';
import '../../orders/utils/estado_pedido.dart';
import '../../orders/utils/formato.dart';
import '../components/pedido_repartidor_card.dart';
import '../hooks/use_pedidos_repartidor.dart';
import '../models/pedido_repartidor.dart';

// Equivalente a RepartidorPage.jsx: los pedidos disponibles y los propios del día (por entregar / historial) con sus
// totales. Se refresca en vivo con los eventos de pedidos del menú. En tablet ancha, las tarjetas van en dos columnas.

class RepartidorPage extends StatefulWidget {
  const RepartidorPage({super.key, required this.codigo});

  final String codigo;

  @override
  State<RepartidorPage> createState() => _RepartidorPageState();
}

class _RepartidorPageState extends State<RepartidorPage> {
  late final _pedidos = UsePedidosRepartidor(widget.codigo);
  late final EventosPedidos _eventos;
  bool _historial = false;

  @override
  void initState() {
    super.initState();
    _eventos = EventosPedidos(context.read<NotificacionContext>(), widget.codigo, () => _pedidos.cargar(silencioso: true));
    _pedidos.cargar();
  }

  @override
  void dispose() {
    _eventos.cerrar();
    _pedidos.dispose();
    super.dispose();
  }

  void _avisar(String? error) {
    if (error == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.kRed));
  }

  Future<void> _cancelar(PedidoRepartidor item) async {
    if (!await confirmar(context, confirmacionEstado['cancelado']!, cancelar: 'No, volver')) return;
    _avisar(await _pedidos.cambiarEstado(item.pedido.codigo, 'cancelado'));
  }

  Widget _tarjeta(PedidoRepartidor item) => PedidoRepartidorCard(
        key: ValueKey(item.pedido.codigo),
        item: item,
        actualizando: _pedidos.actualizando,
        onTomar: () async => _avisar(await _pedidos.tomar(item.pedido.codigo)),
        onCambiarEstado: (e) async => _avisar(await _pedidos.cambiarEstado(item.pedido.codigo, e)),
        onCancelar: () => _cancelar(item),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.kBgPage,
        appBar: const AppHeader(title: 'Vista repartidor', subtitle: 'Pedidos disponibles y tus entregas de hoy'),
        body: ListenableBuilder(
          listenable: _pedidos,
          builder: (context, _) {
            final p = _pedidos;
            final lista = _historial ? p.historial : p.activos;
            return RefreshIndicator(
              onRefresh: () => p.cargar(silencioso: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: contenidoPadding(context, maxWidth: 1000),
                children: [
                  Row(children: [
                    _Metrica(valor: '${p.metricas.entregas}', titulo: 'Entregas'),
                    const SizedBox(width: 10),
                    _Metrica(valor: '${p.metricas.cancelados}', titulo: 'Cancelados', color: AppColors.kRed),
                    const SizedBox(width: 10),
                    _Metrica(valor: precio(p.metricas.cobrado), titulo: 'Cobrado', destacada: true),
                  ]),
                  const SizedBox(height: 14),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, label: Text('Por entregar (${p.activos.length})')),
                      ButtonSegment(value: true, label: Text('Historial (${p.historial.length})')),
                    ],
                    selected: {_historial},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _historial = s.first),
                  ),
                  const SizedBox(height: 14),
                  if (p.error != null) ErrorLista(p.error!),
                  if (p.cargando)
                    const CargandoLista()
                  else if (lista.isEmpty)
                    ListaVacia(
                      icono: _historial ? Icons.schedule : Icons.local_shipping_outlined,
                      texto: _historial ? 'Sin historial hoy' : 'Sin pedidos por entregar',
                    )
                  else
                    LayoutBuilder(builder: (context, c) {
                      // dos columnas cuando caben tarjetas de ~420 px (tablet ancha)
                      final columnas = c.maxWidth >= 860 ? 2 : 1;
                      final ancho = (c.maxWidth - (columnas - 1) * 12) / columnas;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [for (final item in lista) SizedBox(width: ancho, child: _tarjeta(item))],
                      );
                    }),
                  CargarMasBoton(hayMas: p.hayMas, cargando: p.cargandoMas, onPressed: p.cargarMas),
                ],
              ),
            );
          },
        ),
      );
}

class _Metrica extends StatelessWidget {
  const _Metrica({required this.valor, required this.titulo, this.destacada = false, this.color});

  final String valor;
  final String titulo;
  final bool destacada;
  final Color? color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: destacada ? AppColors.kBlue : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: destacada ? null : Border.all(color: AppColors.kCardBorder),
          ),
          child: Column(children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(valor,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900, color: destacada ? Colors.white : color ?? AppColors.kTextPrimary)),
            ),
            const SizedBox(height: 2),
            Text(titulo,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: destacada ? const Color(0xFFC7D2FE) : AppColors.kTextSecondary)),
          ]),
        ),
      );
}
