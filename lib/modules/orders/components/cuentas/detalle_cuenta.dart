import 'package:flutter/material.dart';

import '../../../../shared/app_colors.dart';
import '../../models/cuenta_mesa.dart';
import '../../utils/estado_pedido.dart';
import '../../utils/formato.dart';

/// Lo que tiene una cuenta: sus rondas con ítems y notas, los ajustes auditados y los movimientos de pago.
class DetalleCuenta extends StatelessWidget {
  const DetalleCuenta({super.key, required this.cuenta});

  final CuentaMesa cuenta;

  static const _chico = TextStyle(fontSize: 11, color: AppColors.kTextSecondary);
  static const _seccion = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: AppColors.kTextMuted);

  Widget _nota(String nota) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Text('Nota: $nota', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
      );

  Widget _movimiento(String texto, String? actor, String valor, bool positivo) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(texto, style: _chico.copyWith(fontWeight: FontWeight.w600, color: AppColors.kTextPrimary)),
                  if (actor != null) Text(actor, style: const TextStyle(fontSize: 10, color: AppColors.kTextMuted)),
                ],
              ),
            ),
            Text(valor,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: positivo ? const Color(0xFF047857) : AppColors.kRed)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in cuenta.rondas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(child: Text(estadosPedido[r.estado]?.label ?? r.estado, style: _chico)),
                    Text(precio(r.total), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                  if (r.nota != null) _nota(r.nota!),
                  if (r.items.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4, left: 2),
                      padding: const EdgeInsets.only(left: 8),
                      decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.kCardBorder, width: 2))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final it in r.items)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${it.cantidad}× ${it.nombre}', style: _chico),
                                  if (it.detalle != null) Text(it.detalle!, style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
                                  if (it.nota != null)
                                    Text('Nota: ${it.nota}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (cuenta.ajustes.isNotEmpty) ...[
            const Divider(height: 16),
            const Text('AJUSTES AUDITADOS', style: _seccion),
            for (final a in cuenta.ajustes)
              _movimiento('${a.esCargo ? 'Cargo' : 'Descuento'} · ${a.motivo}', a.actor,
                  '${a.esCargo ? '+' : '−'}${precio(a.valor)}', a.esCargo),
          ],
          if (cuenta.pagos.isNotEmpty) ...[
            const Divider(height: 16),
            const Text('MOVIMIENTOS DE PAGO', style: _seccion),
            for (final p in cuenta.pagos)
              _movimiento('${p.esAbono ? 'Abono' : 'Reverso'} · ${p.medio}', p.actor,
                  '${p.esAbono ? '+' : '−'}${precio(p.valor)}', p.esAbono),
            const Divider(height: 12),
            Row(children: [
              const Expanded(child: Text('Saldo pendiente', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
              Text(precio(cuenta.saldoPendiente), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ],
        ],
      );
}
