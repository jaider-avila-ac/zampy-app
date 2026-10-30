import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/app_colors.dart';

class DeleteMenuModal extends StatefulWidget {
  const DeleteMenuModal({
    super.key,
    required this.menuName,
    required this.confirmWord,
    required this.onDelete,
  });

  final String menuName;
  final String confirmWord;
  final Future<void> Function(String code) onDelete;

  static Future<bool?> show(
    BuildContext context, {
    required String menuName,
    required String confirmWord,
    required Future<void> Function(String code) onDelete,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteMenuModal(
        menuName: menuName,
        confirmWord: confirmWord,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<DeleteMenuModal> createState() => _DeleteMenuModalState();
}

class _DeleteMenuModalState extends State<DeleteMenuModal> {
  final _controller = TextEditingController();
  bool _deleting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canDelete =>
      !_deleting && _controller.text.trim() == widget.confirmWord;

  Future<void> _confirm() async {
    if (!_canDelete) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await widget.onDelete(widget.confirmWord);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _deleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Eliminar menú',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: AppColors.kTextPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.kTextSecondary,
                ),
                children: [
                  const TextSpan(text: 'Vas a eliminar '),
                  TextSpan(
                    text: widget.menuName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.kTextPrimary,
                    ),
                  ),
                  const TextSpan(
                    text:
                        '. Se borrarán el menú, sus imágenes y todos los datos asociados. ',
                  ),
                  const TextSpan(
                    text: 'Esta acción no se puede deshacer.',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.kRed,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.kCardBorder),
              ),
              child: Column(
                children: [
                  const Text(
                    'Escribe exactamente esta palabra para confirmar:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      widget.confirmWord,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: AppColors.kRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                      LengthLimitingTextInputFormatter(
                        widget.confirmWord.length,
                      ),
                      _UpperCaseFormatter(),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Escribe la palabra aquí',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.kTextMuted,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF87171)),
                      ),
                      counterText: '',
                    ),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(fontSize: 12, color: AppColors.kRed),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _canDelete ? _confirm : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.kRed,
            disabledBackgroundColor: const Color(0xFFFCA5A5),
          ),
          child: _deleting
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: Colors.white,
                  ),
                )
              : const Text('Eliminar definitivamente'),
        ),
      ],
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
