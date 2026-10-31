import 'package:flutter/material.dart';

import '../../../../shared/app_colors.dart';
import '../../hooks/catalogo_menu.dart';
import '../../hooks/use_cuentas.dart';
import '../../models/cuenta_mesa.dart';
import '../../utils/formato.dart';
import '../comun/estados_lista.dart';
import '../comun/filtro_fechas.dart';
import '../comun/hoja_formulario.dart';
import 'agregar_item_cuenta_sheet.dart';
import 'ajuste_cuenta_sheet.dart';
import 'cuenta_tile.dart';
import 'pago_cuenta_sheet.dart';

/// Pestañas "En curso" (mesas abiertas ahora) y "Cuentas" (cerradas en un rango). Cada una recibe su propio estado y
/// nunca se mezclan. Tras cualquier acción sobre una cuenta se recarga la lista sin spinner.
class VistaCuentas extends StatelessWidget {
  const VistaCuentas({
    super.key,
    required this.cuentas,
    required this.menu,
    required this.catalogo,
    this.filtro,
  });

  final CuentasVista cuentas;
  final String menu;
  final CatalogoMenu catalogo;
  final FiltroFechas? filtro; // solo las cerradas se filtran por fechas

  bool get _enCurso => cuentas is UseCuentasEnCurso;

  Future<void> _abrir(BuildContext context, Widget hoja) async {
    if (await mostrarHoja(context, hoja)) await cuentas.recargar(silencioso: true);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: cuentas,
        builder: (context, _) {
          final cerradas = cuentas is UseCuentasCerradas ? cuentas as UseCuentasCerradas : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (filtro != null) ...[filtro!, const SizedBox(height: 16)],
              if (cuentas.error != null) ErrorLista(cuentas.error!),
              if (cuentas.cargando)
                const CargandoLista()
              else ...[
                _Totales(enCurso: _enCurso, cantidad: cuentas.items.length, total: cuentas.total),
                const SizedBox(height: 16),
                if (cerradas != null && cerradas.ventasPorMesero.isNotEmpty) ...[
                  _VentasPorMesero(cerradas.ventasPorMesero),
                  const SizedBox(height: 16),
                ],
                if (cuentas.items.isEmpty)
                  ListaVacia(
                    icono: Icons.receipt_long_outlined,
                    texto: _enCurso ? 'No hay mesas abiertas ahora mismo' : 'Sin cuentas cerradas en este rango de fechas',
                  )
                else
                  TarjetaLista(children: [
                    for (var i = 0; i < cuentas.items.length; i++) ...[
                      if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      _tile(context, cuentas.items[i]),
                    ],
                    if (cerradas != null)
                      CargarMasBoton(hayMas: cerradas.hayMas, cargando: cerradas.cargandoMas, onPressed: cerradas.cargarMas),
                  ]),
              ],
            ],
          );
        },
      );

  Widget _tile(BuildContext context, CuentaMesa c) => CuentaTile(
        key: ValueKey(c.codigo),
        cuenta: c,
        enCurso: _enCurso,
        menu: menu,
        onAgregarItem: () => _abrir(context, AgregarItemCuentaSheet(menu: menu, cuenta: c, catalogo: catalogo)),
        onAjustar: () => _abrir(context, AjusteCuentaSheet(menu: menu, cuenta: c)),
        onPago: () => _abrir(context, PagoCuentaSheet(menu: menu, cuenta: c)),
        onCambiada: () => cuentas.recargar(silencioso: true),
      );
}

class _Totales extends StatelessWidget {
  const _Totales({required this.enCurso, required this.cantidad, required this.total});

  final bool enCurso;
  final int cantidad;
  final num total;

  @override
  Widget build(BuildContext context) {
    Widget tarjeta(String titulo, String valor, {bool destacada = false}) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: destacada ? AppColors.kBlue : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: destacada ? null : Border.all(color: AppColors.kCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: destacada ? const Color(0xFFC7D2FE) : AppColors.kTextMuted,
                    )),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(valor,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: destacada ? Colors.white : AppColors.kTextPrimary)),
                ),
              ],
            ),
          ),
        );
    return Row(children: [
      tarjeta(enCurso ? 'Mesas en curso' : 'Cuentas cerradas', '$cantidad'),
      const SizedBox(width: 10),
      tarjeta(enCurso ? 'Total en curso' : 'Total cobrado', precio(total), destacada: true),
    ]);
  }
}

class _VentasPorMesero extends StatelessWidget {
  const _VentasPorMesero(this.ventas);

  final List<VentaMesero> ventas;

  @override
  Widget build(BuildContext context) => TarjetaLista(children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('VENTAS POR MESERO',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: AppColors.kTextMuted)),
          ),
        ),
        for (final v in ventas) ...[
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(children: [
              Expanded(child: Text(v.nombre, style: const TextStyle(fontSize: 13, color: AppColors.kTextSecondary))),
              Text(precio(v.total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ]);
}
