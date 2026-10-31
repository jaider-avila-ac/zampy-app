import 'package:flutter/material.dart';

import '../../../../services/pedido_service.dart';
import '../../../../shared/app_colors.dart';
import '../../hooks/pagina_cursor.dart' show mensaje;
import '../../models/cuenta_mesa.dart';
import '../../utils/formato.dart';
import '../comun/hoja_formulario.dart';

/// Cargo o descuento auditado sobre una cuenta: queda registrado con su motivo, sin alterar la cuenta original.
/// Se crea al abrir, así el formulario y el requestId (evita duplicar si se reintenta) arrancan limpios.
class AjusteCuentaSheet extends StatefulWidget {
  const AjusteCuentaSheet({super.key, required this.menu, required this.cuenta});

  final String menu;
  final CuentaMesa cuenta;

  @override
  State<AjusteCuentaSheet> createState() => _AjusteCuentaSheetState();
}

class _AjusteCuentaSheetState extends State<AjusteCuentaSheet> {
  final _form = GlobalKey<FormState>();
  final _valor = TextEditingController();
  final _motivo = TextEditingController();
  final _requestId = PedidoService.nuevoRequestId('ajuste');
  String _tipo = 'CARGO';
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _valor.dispose();
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_form.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await PedidoService.crearAjusteCuenta(widget.menu, widget.cuenta.codigo,
          tipo: _tipo, valor: num.parse(_valor.text.trim()), motivo: _motivo.text.trim(), requestId: _requestId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = mensaje(e, 'No se pudo registrar el ajuste.'));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
        key: _form,
        child: HojaFormulario(
          titulo: 'Ajuste financiero',
          subtitulo: '${widget.cuenta.mesaNombre} · Total actual ${precio(widget.cuenta.total)}',
          children: [
            const Etiqueta('Tipo'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'CARGO', label: Text('Cargo adicional')),
                ButtonSegment(value: 'DESCUENTO', label: Text('Descuento')),
              ],
              selected: {_tipo},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            const SizedBox(height: 8),
            const Etiqueta('Valor'),
            TextFormField(
              controller: _valor,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: decoracionCampo(prefijo: '\$ '),
              validator: (v) {
                final n = num.tryParse((v ?? '').trim());
                return n == null || n < 0.01 ? 'Escribe un valor mayor que 0.' : null;
              },
            ),
            const SizedBox(height: 8),
            const Etiqueta('Motivo obligatorio'),
            TextFormField(
              controller: _motivo,
              minLines: 3,
              maxLines: 5,
              maxLength: 300,
              decoration: decoracionCampo(hint: 'Explica por qué se realiza este ajuste'),
              validator: (v) => (v ?? '').trim().length < 5 ? 'El motivo debe tener al menos 5 caracteres.' : null,
            ),
            if (_error != null) Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.kRed)),
            const SizedBox(height: 12),
            BotonGuardar(texto: 'Registrar sin alterar la cuenta original', guardando: _guardando, onPressed: _guardar),
          ],
        ),
      );
}
