import 'package:flutter/material.dart';

import '../../../../services/mesa_service.dart';
import '../../../../shared/app_colors.dart';
import '../../../../shared/confirmar_dialog.dart';
import '../../hooks/pagina_cursor.dart' show mensaje;
import '../../models/cuenta_mesa.dart';
import '../../utils/formato.dart';
import 'detalle_cuenta.dart';

/// Una cuenta de mesa en la lista: al tocarla se despliega su detalle y las acciones (agregar ítem olvidado, ajuste
/// auditado, conciliar saldo y, si está en curso, cerrar o cancelar). El dueño o editor puede cerrar o cancelar
/// cualquier cuenta: el mesero que la abrió puede no estar disponible.
class CuentaTile extends StatefulWidget {
  const CuentaTile({
    super.key,
    required this.cuenta,
    required this.enCurso,
    required this.menu,
    required this.onAgregarItem,
    required this.onAjustar,
    required this.onPago,
    required this.onCambiada,
  });

  final CuentaMesa cuenta;
  final bool enCurso;
  final String menu;
  final VoidCallback onAgregarItem;
  final VoidCallback onAjustar;
  final VoidCallback onPago;
  final VoidCallback onCambiada;

  @override
  State<CuentaTile> createState() => _CuentaTileState();
}

class _CuentaTileState extends State<CuentaTile> {
  bool _abierta = false;
  bool _cerrando = false;
  bool _cancelando = false;
  String? _error;

  Future<void> _ejecutar(Future<void> Function() accion, void Function(bool) ocupado, String generico) async {
    setState(() {
      _error = null;
      ocupado(true);
    });
    try {
      await accion();
      widget.onCambiada();
    } catch (e) {
      if (mounted) setState(() => _error = mensaje(e, generico));
    } finally {
      if (mounted) setState(() => ocupado(false));
    }
  }

  void _cerrar() => _ejecutar(
        () => MesaService.cerrarCuenta(widget.menu, widget.cuenta.mesaCodigo, widget.cuenta.codigo),
        (v) => _cerrando = v,
        'No se pudo cerrar la cuenta.',
      );

  Future<void> _cancelar() async {
    const c = Confirmacion(
      '¿Cancelar esta cuenta?',
      'Esta acción no se puede deshacer — la cuenta de la mesa quedará cancelada e ignorada.',
      'Sí, cancelar',
      peligro: true,
    );
    if (!await confirmar(context, c, cancelar: 'No, volver')) return;
    await _ejecutar(
      () => MesaService.cancelarCuenta(widget.menu, widget.cuenta.mesaCodigo, widget.cuenta.codigo),
      (v) => _cancelando = v,
      'No se pudo cancelar la cuenta.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cuenta;
    final enCurso = widget.enCurso;
    final ocupada = _cerrando || _cancelando;
    final rondas = c.rondas.length;

    Widget accion(IconData icono, String texto, Color color, VoidCallback? onTap, {bool cargando = false, String? ayuda}) {
      final boton = TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          minimumSize: Size.zero,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        icon: cargando
            ? SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 1.8, color: color))
            : Icon(icono, size: 15),
        label: Text(texto),
      );
      return ayuda == null ? boton : Tooltip(message: ayuda, child: boton);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _abierta = !_abierta),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(enCurso ? Icons.sensors : Icons.receipt_outlined,
                    size: 17, color: enCurso ? const Color(0xFF10B981) : AppColors.kTextMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: c.mesaNombre),
                          if (c.referencia != null)
                            TextSpan(
                              text: '  · ${c.referencia}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
                            ),
                        ]),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.kTextPrimary),
                      ),
                      Text(
                        'Mesero: ${c.meseroNombre ?? '—'} · ${enCurso ? 'Abierta ' : ''}${hora(enCurso ? c.abiertaEn : c.cerradaEn)}'
                        ' · $rondas ronda${rondas == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(precio(enCurso ? c.totalEnCurso : c.total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                Icon(_abierta ? Icons.expand_more : Icons.chevron_right, size: 18, color: AppColors.kTextMuted),
              ],
            ),
          ),
        ),
        if (_abierta)
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DetalleCuenta(cuenta: c),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    if (enCurso) accion(Icons.add_box_outlined, 'Agregar ítem olvidado', AppColors.kBlue, widget.onAgregarItem),
                    accion(Icons.price_change_outlined, 'Registrar ajuste auditado', AppColors.kBlue, widget.onAjustar),
                    if (c.conSaldo) accion(Icons.account_balance_wallet_outlined, 'Conciliar saldo', const Color(0xFF047857), widget.onPago),
                    if (enCurso) ...[
                      accion(Icons.lock_outline, 'Cerrar cuenta', AppColors.kTextSecondary, ocupada ? null : _cerrar,
                          cargando: _cerrando,
                          ayuda: c.conSaldo ? 'Primero concilia o ajusta el saldo a \$0 para poder cerrar' : null),
                      accion(Icons.block, 'Cancelar (ignorar todo)', AppColors.kRed, ocupada ? null : _cancelar,
                          cargando: _cancelando, ayuda: 'Solo funciona si nada de la cuenta se ha entregado todavía'),
                    ],
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_error!, style: const TextStyle(fontSize: 11, color: AppColors.kRed)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
