import 'package:flutter/material.dart';

import '../../../../services/mesa_service.dart';
import '../../../../services/pedido_service.dart';
import '../../../../shared/app_colors.dart';
import '../../../orders/components/comun/hoja_formulario.dart';
import '../../../orders/hooks/pagina_cursor.dart' show mensaje;
import '../../../orders/models/cuenta_mesa.dart';
import '../../../orders/utils/formato.dart';

const _medios = {'EFECTIVO': 'Efectivo', 'TARJETA': 'Tarjeta', 'TRANSFERENCIA': 'Transferencia', 'OTRO': 'Otro'};

/// Abono del mesero a la cuenta (sugiere el saldo). Si falla, el error se ve aquí y la hoja sigue abierta.
class AbonoSheet extends StatefulWidget {
  const AbonoSheet({super.key, required this.menu, required this.mesa, required this.cuenta});

  final String menu;
  final String mesa;
  final CuentaMesa cuenta;

  @override
  State<AbonoSheet> createState() => _AbonoSheetState();
}

class _AbonoSheetState extends State<AbonoSheet> {
  final _form = GlobalKey<FormState>();
  late final num _saldo = widget.cuenta.saldoPendiente;
  late final _valor = TextEditingController(text: _saldo % 1 == 0 ? _saldo.toInt().toString() : '$_saldo');
  final _requestId = PedidoService.nuevoRequestId('pago');
  String _medio = 'EFECTIVO';
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_form.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await MesaService.registrarAbono(widget.menu, widget.mesa, widget.cuenta.codigo,
          requestId: _requestId, medio: _medio, valor: num.parse(_valor.text.trim()));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = mensaje(e, 'No se pudo registrar el abono. Verifica el saldo.'));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
        key: _form,
        child: HojaFormulario(
          titulo: 'Registrar abono',
          subtitulo: 'Saldo: ${precio(_saldo)}',
          children: [
            const Etiqueta('Medio de pago'),
            DropdownButtonFormField<String>(
              initialValue: _medio,
              decoration: decoracionCampo(),
              items: [for (final e in _medios.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (v) => setState(() => _medio = v ?? _medio),
            ),
            const SizedBox(height: 8),
            const Etiqueta('Valor'),
            TextFormField(
              controller: _valor,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: decoracionCampo(prefijo: '\$ '),
              validator: (v) {
                final n = num.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return 'Escribe un valor mayor que 0.';
                if (n > _saldo) return 'No puede superar el saldo (${precio(_saldo)}).';
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.kRed)),
            ],
            const SizedBox(height: 14),
            BotonGuardar(texto: 'Confirmar abono', guardando: _guardando, onPressed: _guardar, color: const Color(0xFF4F46E5)),
          ],
        ),
      );
}
