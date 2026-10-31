import 'package:flutter/material.dart';

import '../../../../shared/app_colors.dart';
import '../../../../shared/responsive.dart';
import '../../../orders/components/comun/estados_lista.dart';
import '../../../orders/components/comun/filtro_fechas.dart';
import '../../../orders/models/cuenta_mesa.dart';
import '../../../orders/utils/formato.dart';
import '../../hooks/use_historial_mesero.dart';
import '../../utils/estado_ronda.dart';

/// "Mis órdenes": las rondas del mesero (individual) o sus cuentas cerradas (por mesa) en un rango de fechas
/// (equivale a MisPedidosMesero.jsx).
class MisOrdenesMesero extends StatelessWidget {
  const MisOrdenesMesero({super.key, required this.historial});

  final UseHistorialMesero historial;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: historial,
        builder: (context, _) {
          final h = historial;
          final individual = h.modo == ModoHistorial.individual;
          return RefreshIndicator(
            onRefresh: h.cargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: contenidoPadding(context, maxWidth: 720),
              children: [
                SegmentedButton<ModoHistorial>(
                  segments: const [
                    ButtonSegment(value: ModoHistorial.individual, label: Text('Individual')),
                    ButtonSegment(value: ModoHistorial.porMesa, label: Text('Por mesa')),
                  ],
                  selected: {h.modo},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => h.cambiarModo(s.first),
                ),
                const SizedBox(height: 12),
                FiltroFechas(
                  desde: h.desde,
                  hasta: h.hasta,
                  onDesde: (v) => h.cambiarRango(desde: v),
                  onHasta: (v) => h.cambiarRango(hasta: v),
                  onBuscar: h.cargar,
                  cargando: h.cargando,
                ),
                const SizedBox(height: 14),
                Row(children: [
                  if (individual) ...[
                    _Metrica(valor: '${h.totalRondas}', titulo: 'Rondas'),
                    const SizedBox(width: 10),
                    _Metrica(valor: '${h.cancelados}', titulo: 'Cancelados', color: AppColors.kRed),
                  ] else
                    _Metrica(valor: '${h.cantidadCuentas}', titulo: 'Cuentas cerradas'),
                  const SizedBox(width: 10),
                  _Metrica(valor: precio(h.totalCobrado), titulo: 'Cobrado', destacada: true),
                ]),
                const SizedBox(height: 14),
                if (h.error != null) ErrorLista(h.error!),
                if (h.cargando)
                  const CargandoLista()
                else if (individual)
                  if (h.rondas.isEmpty)
                    const ListaVacia(icono: Icons.assignment_outlined, texto: 'Sin rondas en este rango')
                  else
                    ...h.rondas.map((r) => Padding(padding: const EdgeInsets.only(bottom: 8), child: RondaHistorialRow(ronda: r)))
                else if (h.cuentas.isEmpty)
                  const ListaVacia(icono: Icons.receipt_long_outlined, texto: 'Sin cuentas cerradas en este rango')
                else ...[
                  ...h.cuentas.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _OrdenCard(cuenta: c))),
                  CargarMasBoton(hayMas: h.hayMas, cargando: h.cargandoMas, onPressed: h.cargarMas),
                ],
              ],
            ),
          );
        },
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
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: destacada ? const Color(0xFFC7D2FE) : AppColors.kTextSecondary)),
          ]),
        ),
      );
}

/// Una ronda del historial: mesa, hora, estado y total.
class RondaHistorialRow extends StatelessWidget {
  const RondaHistorialRow({super.key, required this.ronda});

  final RondaCuenta ronda;

  @override
  Widget build(BuildContext context) {
    final e = estadoRonda(ronda.estado);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ronda.mesaNombre ?? 'Ronda', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            Text(hora(ronda.creadoEn), style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: e.fondo, borderRadius: BorderRadius.circular(20)),
          child: Text(e.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: e.texto)),
        ),
        const SizedBox(width: 10),
        Text(precio(ronda.total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _OrdenCard extends StatefulWidget {
  const _OrdenCard({required this.cuenta});

  final CuentaMesa cuenta;

  @override
  State<_OrdenCard> createState() => _OrdenCardState();
}

class _OrdenCardState extends State<_OrdenCard> {
  bool _abierta = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.cuenta;
    final n = c.rondas.length;
    return TarjetaLista(children: [
      InkWell(
        onTap: () => setState(() => _abierta = !_abierta),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Icon(Icons.receipt_outlined, size: 17, color: AppColors.kTextMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.mesaNombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                Text('${hora(c.cerradaEn)} · $n ronda${n == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
              ]),
            ),
            Text(precio(c.total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
            Icon(_abierta ? Icons.expand_more : Icons.chevron_right, size: 18, color: AppColors.kTextMuted),
          ]),
        ),
      ),
      if (_abierta)
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            for (final r in c.rondas)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: RondaHistorialRow(ronda: RondaCuenta(
                  codigo: r.codigo,
                  estado: r.estado,
                  total: r.total,
                  creadoEn: r.creadoEn,
                  mesaNombre: c.mesaNombre,
                )),
              ),
          ]),
        ),
    ]);
  }
}
