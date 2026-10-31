import 'package:flutter/material.dart';

import '../../../../shared/app_colors.dart';
import '../../../orders/models/cuenta_mesa.dart';
import '../../hooks/acciones_mesero.dart';

/// Nombre de la mesa, pestañas de cuentas (si se dividió) y las acciones de la cuenta abierta. Cuándo se puede cerrar
/// o cancelar se explica en el aviso de cada botón.
class CabeceraCuenta extends StatelessWidget {
  const CabeceraCuenta({
    super.key,
    required this.mesaNombre,
    required this.cuentas,
    required this.activa,
    required this.acciones,
    required this.onElegirCuenta,
    required this.onCerrar,
    required this.onCancelar,
    required this.onAbonar,
    required this.onAgregar,
  });

  final String mesaNombre;
  final List<CuentaMesa> cuentas;
  final CuentaMesa? activa;
  final AccionesMesero acciones;
  final ValueChanged<String> onElegirCuenta;
  final VoidCallback onCerrar;
  final VoidCallback onCancelar;
  final VoidCallback onAbonar;
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    final rondas = activa?.rondas ?? const <RondaCuenta>[];
    final activas = rondas.where((r) => r.activa).length;
    final saldo = activa?.saldoPendiente ?? 0;
    final hayEntregadas = rondas.any((r) => r.estado == 'entregado');
    final puedeCerrar = activa != null && activas == 0 && saldo == 0 && !acciones.cerrando;
    final puedeCancelar = !acciones.cancelando && !acciones.cerrando && !hayEntregadas;

    Widget accion(IconData icono, String texto, VoidCallback? onTap, String ayuda, {bool cargando = false, Color? color}) =>
        Tooltip(
          message: ayuda,
          child: OutlinedButton.icon(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: color ?? AppColors.kTextSecondary,
              side: BorderSide(color: color?.withValues(alpha: 0.4) ?? AppColors.kCardBorder),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              minimumSize: Size.zero,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: cargando
                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.8))
                : Icon(icono, size: 14),
            label: Text(texto),
          ),
        );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(mesaNombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.kTextPrimary)),
          Text(
            '${cuentas.length > 1 ? '${cuentas.length} cuentas separadas · ' : ''}$activas rondas activas',
            style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted),
          ),
          if (cuentas.length > 1) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in cuentas)
                  ChoiceChip(
                    label: Text(c.referencia ?? 'Principal'),
                    selected: c.codigo == activa?.codigo,
                    showCheckmark: false,
                    onSelected: (_) => onElegirCuenta(c.codigo),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: c.codigo == activa?.codigo ? Colors.white : AppColors.kTextSecondary,
                    ),
                    selectedColor: AppColors.kBlue,
                    backgroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    shape: StadiumBorder(side: BorderSide(color: c.codigo == activa?.codigo ? AppColors.kBlue : AppColors.kCardBorder)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (rondas.isNotEmpty)
                accion(Icons.cancel_outlined, 'Cancelar', puedeCancelar ? onCancelar : null,
                    hayEntregadas ? 'Ya hay platos entregados: cierra la cuenta en vez de cancelar' : 'Cancelar cuenta',
                    cargando: acciones.cancelando),
              accion(
                Icons.receipt_outlined,
                'Cerrar',
                puedeCerrar ? onCerrar : null,
                activas > 0
                    ? 'Resuelve las rondas activas antes de cerrar la cuenta'
                    : saldo != 0
                        ? 'Registra el pago completo antes de cerrar'
                        : 'Cerrar cuenta',
                cargando: acciones.cerrando,
              ),
              if (saldo > 0 && activas == 0)
                accion(Icons.account_balance_wallet_outlined, 'Abonar', onAbonar, 'Registrar un abono', color: const Color(0xFF047857)),
              FilledButton.icon(
                onPressed: onAgregar,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.kBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 15),
                label: const Text('Agregar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
