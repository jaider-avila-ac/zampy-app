import 'package:flutter/material.dart';

import '../../../../../services/live_editor_service.dart';
import '../../models/public_menu_model.dart';
import '../comun/guardar.dart';
import 'con_fotos.dart';
import 'foto_producto.dart';
import 'selector_categoria.dart';

// Equivalente a src/modules/menu/public/edicion/producto/FormProductoBasico.jsx en React.

/// Datos básicos de un producto: categoría, foto, nombre, precio, descripción y destacado. Solo se envía lo que cambió.
class FormProductoBasico extends StatefulWidget {
  const FormProductoBasico({
    super.key,
    required this.menuCodigo,
    required this.producto,
    required this.categorias,
    required this.onListo,
  });

  final String menuCodigo;
  final MenuProduct producto;
  final List<MenuCategory> categorias;
  final Future<void> Function() onListo;

  @override
  State<FormProductoBasico> createState() => _FormProductoBasicoState();
}

class _FormProductoBasicoState extends State<FormProductoBasico> with GuardarSeccion {
  MenuProduct get _p => widget.producto;
  late String? _categoria = _p.categoryId;
  late final _nombre = TextEditingController(text: _p.name);
  late final _precio = TextEditingController(text: _p.price == _p.price.roundToDouble() ? _p.price.toInt().toString() : '${_p.price}');
  late final _descripcion = TextEditingController(text: _p.description ?? '');
  late bool _destacado = _p.isFeatured;
  late final Offset _posicionInicial = Offset(_p.imageX, _p.imageY);
  late FotoElegida _foto = FotoElegida(url: _p.imageUrl, posicion: _posicionInicial);

  @override
  void dispose() {
    _nombre.dispose();
    _precio.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  bool get _pideFoto => conFotos(categoriaPorId(widget.categorias, _categoria));

  // La foto es opcional aunque la categoría sea "con imágenes": sin foto, el menú muestra el logo como respaldo.
  bool get _listo =>
      _nombre.text.trim().isNotEmpty && (double.tryParse(_precio.text) ?? 0) > 0;

  Future<void> _guardar() => guardar(
        () async {
          final datos = <String, dynamic>{
            'name': _nombre.text.trim(),
            'price': double.parse(_precio.text),
            'description': _descripcion.text.trim(),
            'isFeatured': _destacado,
          };
          if (_categoria != _p.categoryId) datos['categoryId'] = _categoria;
          if (_pideFoto && (_foto.archivo != null || _foto.url != _p.imageUrl)) {
            datos['imageUrl'] = await _foto.resolver('menus/${widget.menuCodigo}/productos') ?? '';
          }
          if (_pideFoto && _foto.posicion != _posicionInicial) {
            datos['imagePosition'] = {'x': _foto.posicion.dx, 'y': _foto.posicion.dy};
          }
          await LiveEditorService.updateProductBasic(widget.menuCodigo, _p.id, datos);
        },
        onListo: widget.onListo,
      );

  @override
  Widget build(BuildContext context) {
    void refrescar(_) => setState(() {});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectorCategoria(
          categorias: widget.categorias,
          valor: _categoria,
          onChanged: (c) => setState(() => _categoria = c),
        ),
        if (_pideFoto) FotoProducto(foto: _foto, onCambio: (f) => setState(() => _foto = f)),
        CampoTexto(etiqueta: 'Nombre', controller: _nombre, maxLength: 60, requerido: true, onChanged: refrescar),
        CampoTexto(etiqueta: 'Precio', controller: _precio, requerido: true,
            teclado: const TextInputType.numberWithOptions(decimal: true), onChanged: refrescar),
        CampoTexto(etiqueta: 'Descripción', controller: _descripcion, maxLength: 300, maxLines: 3),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Destacado'),
          subtitle: const Text('Aparece en la fila de destacados del menú.'),
          value: _destacado,
          onChanged: (v) => setState(() => _destacado = v),
        ),
        const SizedBox(height: 8),
        BotonGuardar(guardando: guardando, onPressed: _listo ? _guardar : null),
      ],
    );
  }
}
