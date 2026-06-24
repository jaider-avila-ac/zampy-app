import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'app_colors.dart';

// Equivalente a src/modules/subscription/components/WompiCardForm.jsx en React
// Tokeniza la tarjeta directamente contra la API de Wompi (sin intermediario backend).

class WompiCardForm extends StatefulWidget {
  const WompiCardForm({
    super.key,
    required this.wompiBaseUrl,
    required this.publicKey,
    required this.onToken,
    required this.loading,
  });

  final String wompiBaseUrl;
  final String publicKey;
  final void Function(String token) onToken;
  final bool loading;

  @override
  State<WompiCardForm> createState() => _WompiCardFormState();
}

class _WompiCardFormState extends State<WompiCardForm> {
  final _numberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl    = TextEditingController();
  final _nameCtrl   = TextEditingController();

  bool   _busy  = false;
  String _error = '';

  @override
  void dispose() {
    _numberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _rawNumber => _numberCtrl.text.replaceAll(' ', '');
  String get _rawExpiry => _expiryCtrl.text.replaceAll('/', '');

  String? _validate() {
    final num  = _rawNumber;
    final exp  = _rawExpiry;
    final cvv  = _cvvCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (num.length < 13 || num.length > 19) return 'Número de tarjeta inválido';
    if (exp.length != 4) return 'Fecha de vencimiento inválida';
    final month = int.tryParse(exp.substring(0, 2)) ?? 0;
    if (month < 1 || month > 12) return 'Mes inválido';
    if (cvv.length < 3) return 'CVV inválido';
    if (name.isEmpty) return 'Ingresa el nombre del titular';
    return null;
  }

  Future<void> _tokenize() async {
    final err = _validate();
    if (err != null) { setState(() => _error = err); return; }

    setState(() { _busy = true; _error = ''; });
    try {
      final exp   = _rawExpiry;
      final month = exp.substring(0, 2);
      final year  = '20${exp.substring(2, 4)}';

      final url = Uri.parse('${widget.wompiBaseUrl}/tokens/cards');
      final res = await http.post(
        url,
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer ${widget.publicKey}',
        },
        body: jsonEncode({
          'number':      _rawNumber,
          'cvc':         _cvvCtrl.text.trim(),
          'exp_month':   month,
          'exp_year':    year,
          'card_holder': _nameCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 30));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode >= 200 && res.statusCode < 300 && body['data'] != null) {
        final token = (body['data'] as Map<String, dynamic>)['id'] as String;
        widget.onToken(token);
      } else {
        final msgs = _parseWompiError(body);
        setState(() => _error = msgs);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _parseWompiError(Map<String, dynamic> body) {
    try {
      final messages = (body['error']?['messages'] as Map?)?.values;
      if (messages == null) return 'Error al procesar la tarjeta';
      final all = messages
          .expand((v) => v is List ? v.map((e) => e.toString()) : [v.toString()])
          .join('. ');
      return all.isNotEmpty ? all : 'Error al procesar la tarjeta';
    } catch (_) {
      return 'Error al procesar la tarjeta';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = _busy || widget.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardField(
          controller: _numberCtrl,
          label: 'Número de tarjeta',
          hint: '1234 5678 9012 3456',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _CardField(
                controller: _expiryCtrl,
                label: 'Vencimiento',
                hint: 'MM/AA',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryFormatter(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CardField(
                controller: _cvvCtrl,
                label: 'CVV',
                hint: '123',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                obscure: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        _CardField(
          controller: _nameCtrl,
          label: 'Nombre en la tarjeta',
          hint: 'Como aparece en la tarjeta',
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
        ),

        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B))),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isDisabled ? null : _tokenize,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.kBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _busy
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Continuar con esta tarjeta',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

// ── Campo ─────────────────────────────────────────────────────────────────────
class _CardField extends StatelessWidget {
  const _CardField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType       = TextInputType.text,
    this.inputFormatters    = const [],
    this.obscure            = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController  controller;
  final String                 label;
  final String                 hint;
  final TextInputType           keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final bool                   obscure;
  final TextCapitalization     textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569))),
        const SizedBox(height: 6),
        TextField(
          controller:          controller,
          keyboardType:        keyboardType,
          inputFormatters:     inputFormatters,
          obscureText:         obscure,
          textCapitalization:  textCapitalization,
          style: const TextStyle(fontSize: 15, letterSpacing: 0.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
            counterText: '',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.kBlue, width: 1.5)),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

// ── Formatters ────────────────────────────────────────────────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue val) {
    final digits = val.text.replaceAll(' ', '');
    if (digits.length > 16) return old;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return val.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue val) {
    var digits = val.text.replaceAll('/', '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    final text = digits.length > 2
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : digits;
    return val.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
