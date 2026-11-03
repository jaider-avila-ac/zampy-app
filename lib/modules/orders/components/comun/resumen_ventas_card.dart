import 'package:flutter/material.dart';

import '../../models/pedido_negocio.dart';
import '../../utils/formato.dart';

/// Venta total del rango (pedidos + mesas). En pantallas estrechas los valores se apilan en vez de
/// competir por espacio en una sola fila (los montos largos se veían desproporcionados).
class ResumenVentasCard extends StatelessWidget {
  const ResumenVentasCard({super.key, required this.resumen, required this.cargando});

  final ResumenVentas? resumen;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    String valor(num? n) => cargando && resumen == null ? '···' : precio(n);
    final apilar = MediaQuery.sizeOf(context).width < 480;

    final total = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.account_balance_wallet_outlined, size: 17, color: Color(0xFFCBD5E1)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Venta total del rango', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  valor(resumen?.totalVentas),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    Widget dato(String etiqueta, num? n, {CrossAxisAlignment align = CrossAxisAlignment.end}) => Column(
          crossAxisAlignment: align,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(etiqueta, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            Text(valor(n), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)),
      child: apilar
          // Móvil: total arriba, y debajo Pedidos / Mesas en su propia fila (alineados bajo el texto).
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                total,
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 29),
                  child: Row(
                    children: [
                      Expanded(child: dato('Pedidos', resumen?.totalPedidos, align: CrossAxisAlignment.start)),
                      const SizedBox(width: 12),
                      Expanded(child: dato('Mesas', resumen?.totalCuentas, align: CrossAxisAlignment.start)),
                    ],
                  ),
                ),
              ],
            )
          // Pantalla ancha: todo en una fila.
          : Row(
              children: [
                Expanded(flex: 3, child: total),
                const SizedBox(width: 12),
                Flexible(flex: 2, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: dato('Pedidos', resumen?.totalPedidos))),
                const SizedBox(width: 12),
                Flexible(flex: 2, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: dato('Mesas', resumen?.totalCuentas))),
              ],
            ),
    );
  }
}
