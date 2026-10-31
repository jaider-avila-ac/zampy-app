import 'package:flutter/foundation.dart';

import '../../../services/mesa_service.dart';
import '../../../services/mis_menus_service.dart';
import '../../dashboard/models/dashboard_models.dart';
import '../../orders/hooks/pagina_cursor.dart' show mensaje;
import '../models/mesa_mesero.dart';

/// Las mesas del mesero y el resumen del menú (nombre y slug para tomar la orden) — equivale a useMesasMesero.js.
/// Un fallo se muestra como error (antes React mostraba "Sin mesas configuradas").
class UseMesasMesero extends ChangeNotifier {
  UseMesasMesero(this.menu);

  final String menu;
  List<MesaMesero> mesas = const [];
  MenuResumen? resumen;
  bool cargando = true;
  String? error;
  bool _cerrado = false;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    _avisar();
    // el resumen solo aporta nombre y slug: si falla, las mesas se ven igual
    final pedidoResumen = MisMenusService.getResumen(menu).then<MenuResumen?>((r) => r, onError: (Object _) => null);
    try {
      mesas = (await MesaService.mesasMesero(menu)).map(MesaMesero.fromJson).toList();
      resumen = await pedidoResumen;
    } catch (e) {
      error = mensaje(e, 'No se pudieron cargar las mesas.');
    } finally {
      cargando = false;
      _avisar();
    }
  }

  /// Refresco en vivo, sin spinner.
  Future<void> recargar() async {
    try {
      mesas = (await MesaService.mesasMesero(menu)).map(MesaMesero.fromJson).toList();
      error = null;
      _avisar();
    } catch (_) {
      // se reintenta con el próximo evento
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
