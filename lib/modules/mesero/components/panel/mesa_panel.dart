import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../context/notificacion_context.dart';
import '../../../../shared/app_colors.dart';
import '../../../../shared/confirmar_dialog.dart';
import '../../../orders/components/comun/estados_lista.dart';
import '../../../orders/components/comun/hoja_formulario.dart';
import '../../../orders/hooks/eventos_pedidos.dart';
import '../../../orders/models/cuenta_mesa.dart';
import '../../../orders/utils/formato.dart';
import '../../hooks/acciones_mesero.dart';
import '../../hooks/use_cuentas_de_mesa.dart';
import '../../models/mesa_mesero.dart';
import '../../utils/tomar_orden.dart';
import 'abono_sheet.dart';
import 'agregar_opcion_sheet.dart';
import 'cabecera_cuenta.dart';
import 'ronda_card.dart';

/// La mesa elegida: sus cuentas, las rondas de la cuenta abierta y las acciones del mesero (equivale a
/// MesaPedidosPanel.jsx). Se crea uno por mesa (key), así nunca muestra las cuentas de otra.
class MesaPanel extends StatefulWidget {
  const MesaPanel({super.key, required this.menu, required this.slug, required this.mesa, required this.onMesaLibre});

  final String menu;
  final String? slug;
  final MesaMesero mesa;
  final VoidCallback onMesaLibre;

  @override
  State<MesaPanel> createState() => _MesaPanelState();
}

class _MesaPanelState extends State<MesaPanel> {
  late final _cuentas = UseCuentasDeMesa(widget.menu, widget.mesa.codigo);
  late final _acciones = AccionesMesero(widget.menu, widget.mesa.codigo);
  late final EventosPedidos _eventos;

  @override
  void initState() {
    super.initState();
    // otro mesero o el admin cambió algo de esta mesa (nueva ronda, ítem agregado, cambio de estado)
    _eventos = EventosPedidos(context.read<NotificacionContext>(), widget.menu, () => _cuentas.recargar(silencioso: true));
    _cuentas.recargar();
  }

  @override
  void dispose() {
    _eventos.cerrar();
    _cuentas.dispose();
    _acciones.dispose();
    super.dispose();
  }

  void _avisar(ResultadoAccion r) {
    if (!mounted) return;
    if (r.titulo.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.detalle.isEmpty ? r.titulo : '${r.titulo} · ${r.detalle}'),
        backgroundColor: r.ok ? null : AppColors.kRed,
      ));
    }
    if (r.ok) {
      _cuentas.recargar(silencioso: true);
      if (r.mesaLibre) widget.onMesaLibre();
    }
  }

  Future<void> _cancelarRonda(RondaCuenta ronda) async {
    const c = Confirmacion('¿Cancelar esta ronda?', 'La ronda no se preparará ni se cobrará.', 'Sí, cancelar', peligro: true);
    if (!await confirmar(context, c, cancelar: 'No, volver')) return;
    _avisar(await _acciones.cambiarEstadoRonda(ronda.codigo, 'cancelado'));
  }

  Future<void> _cancelarCuenta(CuentaMesa cuenta) async {
    const c = Confirmacion('¿Cancelar esta cuenta?', 'Esta acción no se puede deshacer.', 'Sí, cancelar', peligro: true);
    if (!await confirmar(context, c, cancelar: 'No, volver')) return;
    _avisar(await _acciones.cancelar(cuenta.codigo));
  }

  Future<void> _abonar(CuentaMesa cuenta) async {
    if (await mostrarHoja(context, AbonoSheet(menu: widget.menu, mesa: widget.mesa.codigo, cuenta: cuenta))) {
      _avisar((ok: true, titulo: 'Abono registrado', detalle: '', mesaLibre: false));
    }
  }

  /// Tomar la orden = abrir el mismo menú público en modo mesero; al volver se recargan las cuentas.
  Future<void> _agregar(CuentaMesa? activa) async {
    final slug = widget.slug;
    if (slug == null || slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el menú. Recarga e intenta de nuevo.')));
      return;
    }
    // con una cuenta abierta se pregunta a cuál; con la mesa libre se abre directo
    var nueva = false;
    if (activa != null) {
      final eleccion = await elegirDestinoOrden(context);
      if (eleccion == null || !mounted) return;
      nueva = eleccion;
    }
    final destino = DestinoOrden(
      mesaCodigo: widget.mesa.codigo,
      mesaNombre: widget.mesa.nombre,
      cuentaCodigo: nueva ? null : activa?.codigo,
      nuevaCuenta: nueva,
    );
    await context.push(urlTomarOrden(slug, destino));
    if (mounted) _cuentas.recargar(silencioso: true);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([_cuentas, _acciones]),
        builder: (context, _) {
          final activa = _cuentas.activa;
          final rondas = activa?.rondas ?? const <RondaCuenta>[];
          final activas = rondas.where((r) => r.activa).toList();
          final completadas = rondas.where((r) => !r.activa).toList();
          Widget tarjeta(RondaCuenta r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RondaCard(
                  ronda: r,
                  actualizando: _acciones.actualizando,
                  onCambiarEstado: (e) async => _avisar(await _acciones.cambiarEstadoRonda(r.codigo, e)),
                  onCancelar: () => _cancelarRonda(r),
                ),
              );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CabeceraCuenta(
                mesaNombre: widget.mesa.nombre,
                cuentas: _cuentas.cuentas,
                activa: activa,
                acciones: _acciones,
                onElegirCuenta: _cuentas.elegir,
                onCerrar: () async => _avisar(await _acciones.cerrar(activa!.codigo)),
                onCancelar: () => _cancelarCuenta(activa!),
                onAbonar: () => _abonar(activa!),
                onAgregar: () => _agregar(activa),
              ),
              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _cuentas.recargar(silencioso: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (_cuentas.error != null) ErrorLista(_cuentas.error!),
                      if (activa != null && rondas.isNotEmpty) ...[
                        _ResumenCuenta(cuenta: activa),
                        const SizedBox(height: 10),
                      ],
                      if (_cuentas.cargando)
                        const CargandoLista()
                      else if (rondas.isEmpty)
                        const ListaVacia(icono: Icons.assignment_outlined, texto: 'Sin rondas activas')
                      else ...[
                        ...activas.map(tarjeta),
                        if (completadas.isNotEmpty && activas.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8, top: 2),
                            child: Text('COMPLETADAS',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: AppColors.kTextMuted)),
                          ),
                        ...completadas.map(tarjeta),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class _ResumenCuenta extends StatelessWidget {
  const _ResumenCuenta({required this.cuenta});

  final CuentaMesa cuenta;

  @override
  Widget build(BuildContext context) {
    Widget dato(String titulo, num valor, Color color) => Expanded(
          child: Column(children: [
            Text(titulo, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(precio(valor), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ),
          ]),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        dato('Total', cuenta.total, Colors.white),
        dato('Pagado', cuenta.totalPagado, const Color(0xFFA5B4FC)), // indigo-300 (como React: text-indigo-300)
        dato('Saldo', cuenta.saldoPendiente, const Color(0xFFFCD34D)),
      ]),
    );
  }
}
