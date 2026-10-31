import 'package:flutter/material.dart';

import 'app_colors.dart';

// Diálogo de confirmación compartido (equivale a ConfirmModal de React).

class Confirmacion {
  const Confirmacion(this.titulo, this.descripcion, this.boton, {this.peligro = false});

  final String titulo;
  final String descripcion;
  final String boton;
  final bool peligro; // acción destructiva: botón en rojo
}

/// Devuelve true si se confirma.
Future<bool> confirmar(BuildContext context, Confirmacion c, {String cancelar = 'Cancelar'}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(c.titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      content: Text(c.descripcion, style: const TextStyle(fontSize: 14, color: AppColors.kTextSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancelar)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: c.peligro ? AppColors.kRed : AppColors.kBlue),
          child: Text(c.boton),
        ),
      ],
    ),
  );
  return ok == true;
}
