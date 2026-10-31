import 'package:flutter/material.dart';

import '../../../../../services/live_editor_service.dart';
import '../../../../../shared/app_colors.dart';
import '../../models/public_menu_model.dart';
import '../comun/guardar.dart';
import 'con_fotos.dart';
import 'foto_producto.dart';
import 'selector_categoria.dart';

// Equivalente a src/modules/menu/public/edicion/producto/FormNuevoProducto.jsx en React.

/// Producto nuevo: solo lo básico. Tamaños, ingredientes, adiciones, grupos y promoción se agregan desde su "⋯".
class FormNuevoProducto extends StatefulWidget {
  const FormNuevoProducto({
    super.key,
    required this.menuCodigo,
    required this.categorias,
    this.categoriaInicial,
    required this.onListo,
  });

  final String menuCodigo;
  final List<MenuCategory> categorias;
  final String? categoriaInicial;
  final Future<void> Function() onListo;

  @override
  State<FormNuevoProducto> createState() => _FormNuevoProductoState();
}

class _FormNuevoProductoState extends State<FormNuevoProducto> with GuardarSeccion {
  late String? _categoria = widget.categoriaInicial ?? widget.categorias.firstOrNull?.id;
  final _nombre = TextEditingController();
  final _precio = TextEditingController();
  final _descripcion = TextEditingController();
  FotoElegida _foto = const FotoElegida();

  @override
  void dispose() {
    _nombre.dispose();
    _precio.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  bool get _pideFoto => conFotos(categoriaPorId(widget.categorias, _categoria));

  bool get _listo =>
      _categoria != null &&
      _nombre.text.trim().isNotEmpty &&
      (double.tryParse(_precio.text) ?? 0) > 0 &&
      (!_pideFoto || !_foto.vacia);

  Future<void> _crear() => guardar(
        () async {
          final url = _pideFoto ? await _foto.resolver('menus/${widget.menuCodigo}/productos') : null;
          await LiveEditorService.createProduct(widget.menuCodigo, {
            'categoryId': _categoria,
            'name': _nombre.text.trim(),
            'price': double.parse(_precio.text),
            'description': _descripcion.text.trim(),
            if (url != null && url.isNotEmpty) 'imageUrl': url,
            if (url != null && url.isNotEmpty) 'imagePosition': {'x': _foto.posicion.dx, 'y': _foto.posicion.dy},
            'isVisible': true,
          });
        },
        onListo: widget.onListo,
        mensaje: 'Producto creado',
      );

  @override
  Widget build(BuildContext context) {
    if (widget.categorias.isEmpty) {
      return const Text('Primero crea una categoría desde "Categorías".', style: TextStyle(fontSize: 13));
    }
    void refrescar(_) => setState(() {});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectorCategoria(
          categorias: widget.categorias,
          valor: _categoria,
          onChanged: (c) => setState(() => _categoria = c),
        ),
        if (_pideFoto)
          FotoProducto(
            foto: _foto,
            onCambio: (f) => setState(() => _foto = f),
            ayuda: 'Esta categoría muestra los productos con foto.',
          ),
        CampoTexto(etiqueta: 'Nombre', controller: _nombre, maxLength: 60, requerido: true,
            hint: 'Ej: Hamburguesa doble', onChanged: refrescar),
        CampoTexto(etiqueta: 'Precio', controller: _precio, requerido: true, hint: 'Ej: 18000',
            teclado: const TextInputType.numberWithOptions(decimal: true), onChanged: refrescar),
        CampoTexto(etiqueta: 'Descripción breve', controller: _descripcion, maxLength: 120, maxLines: 2,
            hint: 'Ej: Carne doble, queso cheddar y tocineta'),
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Tamaños, ingredientes, adiciones, grupos y promoción se agregan después desde el "⋯" del producto.',
              style: TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
        ),
        BotonGuardar(texto: 'Crear producto', guardando: guardando, onPressed: _listo ? _crear : null),
      ],
    );
  }
}
