import 'package:flutter/foundation.dart';

import '../../../services/mesa_service.dart';
import '../../orders/hooks/pagina_cursor.dart' show mensaje;
import '../../orders/models/cuenta_mesa.dart';

/// Las cuentas abiertas de una mesa (varias si se dividió) y cuál se está viendo (equivale a useCuentasDeMesa.js).
/// Se crea uno por mesa: al cambiar de mesa nunca se ven las cuentas de la anterior.
class UseCuentasDeMesa extends ChangeNotifier {
  UseCuentasDeMesa(this.menu, this.mesa);

  final String menu;
  final String mesa;
  List<CuentaMesa> cuentas = const [];
  String? _activa;
  bool cargando = true;
  String? error;
  int _version = 0;
  bool _cerrado = false;

  CuentaMesa? get activa => cuentas.where((c) => c.codigo == _activa).firstOrNull;

  void elegir(String codigo) {
    _activa = codigo;
    _avisar();
  }

  Future<void> recargar({bool silencioso = false}) async {
    final version = ++_version;
    if (!silencioso) {
      cargando = true;
      error = null;
      _avisar();
    }
    try {
      final lista = (await MesaService.cuentasDeMesa(menu, mesa)).map(CuentaMesa.fromJson).toList();
      if (version != _version) return;
      cuentas = lista;
      // se conserva la cuenta elegida mientras siga abierta; si no, la primera
      if (!lista.any((c) => c.codigo == _activa)) _activa = lista.firstOrNull?.codigo;
      error = null;
    } catch (e) {
      if (version == _version && !silencioso) error = mensaje(e, 'No se pudieron cargar las cuentas de la mesa.');
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
