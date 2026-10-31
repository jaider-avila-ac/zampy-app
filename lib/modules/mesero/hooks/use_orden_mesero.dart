import 'package:flutter/foundation.dart';

import '../../../services/mesa_service.dart';
import '../../../services/pedido_service.dart';
import '../../orders/hooks/pagina_cursor.dart' show mensaje;
import '../../orders/utils/order_items.dart';
import '../utils/tomar_orden.dart';

/// "La orden" que arma el mesero en el menú público: ítems locales (aparte del carrito del cliente, que es por usuario
/// y menú, no por mesa) y su envío como ronda a la cuenta de la mesa (equivale a la orden de MenuPage + OrderSheet).
class UseOrdenMesero extends ChangeNotifier {
  UseOrdenMesero({required this.menu, required DestinoOrden destino}) : _destino = destino;

  final String menu;
  DestinoOrden _destino;
  List<Map<String, dynamic>> items = [];
  bool enviando = false;
  String? error;
  String _requestId = PedidoService.nuevoRequestId('ronda');
  bool _cerrado = false;

  DestinoOrden get destino => _destino;
  num get total => calculateOrderTotal(items);
  int get cantidad => items.fold<int>(0, (s, i) => s + ((i['quantity'] as num?)?.toInt() ?? 0));

  // cualquier cambio de la orden es otra ronda: un requestId nuevo (el mismo solo se reusa al reintentar igual)
  void _cambiar(List<Map<String, dynamic>> nuevos) {
    items = nuevos;
    _requestId = PedidoService.nuevoRequestId('ronda');
    error = null;
    _avisar();
  }

  void agregar(Map<String, dynamic> item) => _cambiar(addConfiguredOrderItem(items, item));

  void cantidadDe(String key, int delta) => _cambiar([
        for (final i in items)
          if (buildOrderItemKey(i) != key)
            i
          else if (((i['quantity'] as num?) ?? 0) + delta > 0)
            {...i, 'quantity': ((i['quantity'] as num?) ?? 0) + delta},
      ]);

  void quitar(String key) => _cambiar(items.where((i) => buildOrderItemKey(i) != key).toList());

  /// Envía la orden como ronda. [nota]: con cuenta nueva es su nombre; si no, nota para cocina. true = enviada.
  Future<bool> enviar(String nota) async {
    if (enviando || items.isEmpty) return false;
    enviando = true;
    error = null;
    _avisar();
    try {
      final limpia = nota.trim();
      final r = await MesaService.agregarRonda(
        menu,
        _destino.mesaCodigo,
        requestId: _requestId,
        items: items.map(toOrderItemPayload).toList(),
        cuenta: _destino.cuentaCodigo,
        nuevaCuenta: _destino.nuevaCuenta,
        nota: limpia.isEmpty ? null : limpia,
      );
      final cuenta = r['ordenCodigo']?.toString();
      if (cuenta != null && cuenta.isNotEmpty) _destino = _destino.conCuenta(cuenta);
      items = [];
      _requestId = PedidoService.nuevoRequestId('ronda');
      return true;
    } catch (e) {
      error = mensaje(e, 'No se pudo enviar la orden. Intenta de nuevo.');
      return false;
    } finally {
      enviando = false;
      _avisar();
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
