import 'package:flutter/material.dart';

import '../../../../../services/live_editor_service.dart';
import '../../../../../shared/app_colors.dart';
import '../comun/guardar.dart';
import 'tema_elegido.dart';

// Equivalente a src/modules/menu/public/edicion/tema/PruebaTema.jsx en React.

/// El menú ya se ve con el tema elegido (todavía sin guardar): el dueño lo aprecia completo y decide si lo deja, elige
/// otro o vuelve al que tenía.
class PruebaTema extends StatefulWidget {
  const PruebaTema({
    super.key,
    required this.menuCodigo,
    required this.tema,
    required this.nombre,
    required this.onVolver,
    required this.onElegirOtro,
    required this.onGuardado,
  });

  final String menuCodigo;
  final TemaElegido tema;

  /// "Estilo · Paleta" del tema que se está probando.
  final String nombre;
  final VoidCallback onVolver;
  final VoidCallback onElegirOtro;
  final Future<void> Function() onGuardado;

  @override
  State<PruebaTema> createState() => _PruebaTemaState();
}

class _PruebaTemaState extends State<PruebaTema> {
  bool _guardando = false;

  Future<void> _dejar() async {
    setState(() => _guardando = true);
    try {
      await LiveEditorService.saveSection(widget.menuCodigo, 'diseno', {
        'skinId': widget.tema.skin,
        'paletteId': widget.tema.paleta,
      });
      if (mounted) avisar(context, 'Tema guardado. Tu menú ya se ve así para tus clientes.');
      await widget.onGuardado();
    } catch (e) {
      if (mounted) avisar(context, 'No se pudo guardar el tema: ${mensajeError(e)}', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Material(
        elevation: 12,
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 13, color: AppColors.kTextSecondary),
                    children: [
                      const TextSpan(text: '¿Te gusta cómo queda? ', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.kTextPrimary)),
                      TextSpan(text: 'Así se verá tu menú con ${widget.nombre}.'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _guardando ? null : widget.onVolver,
                      icon: const Icon(Icons.undo, size: 16),
                      label: const Text('Volver al anterior'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _guardando ? null : widget.onElegirOtro,
                      icon: const Icon(Icons.palette_outlined, size: 16),
                      label: const Text('Elegir otro'),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.kBlue),
                      onPressed: _guardando ? null : _dejar,
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(_guardando ? 'Guardando…' : 'Dejar este tema'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
