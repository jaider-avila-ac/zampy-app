import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../services/pedido_service.dart';
import '../../../../shared/app_colors.dart';
import '../../hooks/pagina_cursor.dart' show mensaje;
import '../../utils/formato.dart';

/// Lo que el cliente pagó por un pedido entregado (lo registra el negocio; Zammpy no gestiona pagos).
class ValorPagado extends StatelessWidget {
  const ValorPagado({super.key, required this.codigo, required this.valorActual, required this.onGuardado});

  final String codigo;
  final num? valorActual;
  final ValueChanged<num> onGuardado;

  Future<void> _editar(BuildContext context) async {
    final valor = await showDialog<num>(
      context: context,
      builder: (_) => _ValorPagadoDialog(codigo: codigo, valorActual: valorActual),
    );
    if (valor != null) onGuardado(valor);
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: () => _editar(context),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.kTextMuted,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          minimumSize: Size.zero,
          textStyle: const TextStyle(fontSize: 12),
        ),
        icon: const Icon(Icons.attach_money, size: 14),
        label: valorActual == null
            ? const Text('Registrar pago')
            : Text.rich(TextSpan(children: [
                const TextSpan(text: 'Pagado: '),
                TextSpan(
                  text: precio(valorActual),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.kTextPrimary),
                ),
              ])),
      );
}

class _ValorPagadoDialog extends StatefulWidget {
  const _ValorPagadoDialog({required this.codigo, required this.valorActual});

  final String codigo;
  final num? valorActual;

  @override
  State<_ValorPagadoDialog> createState() => _ValorPagadoDialogState();
}

class _ValorPagadoDialogState extends State<_ValorPagadoDialog> {
  late final _ctrl = TextEditingController(text: widget.valorActual?.round().toString() ?? '');
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final valor = num.tryParse(_ctrl.text.trim());
    if (valor == null || valor < 0) {
      setState(() => _error = 'Escribe un valor válido.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await PedidoService.registrarValorPagado(widget.codigo, valor);
      if (mounted) Navigator.pop(context, valor);
    } catch (e) {
      if (mounted) setState(() => _error = mensaje(e, 'No se pudo guardar.'));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Valor pagado', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _guardar(),
              decoration: const InputDecoration(prefixText: '\$ ', hintText: '0'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.kRed)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: _guardando ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: _guardando ? null : _guardar,
            style: FilledButton.styleFrom(backgroundColor: AppColors.kBlue),
            child: _guardando
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Guardar'),
          ),
        ],
      );
}
