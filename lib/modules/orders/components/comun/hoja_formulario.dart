import 'package:flutter/material.dart';

import '../../../../shared/app_colors.dart';
import '../../../../shared/responsive.dart';

/// Abre una hoja inferior que sube con el teclado y en tablet no ocupa todo el ancho. Devuelve true si se guardó.
Future<bool> mostrarHoja(BuildContext context, Widget hoja) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: hojaConstraints(context),
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom), child: hoja),
  );
  return ok == true;
}

/// Título, subtítulo y contenido con scroll de una hoja de formulario.
class HojaFormulario extends StatelessWidget {
  const HojaFormulario({super.key, required this.titulo, this.subtitulo, required this.children});

  final String titulo;
  final String? subtitulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.kTextPrimary)),
                      if (subtitulo != null)
                        Text(subtitulo!, style: const TextStyle(fontSize: 12, color: AppColors.kTextSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close, size: 20, color: AppColors.kTextMuted),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );
}

/// Etiqueta de campo.
class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 4),
        child: Text(texto, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.kTextSecondary)),
      );
}

InputDecoration decoracionCampo({String? hint, String? prefijo}) => InputDecoration(
      hintText: hint,
      prefixText: prefijo,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );

/// Botón principal de la hoja, con spinner mientras guarda.
class BotonGuardar extends StatelessWidget {
  const BotonGuardar({super.key, required this.texto, required this.guardando, required this.onPressed, this.color = AppColors.kBlue});

  final String texto;
  final bool guardando;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 46,
        child: FilledButton(
          onPressed: guardando ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: guardando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(texto, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
}
