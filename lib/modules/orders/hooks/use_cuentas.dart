import 'package:flutter/foundation.dart';

import '../../../services/pedido_service.dart';
import '../models/cuenta_mesa.dart';
import '../models/pedido_negocio.dart' show toNum;
import 'pagina_cursor.dart';

// Cuentas de mesa: las CERRADAS de un rango (histórico) y las EN CURSO (abiertas ahora). Nunca se mezclan: cada una
// viene de su propio endpoint y tiene su propio estado (equivale a useCuentasCerradas / useCuentasEnCurso de React).

List<CuentaMesa> _cuentas(Map<String, dynamic> resp) => [
      if (resp['cuentas'] is List)
        for (final c in (resp['cuentas'] as List).whereType<Map>()) CuentaMesa.fromJson(Map<String, dynamic>.from(c)),
    ];

/// Lo que comparten las dos vistas de cuentas.
abstract class CuentasVista implements Listenable {
  List<CuentaMesa> get items;
  num get total;
  bool get cargando;
  String? get error;
  Future<void> recargar({bool silencioso = false});
}

class UseCuentasCerradas extends PaginaCursor<CuentaMesa> implements CuentasVista {
  UseCuentasCerradas(this.menu);

  final String menu;
  String _desde = '';
  String _hasta = '';

  @override
  num total = 0; // facturado en todo el rango
  List<VentaMesero> ventasPorMesero = const [];

  @override
  Future<Map<String, dynamic>> pedir(String? cursor) =>
      PedidoService.cuentasDelMenu(menu, _desde, _hasta, despues: cursor);

  @override
  List<CuentaMesa> extraer(Map<String, dynamic> resp) => _cuentas(resp);

  @override
  void alRecibirPrimera(Map<String, dynamic> resp) => total = toNum(resp['totalFacturado']);

  Future<void> cargar(String desde, String hasta, {bool silencioso = false}) async {
    _desde = desde;
    _hasta = hasta;
    PedidoService.ventasPorMesero(menu, desde, hasta).then((v) {
      ventasPorMesero = v.map(VentaMesero.fromJson).toList();
      avisar();
    }).catchError((_) {
      ventasPorMesero = const [];
    });
    await cargarPagina('No se pudieron cargar las cuentas.', silencioso: silencioso);
  }

  @override
  Future<void> recargar({bool silencioso = false}) => cargar(_desde, _hasta, silencioso: silencioso);

  Future<void> cargarMas() => cargarMasPagina('No se pudieron cargar más cuentas.');
}

class UseCuentasEnCurso extends ChangeNotifier implements CuentasVista {
  UseCuentasEnCurso(this.menu);

  final String menu;

  @override
  List<CuentaMesa> items = const [];
  @override
  num total = 0;
  @override
  bool cargando = false;
  @override
  String? error;
  int _version = 0;
  bool _cerrado = false;

  @override
  Future<void> recargar({bool silencioso = false}) async {
    final version = ++_version;
    if (!silencioso) {
      cargando = true;
      error = null;
      _avisar();
    }
    try {
      final resp = await PedidoService.cuentasEnCursoDelMenu(menu);
      if (version != _version) return;
      items = _cuentas(resp);
      total = toNum(resp['totalEnCursoGeneral']);
      error = null;
    } catch (e) {
      if (version == _version && !silencioso) error = mensaje(e, 'No se pudieron cargar las mesas en curso.');
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
