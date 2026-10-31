import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../services/mesa_service.dart';
import '../../../../shared/app_colors.dart';
import '../../../orders/components/comun/hoja_formulario.dart';
import '../../../orders/hooks/pagina_cursor.dart' show mensaje;
import 'mesa_model.dart';

/// Crear (mesa null) o editar una mesa. Se crea al abrir, así arranca con los datos de la mesa. Devuelve la mesa
/// guardada.
class MesaFormSheet extends StatefulWidget {
  const MesaFormSheet({super.key, required this.menu, this.mesa});

  final String menu;
  final Mesa? mesa;

  @override
  State<MesaFormSheet> createState() => _MesaFormSheetState();
}

class _MesaFormSheetState extends State<MesaFormSheet> {
  late final _nombre = TextEditingController(text: widget.mesa?.nombre ?? '');
  late final _capacidad = TextEditingController(text: widget.mesa?.capacidad?.toString() ?? '');
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _capacidad.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty || _guardando) return;
    final capacidad = int.tryParse(_capacidad.text.trim());
    if (capacidad != null && (capacidad < 1 || capacidad > 100)) {
      setState(() => _error = 'La capacidad debe estar entre 1 y 100 personas.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final json = widget.mesa == null
          ? await MesaService.crear(widget.menu, nombre: nombre, capacidad: capacidad)
          : await MesaService.actualizar(widget.menu, widget.mesa!.codigo, nombre: nombre, capacidad: capacidad);
      if (mounted) Navigator.pop(context, Mesa.fromJson(json));
    } catch (e) {
      if (mounted) setState(() => _error = mensaje(e, 'No se pudo guardar'));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => HojaFormulario(
        titulo: widget.mesa == null ? 'Nueva mesa' : 'Editar mesa',
        children: [
          const Etiqueta('Nombre *'),
          TextField(
            controller: _nombre,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() => _error = null),
            decoration: decoracionCampo(hint: 'Mesa 1, VIP, Terraza...'),
          ),
          const SizedBox(height: 8),
          const Etiqueta('Capacidad (personas, opcional)'),
          TextField(
            controller: _capacidad,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
            decoration: decoracionCampo(hint: '4'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.kRed)),
          ],
          const SizedBox(height: 16),
          ValueListenableBuilder(
            valueListenable: _nombre,
            builder: (_, valor, _) => BotonGuardar(
              texto: widget.mesa == null ? 'Crear' : 'Guardar',
              guardando: _guardando,
              onPressed: valor.text.trim().isEmpty ? null : _guardar,
            ),
          ),
        ],
      );
}
