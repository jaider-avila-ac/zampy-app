import 'package:flutter/material.dart' hide MenuTheme;

import '../../../mesero/hooks/use_orden_mesero.dart';
import '../models/public_menu_model.dart';

/// Franja superior del menú cuando el mesero toma la orden de una mesa (vuelve a sus mesas con la flecha).
class BannerOrdenMesero extends StatelessWidget {
  const BannerOrdenMesero({super.key, required this.orden, required this.onVolver});

  final UseOrdenMesero orden;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: orden,
        builder: (context, _) => Container(
          color: const Color(0xFF0F172A),
          padding: const EdgeInsets.fromLTRB(4, 2, 16, 2),
          child: Row(children: [
            IconButton(
              onPressed: onVolver,
              tooltip: 'Volver a mesas',
              icon: const Icon(Icons.arrow_back, size: 18, color: Color(0xFFCBD5E1)),
            ),
            const Icon(Icons.assignment_outlined, size: 15, color: Color(0xFFFBBF24)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Tomando orden para ${orden.destino.mesaNombre}${orden.destino.nuevaCuenta ? ' · cuenta nueva' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ]),
        ),
      );
}

/// Botón flotante "La orden · N" (solo con productos agregados).
class BotonOrdenMesero extends StatelessWidget {
  const BotonOrdenMesero({super.key, required this.orden, required this.theme, required this.onPressed});

  final UseOrdenMesero orden;
  final MenuTheme theme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: orden,
        builder: (context, _) => orden.cantidad == 0
            ? const SizedBox.shrink()
            : FloatingActionButton.extended(
                heroTag: 'orden-mesero',
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                onPressed: onPressed,
                icon: const Icon(Icons.assignment_outlined),
                label: Text('La orden · ${orden.cantidad}'),
              ),
      );
}
