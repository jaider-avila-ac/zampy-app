import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/geography_service.dart';
import 'app_colors.dart';

class TelefonoInput extends StatefulWidget {
  const TelefonoInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.paisDefecto = 'CO',
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? label;
  final String? hint;
  final String paisDefecto;

  @override
  State<TelefonoInput> createState() => _TelefonoInputState();
}

class _TelefonoInputState extends State<TelefonoInput> {
  final _numberCtrl = TextEditingController();
  List<GeoPais> _paises = [];
  GeoPais? _pais;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPaises();
  }

  @override
  void didUpdateWidget(covariant TelefonoInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _syncFromValue();
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPaises() async {
    try {
      final paises = await GeographyService.getPaisesCatalogo();
      if (!mounted) return;
      setState(() {
        _paises = paises;
        _loading = false;
        _syncFromValue();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _syncFromValue() {
    final (pais, numero) = _separar(widget.value, _paises);
    _pais =
        pais ??
        _paises.cast<GeoPais?>().firstWhere(
          (p) => p?.codigo == widget.paisDefecto,
          orElse: () => _paises.cast<GeoPais?>().firstWhere(
            (p) => p?.codigo == 'CO',
            orElse: () => _paises.isEmpty ? null : _paises.first,
          ),
        );
    if (_numberCtrl.text != numero) {
      _numberCtrl.text = numero;
      _numberCtrl.selection = TextSelection.collapsed(
        offset: _numberCtrl.text.length,
      );
    }
  }

  void _emit() {
    final digits = _numberCtrl.text.replaceAll(RegExp(r'\D'), '');
    final indicativo = _pais?.indicativo ?? '';
    widget.onChanged(digits.isEmpty ? '' : '$indicativo $digits'.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.kTextSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _pais?.codigo,
                  hint: Text(_loading ? '…' : 'País'),
                  isDense: true,
                  items: _paises
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.codigo,
                          child: Text(
                            '${p.codigo} ${p.indicativo}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _loading
                      ? null
                      : (codigo) {
                          final pais = _paises.firstWhere(
                            (p) => p.codigo == codigo,
                            orElse: () => _paises.first,
                          );
                          setState(() => _pais = pais);
                          _emit();
                        },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _numberCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                onChanged: (_) => _emit(),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.hint ?? '300 000 0000',
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.kBlue,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  (GeoPais?, String) _separar(String valor, List<GeoPais> paises) {
    final texto = valor.trim();
    if (!texto.startsWith('+')) {
      return (null, texto.replaceAll(RegExp(r'\D'), ''));
    }
    final digitos = texto.replaceAll(RegExp(r'\D'), '');
    final candidatos =
        paises
            .where(
              (p) =>
                  p.indicativo.isNotEmpty &&
                  digitos.startsWith(
                    p.indicativo.replaceAll(RegExp(r'\D'), ''),
                  ),
            )
            .toList()
          ..sort((a, b) => b.indicativo.length.compareTo(a.indicativo.length));
    if (candidatos.isEmpty) return (null, digitos);
    final pais = candidatos.first;
    final indicativo = pais.indicativo.replaceAll(RegExp(r'\D'), '');
    return (pais, digitos.substring(indicativo.length));
  }
}
