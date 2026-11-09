import 'package:flutter/foundation.dart';

import '../../../../../services/live_editor_service.dart';
import '../../../editor/live/editor_models.dart';

// Equivalente a src/modules/menu/public/edicion/categorias/useCategorias.js en React.

/// Estado y acciones de las categorías en el propio menú: crear, renombrar, mostrar u ocultar, eliminar y ordenar.
/// El orden se arma en pantalla y se guarda una sola vez (guardar en cada flecha hacía lento reordenar).
class CategoriasEdicion extends ChangeNotifier {
  CategoriasEdicion({required this.menuCodigo, required this.onCambio, required this.avisar}) {
    recargar();
  }

  final String menuCodigo;

  /// Recargar el menú después de cada cambio guardado.
  final Future<void> Function() onCambio;

  /// Aviso del resultado (mensaje, error).
  final void Function(String mensaje, {bool error}) avisar;

  List<LiveCategory>? lista;
  List<LiveCategory> _guardada = [];
  String? ocupado; // código de la categoría que se está guardando ('orden', 'nueva')
  final Map<String, String> _nombres = {}; // renombres sin guardar, por código
  bool _disposed = false;
  bool errorCarga = false; // la carga inicial falló (distinto de "sin categorías")

  void _notificar() {
    if (!_disposed) notifyListeners();
  }

  /// Carga inicial / reintento. Un fallo NO se muestra como "sin categorías": marca errorCarga.
  Future<void> recargar() async {
    errorCarga = false;
    _notificar();
    try {
      await _cargar();
    } catch (_) {
      errorCarga = true;
      _notificar();
    }
  }

  Future<void> _cargar() async {
    final menu = await LiveEditorService.load(menuCodigo);
    final ordenada = [...menu.categories]..sort((a, b) => a.order.compareTo(b.order));
    lista = ordenada;
    _guardada = [...ordenada];
    _notificar();
  }

  Future<bool> _accion(String codigo, Future<void> Function() fn, String? mensaje) async {
    ocupado = codigo;
    _notificar();
    try {
      await fn();
      if (mensaje != null) avisar(mensaje);
      await _cargar();
      await onCambio();
      return true;
    } catch (e) {
      avisar('No se pudo guardar: ${e.toString().replaceFirst('Exception: ', '')}', error: true);
      return false;
    } finally {
      ocupado = null;
      _notificar();
    }
  }

  bool get ordenCambiado {
    final l = lista;
    if (l == null) return false;
    for (var i = 0; i < l.length; i++) {
      if (i >= _guardada.length || l[i].codigo != _guardada[i].codigo) return true;
    }
    return false;
  }

  /// Con el orden sin guardar no se hacen otras acciones (recargar la lista lo perdería).
  bool get bloqueado => ocupado != null || ordenCambiado;

  void mover(int i, int delta) {
    final orden = [...lista!];
    final cat = orden.removeAt(i);
    orden.insert(i + delta, cat);
    lista = orden;
    _notificar();
  }

  void deshacerOrden() {
    lista = [..._guardada];
    _notificar();
  }

  Future<void> guardarOrden() => _accion(
        'orden',
        () => LiveEditorService.orderCategories(menuCodigo, [for (final c in lista!) c.codigo]),
        'Orden guardado',
      );

  String nombreDe(LiveCategory c) => _nombres[c.codigo] ?? c.name;

  void editarNombre(LiveCategory c, String nombre) {
    _nombres[c.codigo] = nombre;
    _notificar();
  }

  bool nombreEditado(LiveCategory c) => _nombres[c.codigo] != null && _nombres[c.codigo]!.trim() != c.name;

  Future<void> renombrar(LiveCategory c) async {
    final nombre = (_nombres[c.codigo] ?? '').trim();
    if (nombre.isEmpty || nombre == c.name) return;
    final ok = await _accion(
      c.codigo,
      () => LiveEditorService.updateCategory(menuCodigo, c.codigo, {'name': nombre}),
      'Categoría renombrada',
    );
    if (ok) _nombres.remove(c.codigo);
  }

  Future<void> alternarVisible(LiveCategory c) => _accion(
        c.codigo,
        () => LiveEditorService.updateCategory(menuCodigo, c.codigo, {'isVisible': !c.isVisible}),
        c.isVisible ? 'Categoría oculta' : 'Categoría visible',
      );

  Future<void> eliminar(LiveCategory c) =>
      _accion(c.codigo, () => LiveEditorService.deleteCategory(menuCodigo, c.codigo), 'Categoría eliminada');

  Future<bool> crear(String nombre, String tipoContenido) => _accion(
        'nueva',
        () => LiveEditorService.createCategory(menuCodigo, {
          'name': nombre.trim(),
          'icon': 'utensils',
          'isVisible': true,
          'tipoContenido': tipoContenido,
        }),
        'Categoría creada',
      );

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
