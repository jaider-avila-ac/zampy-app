import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../components/layout/sidebar.dart';
import '../../../context/notificacion_context.dart';
import '../../../services/mis_menus_service.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/app_header.dart';
import '../../../shared/responsive.dart';
import '../components/comun/filtro_fechas.dart';
import '../components/comun/resumen_ventas_card.dart';
import '../components/cuentas/vista_cuentas.dart';
import '../components/pedidos/vista_pedidos.dart';
import '../hooks/catalogo_menu.dart';
import '../hooks/eventos_pedidos.dart';
import '../hooks/use_cuentas.dart';
import '../hooks/use_pedidos_negocio.dart';
import '../hooks/use_resumen_ventas.dart';
import '../utils/formato.dart';

// Equivalente a MenuPedidosPage.jsx: venta total del rango y tres pestañas (pedidos de clientes, mesas en curso y
// cuentas cerradas). Cada pestaña tiene su propio estado; la página solo comparte el rango de fechas y recarga la
// pestaña visible cuando llega un evento de pedidos de este menú. Solo para el dueño o un editor.

enum _Vista { pedidos, enCurso, cuentas }

const _etiquetas = {_Vista.pedidos: 'Pedidos', _Vista.enCurso: 'En curso', _Vista.cuentas: 'Cuentas'};

class MenuPedidosPage extends StatefulWidget {
  const MenuPedidosPage({super.key, required this.codigo});

  final String codigo;

  @override
  State<MenuPedidosPage> createState() => _MenuPedidosPageState();
}

class _MenuPedidosPageState extends State<MenuPedidosPage> {
  late final _resumen = UseResumenVentas(widget.codigo);
  late final _pedidos = UsePedidosNegocio(widget.codigo);
  late final _cerradas = UseCuentasCerradas(widget.codigo);
  late final _enCurso = UseCuentasEnCurso(widget.codigo);
  late final _catalogo = CatalogoMenu(widget.codigo);
  late final EventosPedidos _eventos;

  _Vista _vista = _Vista.pedidos;
  String _desde = bogotaHoy();
  String _hasta = bogotaHoy();
  String? _nombre;
  bool _sinPermiso = false;

  @override
  void initState() {
    super.initState();
    _eventos = EventosPedidos(context.read<NotificacionContext>(), widget.codigo, () => _recargar(silencioso: true));
    _cargarMenu();
    _recargar();
  }

  @override
  void dispose() {
    _eventos.cerrar();
    for (final n in [_resumen, _pedidos, _cerradas, _enCurso]) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarMenu() async {
    try {
      final menu = await MisMenusService.getResumen(widget.codigo);
      if (!mounted) return;
      setState(() {
        _nombre = menu.nombre;
        _sinPermiso = !menu.puedeGestionar;
      });
    } catch (_) {
      // el título queda genérico; los errores de acceso los muestra cada pestaña
    }
  }

  /// La pestaña visible con el rango actual (y la venta total del rango).
  Future<void> _recargar({bool silencioso = false}) {
    if (_vista == _Vista.enCurso) return _enCurso.recargar(silencioso: silencioso);
    _resumen.cargar(_desde, _hasta);
    return _vista == _Vista.cuentas
        ? _cerradas.cargar(_desde, _hasta, silencioso: silencioso)
        : _pedidos.cargar(_desde, _hasta, silencioso: silencioso);
  }

  void _cambiarVista(_Vista v) {
    if (v == _vista) return;
    setState(() => _vista = v);
    _recargar();
  }

  FiltroFechas _filtro(bool cargando) => FiltroFechas(
        desde: _desde,
        hasta: _hasta,
        onDesde: (v) => setState(() => _desde = v),
        onHasta: (v) => setState(() => _hasta = v),
        onBuscar: _recargar,
        cargando: cargando,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgPage,
      drawer: const AppSidebar(),
      appBar: AppHeader(title: 'Pedidos', subtitle: _nombre),
      body: _sinPermiso
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Solo el dueño o un editor del menú pueden ver sus pedidos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.kTextSecondary),
                ),
              ),
            )
          : RefreshIndicator(
              color: AppColors.kBlue,
              onRefresh: _recargar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: contenidoPadding(context, maxWidth: 1100, bottom: 40),
                children: [
                  ListenableBuilder(
                    listenable: _resumen,
                    builder: (_, _) => ResumenVentasCard(resumen: _resumen.resumen, cargando: _resumen.cargando),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final v in _Vista.values)
                        ChoiceChip(
                          label: Text(_etiquetas[v]!),
                          selected: v == _vista,
                          showCheckmark: false,
                          onSelected: (_) => _cambiarVista(v),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: v == _vista ? Colors.white : AppColors.kTextSecondary,
                          ),
                          selectedColor: AppColors.kBlue,
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  switch (_vista) {
                    _Vista.pedidos => ListenableBuilder(
                        listenable: _pedidos,
                        builder: (_, _) => VistaPedidos(pedidos: _pedidos, filtro: _filtro(_pedidos.cargando)),
                      ),
                    _Vista.enCurso => VistaCuentas(cuentas: _enCurso, menu: widget.codigo, catalogo: _catalogo),
                    _Vista.cuentas => ListenableBuilder(
                        listenable: _cerradas,
                        builder: (_, _) => VistaCuentas(
                          cuentas: _cerradas,
                          menu: widget.codigo,
                          catalogo: _catalogo,
                          filtro: _filtro(_cerradas.cargando),
                        ),
                      ),
                  },
                ],
              ),
            ),
    );
  }
}
