import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../components/layout/sidebar.dart';
import '../../../../context/notificacion_context.dart';
import '../../../../services/mis_menus_service.dart';
import '../../../../shared/app_colors.dart';
import '../../../../shared/app_header.dart';
import '../../../../shared/confirmar_dialog.dart';
import '../../../../shared/responsive.dart';
import '../../../orders/components/comun/estados_lista.dart';
import '../../../orders/hooks/eventos_pedidos.dart';
import '../../../orders/hooks/pagina_cursor.dart' show mensaje;
import '../live/editor_tabs_bar.dart';
import 'mesa_form_sheet.dart';
import 'mesa_model.dart';
import 'mesa_tile.dart';
import 'use_mesas.dart';

// Equivalente a MesasPage.jsx: CRUD de las mesas del menú, activar/desactivar y refresco en vivo (otro admin o un
// mesero crea/edita una mesa o abre/cierra una cuenta).

/// Texto de la confirmación; activar no es destructivo, así que no va en rojo.
Confirmacion _confirmacion(Mesa mesa, {required bool eliminar}) {
  if (eliminar) {
    return Confirmacion('¿Eliminar mesa?', '"${mesa.nombre}" se eliminará permanentemente.', 'Eliminar', peligro: true);
  }
  return mesa.activo
      ? const Confirmacion('¿Desactivar mesa?', 'La mesa dejará de aparecer en la vista del mesero.', 'Desactivar', peligro: true)
      : const Confirmacion('¿Activar mesa?', 'La mesa volverá a aparecer en la vista del mesero.', 'Activar');
}

class MesasPage extends StatefulWidget {
  const MesasPage({super.key, required this.codigo});

  final String codigo;

  @override
  State<MesasPage> createState() => _MesasPageState();
}

class _MesasPageState extends State<MesasPage> {
  late final _mesas = UseMesas(widget.codigo);
  late final EventosPedidos _eventos;
  String? _nombre;
  String? _slug;

  @override
  void initState() {
    super.initState();
    _eventos = EventosPedidos(context.read<NotificacionContext>(), widget.codigo, () => _mesas.cargar(silencioso: true));
    _mesas.cargar();
    _cargarMenu();
  }

  Future<void> _cargarMenu() async {
    try {
      final menu = await MisMenusService.getResumen(widget.codigo);
      if (!mounted) return;
      setState(() {
        _nombre = menu.nombre;
        _slug = menu.slug;
      });
    } catch (_) {
      // el título queda genérico si falla
    }
  }

  @override
  void dispose() {
    _eventos.cerrar();
    _mesas.dispose();
    super.dispose();
  }

  Future<void> _formulario([Mesa? mesa]) async {
    final guardada = await showModalBottomSheet<Mesa>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: hojaConstraints(context),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: MesaFormSheet(menu: widget.codigo, mesa: mesa),
      ),
    );
    if (guardada != null) _mesas.guardada(guardada);
  }

  Future<void> _accion(Mesa mesa, {required bool eliminar}) async {
    if (!await confirmar(context, _confirmacion(mesa, eliminar: eliminar))) return;
    try {
      await (eliminar ? _mesas.eliminar(mesa) : _mesas.alternarActivo(mesa));
      _mesas.mostrarError(null);
    } catch (e) {
      _mesas.mostrarError(mensaje(e, eliminar ? 'No se pudo eliminar' : 'No se pudo actualizar'));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.kBgPage,
        drawer: const AppSidebar(),
        // Mismo header que el editor (nombre + /slug): el layout no cambia al pasar entre pestañas
        appBar: AppHeader(
          title: (_nombre != null && _nombre!.isNotEmpty) ? _nombre! : 'Mesas',
          subtitle: (_slug != null && _slug!.isNotEmpty) ? '/$_slug' : null,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _formulario(),
          backgroundColor: AppColors.kBlue,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nueva mesa', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: Column(children: [
          EditorTabsBar(codigo: widget.codigo, active: 'mesas'),
          Expanded(child: ListenableBuilder(
          listenable: _mesas,
          builder: (context, _) => RefreshIndicator(
            color: AppColors.kBlue,
            onRefresh: () => _mesas.cargar(silencioso: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: contenidoPadding(context, maxWidth: 900, bottom: 96),
              children: [
                if (_mesas.error != null) ErrorLista(_mesas.error!),
                if (_mesas.cargando)
                  const CargandoLista()
                else if (_mesas.mesas.isEmpty)
                  const ListaVacia(
                    icono: Icons.table_restaurant_outlined,
                    texto: 'No hay mesas configuradas\nCrea tu primera mesa para que los meseros puedan tomar pedidos.',
                  )
                else
                  TarjetaLista(children: [
                    if (esTablet(context)) const MesasEncabezado(),
                    for (var i = 0; i < _mesas.mesas.length; i++) ...[
                      if (i > 0 || esTablet(context)) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      MesaTile(
                        key: ValueKey(_mesas.mesas[i].codigo),
                        mesa: _mesas.mesas[i],
                        onEditar: () => _formulario(_mesas.mesas[i]),
                        onAlternar: () => _accion(_mesas.mesas[i], eliminar: false),
                        onEliminar: () => _accion(_mesas.mesas[i], eliminar: true),
                      ),
                    ],
                  ]),
              ],
            ),
          ),
        ),
        ),
        ]),
      );
}
