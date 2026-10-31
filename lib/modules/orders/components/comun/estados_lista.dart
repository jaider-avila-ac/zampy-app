import 'package:flutter/material.dart';

import '../../../../shared/app_colors.dart';

// Piezas de estado compartidas por las pestañas de pedidos y cuentas.

class CargandoLista extends StatelessWidget {
  const CargandoLista({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 72),
        child: Center(child: CircularProgressIndicator(color: AppColors.kBlue, strokeWidth: 2.5)),
      );
}

class ListaVacia extends StatelessWidget {
  const ListaVacia({super.key, required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 16),
        child: Column(
          children: [
            Icon(icono, size: 40, color: AppColors.kTextMuted.withValues(alpha: 0.45)),
            const SizedBox(height: 10),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.kTextMuted),
            ),
          ],
        ),
      );
}

class ErrorLista extends StatelessWidget {
  const ErrorLista(this.mensaje, {super.key});

  final String mensaje;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(mensaje, style: const TextStyle(fontSize: 12, color: AppColors.kRed)),
      );
}

class CargarMasBoton extends StatelessWidget {
  const CargarMasBoton({super.key, required this.hayMas, required this.cargando, required this.onPressed});

  final bool hayMas;
  final bool cargando;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (!hayMas) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: OutlinedButton(
          onPressed: cargando ? null : onPressed,
          child: cargando
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Cargar más'),
        ),
      ),
    );
  }
}

/// Tarjeta blanca con borde, el contenedor de las listas.
class TarjetaLista extends StatelessWidget {
  const TarjetaLista({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kCardBorder),
        ),
        child: Column(children: children),
      );
}
