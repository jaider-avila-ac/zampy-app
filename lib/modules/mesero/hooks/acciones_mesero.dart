import 'package:flutter/foundation.dart';

import '../../../services/mesa_service.dart';
import '../../orders/hooks/pagina_cursor.dart' show mensaje;
import '../../orders/models/pedido_negocio.dart' show toNum;
import '../../orders/utils/formato.dart';

/// Resultado de una acción, para avisar con un mensaje (equivale a los toast de React).
typedef ResultadoAccion = ({bool ok, String titulo, String detalle, bool mesaLibre});

/// Lo que el mesero hace sobre una cuenta de la mesa: avanzar o cancelar rondas, cerrar y cancelar la cuenta
/// (equivale a useAccionesMesero.js). Los abonos los guarda su propia hoja.
class AccionesMesero extends ChangeNotifier {
  AccionesMesero(this.menu, this.mesa);

  final String menu;
  final String mesa;
  String? actualizando; // código de la ronda que cambia de estado
  bool cerrando = false;
  bool cancelando = false;
  bool _cerrado = false;

  bool get ocupada => actualizando != null || cerrando || cancelando;

  Future<ResultadoAccion> cambiarEstadoRonda(String ronda, String estado) async {
    actualizando = ronda;
    _avisar();
    try {
      await MesaService.cambiarEstadoRonda(menu, ronda, estado);
      return (ok: true, titulo: '', detalle: '', mesaLibre: false);
    } catch (e) {
      return (ok: false, titulo: 'No se pudo actualizar la ronda', detalle: mensaje(e, 'Intenta de nuevo.'), mesaLibre: false);
    } finally {
      actualizando = null;
      _avisar();
    }
  }

  Future<ResultadoAccion> cerrar(String cuenta) async {
    cerrando = true;
    _avisar();
    try {
      final r = await MesaService.cerrarCuenta(menu, mesa, cuenta);
      final rondas = toNum(r['cantidadRondas']).toInt();
      return (
        ok: true,
        titulo: 'Cuenta cerrada',
        detalle: 'Total: ${precio(toNum(r['totalCerrado']))} · $rondas ronda${rondas == 1 ? '' : 's'}',
        mesaLibre: r['mesaLibre'] == true,
      );
    } catch (e) {
      return (ok: false, titulo: 'No se pudo cerrar la cuenta', detalle: mensaje(e, 'Intenta de nuevo.'), mesaLibre: false);
    } finally {
      cerrando = false;
      _avisar();
    }
  }

  Future<ResultadoAccion> cancelar(String cuenta) async {
    cancelando = true;
    _avisar();
    try {
      final r = await MesaService.cancelarCuenta(menu, mesa, cuenta);
      final libre = r['mesaLibre'] == true;
      return (
        ok: true,
        titulo: 'Cuenta cancelada',
        detalle: libre ? 'La mesa quedó libre.' : 'Quedan otras cuentas abiertas en la mesa.',
        mesaLibre: libre,
      );
    } catch (e) {
      return (ok: false, titulo: 'No se pudo cancelar la cuenta', detalle: mensaje(e, 'Intenta de nuevo.'), mesaLibre: false);
    } finally {
      cancelando = false;
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
