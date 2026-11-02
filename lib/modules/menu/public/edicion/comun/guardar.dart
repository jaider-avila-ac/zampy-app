import 'package:flutter/material.dart';

import '../../../../../shared/app_colors.dart';

// Equivalente a src/modules/menu/public/edicion/hooks/useGuardar.js en React.

String mensajeError(Object e) {
  final m = e.toString().replaceFirst('Exception: ', '');
  return m.isEmpty ? 'Intenta de nuevo.' : m;
}

void avisar(BuildContext context, String mensaje, {bool error = false}) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
    content: Text(mensaje),
    backgroundColor: error ? AppColors.kRed : AppColors.kBlue,
    behavior: SnackBarBehavior.floating,
  ));
}

/// Guarda una sección del menú desde un formulario: avisa el resultado y, si salió bien, llama a onListo (recargar el
/// menú y cerrar el panel).
mixin GuardarSeccion<T extends StatefulWidget> on State<T> {
  bool guardando = false;

  Future<void> guardar(
    Future<void> Function() fn, {
    required Future<void> Function() onListo,
    String mensaje = 'Cambios guardados',
  }) async {
    setState(() => guardando = true);
    try {
      await fn();
      if (mounted) avisar(context, mensaje);
      await onListo();
    } catch (e) {
      if (mounted) avisar(context, 'No se pudo guardar: ${mensajeError(e)}', error: true);
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }
}

/// Botón principal de los formularios del panel.
class BotonGuardar extends StatelessWidget {
  const BotonGuardar({super.key, required this.onPressed, this.guardando = false, this.texto = 'Guardar'});

  final VoidCallback? onPressed;
  final bool guardando;
  final String texto;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 46,
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.kBlue),
          onPressed: guardando ? null : onPressed,
          child: guardando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(texto),
        ),
      );
}

/// Campo de texto con etiqueta, igual en todos los formularios del panel.
class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.etiqueta,
    required this.controller,
    this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.teclado,
    this.requerido = false,
    this.error,
    this.onChanged,
  });

  final String etiqueta;
  final TextEditingController controller;
  final String? hint;
  final int? maxLength;
  final int maxLines;
  final TextInputType? teclado;
  final bool requerido;
  final String? error;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          keyboardType: teclado,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: requerido ? '$etiqueta *' : etiqueta,
            hintText: hint,
            errorText: error,
            counterText: '',
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
}

/// Título de un bloque dentro de un formulario.
class TituloBloque extends StatelessWidget {
  const TituloBloque(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Text(texto, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.kTextPrimary)),
      );
}

const cargandoPanel = Padding(
  padding: EdgeInsets.symmetric(vertical: 32),
  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
);
