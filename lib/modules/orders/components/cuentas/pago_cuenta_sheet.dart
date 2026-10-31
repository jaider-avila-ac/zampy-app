import 'package:flutter/material.dart';

import '../../../../services/pedido_service.dart';
import '../../../../shared/app_colors.dart';
import '../../hooks/pagina_cursor.dart' show mensaje;
import '../../models/cuenta_mesa.dart';
import '../../utils/formato.dart';
import '../comun/hoja_formulario.dart';

const _medios = {'EFECTIVO': 'Efectivo', 'TARJETA': 'Tarjeta', 'TRANSFERENCIA': 'Transferencia', 'OTRO': 'Otro'};

/// Concilia el saldo de una cuenta con un movimiento auditado: cobro pendiente (saldo a favor del negocio) o
/// devolución (saldo negativo, con motivo obligatorio). Sugiere el saldo como valor.
class PagoCuentaSheet extends StatefulWidget {
  const PagoCuentaSheet({super.key, required this.menu, required this.cuenta});

  final String menu;
  final CuentaMesa cuenta;

  @override
  State<PagoCuentaSheet> createState() => _PagoCuentaSheetState();
}

class _PagoCuentaSheetState extends State<PagoCuentaSheet> {
  final _form = GlobalKey<FormState>();
  late final num _saldo = widget.cuenta.saldoPendiente;
  late final bool _esAbono = _saldo >= 0;
  late final _valor = TextEditingController(text: _saldo % 1 == 0 ? _saldo.abs().toInt().toString() : _saldo.abs().toString());
  final _motivo = TextEditingController();
  final _requestId = PedidoService.nuevoRequestId('pago');
  String _medio = 'EFECTIVO';
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
      final motivo = _motivo.text.trim();
      await PedidoService.crearMovimientoPagoCuenta(widget.menu, widget.cuenta.codigo,
          tipo: _esAbono ? 'ABONO' : 'REVERSO',
          medio: _medio,
          valor: num.parse(_valor.text.trim()),
          motivo: motivo.isEmpty ? null : motivo,
          requestId: _requestId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = mensaje(e, 'No se pudo registrar el movimiento.'));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
        key: _form,
        child: HojaFormulario(
          titulo: _esAbono ? 'Registrar cobro pendiente' : 'Registrar devolución',
          subtitulo: 'Saldo: ${precio(_saldo)}',
          children: [
            const Etiqueta('Medio'),
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
                if (n == null || n < 0.01) return 'Escribe un valor mayor que 0.';
                if (n > _saldo.abs()) return 'No puede superar el saldo (${precio(_saldo.abs())}).';
                return null;
              },
            ),
            if (!_esAbono) ...[
              const SizedBox(height: 8),
              const Etiqueta('Motivo obligatorio de la devolución'),
              TextFormField(
                controller: _motivo,
                minLines: 2,
                maxLines: 4,
                maxLength: 300,
                decoration: decoracionCampo(),
                validator: (v) => (v ?? '').trim().length < 5 ? 'El motivo debe tener al menos 5 caracteres.' : null,
              ),
            ],
            if (_error != null) Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.kRed)),
            const SizedBox(height: 12),
            BotonGuardar(
              texto: 'Registrar movimiento auditado',
              guardando: _guardando,
              onPressed: _guardar,
              color: const Color(0xFF059669),
            ),
          ],
        ),
      );
}
