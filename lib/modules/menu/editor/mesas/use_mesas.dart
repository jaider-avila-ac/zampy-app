import 'package:flutter/foundation.dart';

import '../../../../services/mesa_service.dart';
import '../../../orders/hooks/pagina_cursor.dart' show mensaje;
import 'mesa_model.dart';

/// Mesas del menú: carga, refresco silencioso (eventos en vivo) y las acciones de la lista (equivale a useMesas.js).
/// Las acciones lanzan el error para que quien confirma decida cómo mostrarlo.
class UseMesas extends ChangeNotifier {
  UseMesas(this.menu);

  final String menu;
  List<Mesa> mesas = const [];
  bool cargando = true;
  String? error;
  bool _cerrado = false;

  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso) {
      cargando = true;
      error = null;
      _avisar();
    }
    try {
      mesas = (await MesaService.listar(menu)).map(Mesa.fromJson).toList();
    } catch (e) {
      // el refresco en vivo no tapa el error de una acción
      if (!silencioso) error = mensaje(e, 'Error al cargar mesas');
    } finally {
      cargando = false;
      _avisar();
    }
  }

  void guardada(Mesa mesa) {
    mesas = mesas.any((m) => m.codigo == mesa.codigo)
        ? [for (final m in mesas) m.codigo == mesa.codigo ? mesa : m]
        : [...mesas, mesa];
    _avisar();
  }

  Future<void> eliminar(Mesa mesa) async {
    await MesaService.eliminar(menu, mesa.codigo);
    mesas = mesas.where((m) => m.codigo != mesa.codigo).toList();
    _avisar();
  }

  Future<void> alternarActivo(Mesa mesa) async {
    guardada(Mesa.fromJson(await MesaService.cambiarActivo(menu, mesa.codigo, !mesa.activo)));
  }

  void mostrarError(String? e) {
    error = e;
    _avisar();
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
