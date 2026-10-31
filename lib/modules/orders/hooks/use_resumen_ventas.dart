import 'package:flutter/foundation.dart';

import '../../../services/pedido_service.dart';
import '../models/pedido_negocio.dart';

/// Venta total del rango (pedidos de cliente + cuentas de mesa), calculada en el backend.
class UseResumenVentas extends ChangeNotifier {
  UseResumenVentas(this.menu);

  final String menu;
  ResumenVentas? resumen;
  bool cargando = false;
  int _version = 0;
  bool _cerrado = false;

  Future<void> cargar(String desde, String hasta) async {
    final version = ++_version;
    cargando = true;
    _avisar();
    try {
      final r = ResumenVentas.fromJson(await PedidoService.resumenVentas(menu, desde, hasta));
      if (version == _version) resumen = r;
    } catch (_) {
      // la tarjeta conserva el último valor; el error de la lista ya se muestra en su pestaña
    } finally {
      if (version == _version) {
        cargando = false;
        _avisar();
      }
    }
  }

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
