import 'package:flutter/material.dart';

import '../../../../../services/live_editor_service.dart';
import '../../../../../shared/app_colors.dart';
import '../../models/public_menu_model.dart';
import '../comun/guardar.dart';
import 'opciones_producto.dart';

// Equivalente a src/modules/menu/public/edicion/producto/FormOpciones.jsx en React.

class _Fila {
  _Fila({this.id, String label = '', String precio = '', String cantidad = ''})
      : label = TextEditingController(text: label),
        precio = TextEditingController(text: precio),
        cantidad = TextEditingController(text: cantidad);
  final String? id;
  final TextEditingController label;
  final TextEditingController precio;
  final TextEditingController cantidad;

  void dispose() {
    label.dispose();
    precio.dispose();
    cantidad.dispose();
  }
}

String _precioTexto(double p) => p == 0 ? '' : (p == p.roundToDouble() ? p.toInt().toString() : '$p');

/// tipo: tamanos | ingredientes | adiciones
class FormOpciones extends StatefulWidget {
  const FormOpciones({
    super.key,
    required this.menuCodigo,
    required this.producto,
    required this.tipo,
    required this.onListo,
  });

  final String menuCodigo;
  final MenuProduct producto;
  final String tipo;
  final Future<void> Function() onListo;

  @override
  State<FormOpciones> createState() => _FormOpcionesState();
}

class _FormOpcionesState extends State<FormOpciones> with GuardarSeccion {
  OpcionProducto get _opcion => opcionesProducto[widget.tipo]!;
  late final List<_Fila> _filas = _inicial();
  late final TextEditingController _titulo =
      TextEditingController(text: widget.producto.cantidadTitulo ?? '');

  List<_Fila> _inicial() {
    final p = widget.producto;
    return switch (widget.tipo) {
      'tamanos' => [for (final s in p.sizes) _Fila(id: s.id, label: s.label, precio: _precioTexto(s.price))],
      'cantidades' => [for (final s in p.cantidades) _Fila(id: s.id, label: s.label, precio: _precioTexto(s.price), cantidad: s.cantidad?.toString() ?? '')],
      'ingredientes' => [for (final m in p.ingredients) _Fila(id: m.id, label: m.label, precio: _precioTexto(m.price))],
      _ => [for (final m in p.extras) _Fila(id: m.id, label: m.label, precio: _precioTexto(m.price))],
    };
  }

  @override
  void dispose() {
    for (final f in _filas) {
      f.dispose();
    }
    _titulo.dispose();
    super.dispose();
  }

  Future<void> _guardar() {
    final items = [
      for (final f in _filas)
        if (f.label.text.trim().isNotEmpty)
          {
            if (f.id != null && f.id!.isNotEmpty) 'id': f.id,
            'label': f.label.text.trim(),
            'price': _opcion.conPrecio ? (double.tryParse(f.precio.text) ?? 0) : 0,
            if (_opcion.conCantidad)
              'cantidad': (int.tryParse(f.cantidad.text) ?? 0) > 0 ? int.parse(f.cantidad.text) : null,
          },
    ];
    // La sección "Cantidad" guarda además su título; las demás van como lista simple.
    final Object body = _opcion.conTitulo
        ? {'titulo': _titulo.text.trim().isEmpty ? null : _titulo.text.trim(), 'items': items}
        : items;
    return guardar(
      () => LiveEditorService.updateProductPart(widget.menuCodigo, widget.producto.id, widget.tipo, body),
      onListo: widget.onListo,
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_opcion.ayuda, style: const TextStyle(fontSize: 13, color: AppColors.kTextSecondary)),
          const SizedBox(height: 12),
          if (_opcion.conTitulo) ...[
            CampoTexto(
              etiqueta: 'Título de la sección',
              hint: 'Ej: Cantidad de ingredientes',
              controller: _titulo,
              maxLength: 40,
            ),
            const SizedBox(height: 12),
          ],
          for (var i = 0; i < _filas.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CampoTexto(etiqueta: 'Nombre', hint: _opcion.placeholder, controller: _filas[i].label, maxLength: 60),
                ),
                if (_opcion.conPrecio) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: CampoTexto(
                      etiqueta: 'Precio',
                      controller: _filas[i].precio,
                      teclado: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
                if (_opcion.conCantidad) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 72,
                    child: CampoTexto(
                      etiqueta: 'Cant.',
                      controller: _filas[i].cantidad,
                      teclado: TextInputType.number,
                    ),
                  ),
                ],
                IconButton(
                  tooltip: 'Quitar',
                  onPressed: () => setState(() => _filas.removeAt(i).dispose()),
                  icon: const Icon(Icons.delete_outline, size: 18),
                ),
              ],
            ),
          OutlinedButton.icon(
            onPressed: _filas.length >= _opcion.max
                ? null
                : () => setState(() => _filas.add(_Fila())),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Agregar'),
          ),
          // El aviso solo aparece al acercarse al tope
          if (_opcion.max - _filas.length <= 2)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _filas.length >= _opcion.max
                    ? 'Llegaste al máximo (${_opcion.max}).'
                    : 'Puedes agregar ${_opcion.max - _filas.length} más.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted),
              ),
            ),
          const SizedBox(height: 12),
          BotonGuardar(guardando: guardando, onPressed: _guardar),
        ],
      );
}
