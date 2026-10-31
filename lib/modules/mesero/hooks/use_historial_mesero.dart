import 'package:flutter/foundation.dart';

import '../../../services/mesa_service.dart';
import '../../orders/hooks/pagina_cursor.dart' show mensaje;
import '../../orders/models/cuenta_mesa.dart';
import '../../orders/models/pedido_negocio.dart' show toNum;
import '../../orders/utils/formato.dart';

enum ModoHistorial { individual, porMesa }

/// "Mis órdenes" del mesero en un rango: sus rondas (individual) o sus cuentas cerradas por páginas (por mesa).
/// Los totales son de todo el rango (equivale a useHistorialMesero.js).
class UseHistorialMesero extends ChangeNotifier {
  UseHistorialMesero(this.menu);

  final String menu;
  ModoHistorial modo = ModoHistorial.individual;
  String desde = bogotaHoy();
  String hasta = bogotaHoy();

  List<RondaCuenta> rondas = const [];
  List<CuentaMesa> cuentas = const [];
  int totalRondas = 0;
  int cancelados = 0;
  num totalCobrado = 0; // individual: cobrado del rango · por mesa: facturado de las cuentas cerradas
  int cantidadCuentas = 0;
  String? _siguiente;

  bool cargando = true;
  bool cargandoMas = false;
  String? error;
  int _version = 0;
  bool _cerrado = false;

  bool get hayMas => modo == ModoHistorial.porMesa && _siguiente != null;

  void cambiarModo(ModoHistorial m) {
    if (m == modo) return;
    modo = m;
    cargar();
  }

  void cambiarRango({String? desde, String? hasta}) {
    this.desde = desde ?? this.desde;
    this.hasta = hasta ?? this.hasta;
    cargar();
  }

  Future<void> cargar() async {
    final version = ++_version;
    cargando = true;
    error = null;
    _avisar();
    try {
      if (modo == ModoHistorial.individual) {
        final r = await MesaService.misRondas(menu, desde, hasta);
        if (version != _version) return;
        rondas = _lista(r['rondas']).map(RondaCuenta.fromJson).toList();
        totalRondas = toNum(r['totalRondas']).toInt();
        cancelados = toNum(r['cancelados']).toInt();
        totalCobrado = toNum(r['totalCobrado']);
      } else {
        final r = await MesaService.misOrdenes(menu, desde, hasta);
        if (version != _version) return;
        cuentas = _lista(r['cuentas']).map(CuentaMesa.fromJson).toList();
        _siguiente = r['siguiente']?.toString();
        cantidadCuentas = toNum(r['cantidadCuentas']).toInt();
        totalCobrado = toNum(r['totalFacturado']);
      }
    } catch (e) {
      if (version == _version) error = mensaje(e, 'No se pudo cargar el historial.');
    } finally {
      if (version == _version) {
        cargando = false;
        _avisar();
      }
    }
  }

  Future<void> cargarMas() async {
    final cursor = _siguiente;
    if (cursor == null || cargandoMas) return;
    final version = _version;
    cargandoMas = true;
    _avisar();
    try {
      final r = await MesaService.misOrdenes(menu, desde, hasta, despues: cursor);
      if (version != _version) return;
      cuentas = [...cuentas, ..._lista(r['cuentas']).map(CuentaMesa.fromJson)];
      _siguiente = r['siguiente']?.toString();
    } catch (e) {
      if (version == _version) error = mensaje(e, 'No se pudieron cargar más cuentas.');
    } finally {
      cargandoMas = false;
      _avisar();
    }
  }

  static List<Map<String, dynamic>> _lista(dynamic v) =>
      v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
