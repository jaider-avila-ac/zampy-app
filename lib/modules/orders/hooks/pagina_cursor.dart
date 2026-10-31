import 'package:flutter/foundation.dart';

import '../../../services/api_client.dart';

// Lista paginada por cursor ({…, siguiente}) con carga, "cargar más" y error (equivale a usePaginaCursor de React).
// Cada recarga invalida las respuestas anteriores, así una respuesta lenta no pisa una más reciente.

abstract class PaginaCursor<T> extends ChangeNotifier {
  List<T> items = [];
  String? _siguiente;
  bool cargando = false;
  bool cargandoMas = false;
  String? error;
  int _version = 0;
  bool _cerrado = false;

  bool get hayMas => _siguiente != null;

  /// La página que empieza en [cursor] (null = la primera).
  @protected
  Future<Map<String, dynamic>> pedir(String? cursor);

  @protected
  List<T> extraer(Map<String, dynamic> resp);

  /// Datos de todo el resultado (métricas, totales) que llegan con la primera página.
  @protected
  void alRecibirPrimera(Map<String, dynamic> resp) {}

  /// silencioso: refresco en vivo, sin vaciar la lista ni mostrar el spinner de pantalla completa.
  Future<void> cargarPagina(String mensajeError, {bool silencioso = false}) async {
    final version = ++_version;
    if (!silencioso) {
      cargando = true;
      error = null;
      _avisar();
    }
    try {
      final resp = await pedir(null);
      if (version != _version) return;
      items = extraer(resp);
      _siguiente = resp['siguiente']?.toString();
      alRecibirPrimera(resp);
      error = null;
    } catch (e) {
      if (version != _version) return;
      if (!silencioso) error = mensaje(e, mensajeError);
    } finally {
      if (version == _version) {
        cargando = false;
        _avisar();
      }
    }
  }

  Future<void> cargarMasPagina(String mensajeError) async {
    final cursor = _siguiente;
    if (cursor == null || cargandoMas || cargando) return;
    final version = _version;
    cargandoMas = true;
    _avisar();
    try {
      final resp = await pedir(cursor);
      if (version != _version) return;
      items = [...items, ...extraer(resp)];
      _siguiente = resp['siguiente']?.toString();
    } catch (e) {
      if (version == _version) error = mensaje(e, mensajeError);
    } finally {
      cargandoMas = false;
      _avisar();
    }
  }

  @protected
  void avisar() => _avisar();

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}

/// El mensaje del backend si lo hay; si no, el genérico de la pantalla.
String mensaje(Object e, String generico) => e is ApiException && e.message.trim().isNotEmpty ? e.message : generico;
