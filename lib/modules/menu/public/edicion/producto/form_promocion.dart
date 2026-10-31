import 'package:flutter/material.dart';

import '../../../../../services/live_editor_service.dart';
import '../../models/public_menu_model.dart';
import '../comun/guardar.dart';

// Equivalente a src/modules/menu/public/edicion/producto/FormPromocion.jsx en React.

/// Promoción del producto: precio menor al normal y vencimiento opcional.
class FormPromocion extends StatefulWidget {
  const FormPromocion({super.key, required this.menuCodigo, required this.producto, required this.onListo});

  final String menuCodigo;
  final MenuProduct producto;
  final Future<void> Function() onListo;

  @override
  State<FormPromocion> createState() => _FormPromocionState();
}

class _FormPromocionState extends State<FormPromocion> with GuardarSeccion {
  MenuProduct get _p => widget.producto;
  late bool _activa = _p.promoActive;
  late final _precio = TextEditingController(
    text: _p.promoPrice == null ? '' : (_p.promoPrice! == _p.promoPrice!.roundToDouble() ? _p.promoPrice!.toInt().toString() : '${_p.promoPrice}'),
  );
  late DateTime? _vence = _p.promoEndsAt == null ? null : DateTime.tryParse(_p.promoEndsAt!);

  @override
  void dispose() {
    _precio.dispose();
    super.dispose();
  }

  bool get _invalida {
    if (!_activa) return false;
    final v = double.tryParse(_precio.text) ?? 0;
    return !(v > 0 && v < _p.price);
  }

  String _iso(DateTime d) => '${d.toIso8601String().substring(0, 16)}:00';

  Future<void> _elegirVencimiento() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _vence ?? hoy,
      firstDate: hoy,
      lastDate: DateTime(hoy.year + 2),
    );
    if (fecha == null || !mounted) return;
    final hora = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_vence ?? hoy));
    setState(() => _vence = DateTime(fecha.year, fecha.month, fecha.day, hora?.hour ?? 23, hora?.minute ?? 59));
  }

  Future<void> _guardar() => guardar(
        () => LiveEditorService.updateProductPart(
          widget.menuCodigo,
          _p.id,
          'promocion',
          _activa
              ? {'activa': true, 'precio': double.parse(_precio.text), 'vence': _vence == null ? null : _iso(_vence!)}
              : {'activa': false},
        ),
        onListo: widget.onListo,
        mensaje: _activa ? 'Promoción guardada' : 'Promoción desactivada',
      );

  @override
  Widget build(BuildContext context) {
    final normal = _p.price == _p.price.roundToDouble() ? _p.price.toInt().toString() : '${_p.price}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Promoción activa'),
          subtitle: Text('Precio normal: $normal'),
          value: _activa,
          onChanged: (v) => setState(() => _activa = v),
        ),
        if (_activa) ...[
          const SizedBox(height: 8),
          CampoTexto(
            etiqueta: 'Precio de promoción',
            controller: _precio,
            teclado: const TextInputType.numberWithOptions(decimal: true),
            error: _invalida && _precio.text.isNotEmpty ? 'Debe ser menor que el precio normal.' : null,
            onChanged: (_) => setState(() {}),
          ),
          OutlinedButton.icon(
            onPressed: _elegirVencimiento,
            icon: const Icon(Icons.event_outlined, size: 16),
            label: Text(_vence == null
                ? 'Vence (opcional)'
                : 'Vence: ${_vence!.day}/${_vence!.month}/${_vence!.year} ${_vence!.hour.toString().padLeft(2, '0')}:${_vence!.minute.toString().padLeft(2, '0')}'),
          ),
          if (_vence != null)
            TextButton(onPressed: () => setState(() => _vence = null), child: const Text('Quitar vencimiento')),
        ],
        const SizedBox(height: 12),
        BotonGuardar(guardando: guardando, onPressed: _invalida ? null : _guardar),
      ],
    );
  }
}
