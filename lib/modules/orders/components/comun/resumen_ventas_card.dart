import 'package:flutter/material.dart';

import '../../models/pedido_negocio.dart';
import '../../utils/formato.dart';

/// Venta total del rango (pedidos + mesas). Ocupa su espacio desde el inicio; solo los números muestran la carga.
class ResumenVentasCard extends StatelessWidget {
  const ResumenVentasCard({super.key, required this.resumen, required this.cargando});

  final ResumenVentas? resumen;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    String valor(num? n) => cargando && resumen == null ? '···' : precio(n);
    // con cifras grandes en un teléfono estrecho los números se reducen en lugar de desbordar
    Widget dato(String etiqueta, num? n) => Flexible(
          flex: 2,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(etiqueta, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                Text(valor(n), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 17, color: Color(0xFFCBD5E1)),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
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
          const SizedBox(width: 12),
          dato('Pedidos', resumen?.totalPedidos),
          const SizedBox(width: 12),
          dato('Mesas', resumen?.totalCuentas),
        ],
      ),
    );
  }
}
