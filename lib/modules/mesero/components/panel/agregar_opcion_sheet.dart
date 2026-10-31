import 'package:flutter/material.dart';

import '../../../../shared/app_colors.dart';
import '../../../../shared/responsive.dart';

/// Con una cuenta abierta, "Agregar" pregunta si es para esa cuenta o para una nueva separada (dividir mesa).
/// Devuelve true = cuenta nueva, false = esta cuenta, null = nada.
Future<bool?> elegirDestinoOrden(BuildContext context) => showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      constraints: hojaConstraints(context, maxWidth: 440),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        Widget opcion(bool nueva, IconData icono, String titulo, String desc) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.kCardBorder),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onTap: () => Navigator.pop(ctx, nueva),
                  leading: Icon(icono, color: AppColors.kBlue),
                  title: Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
                ),
              ),
            );
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12, left: 4),
                child: Text('¿Qué quieres agregar?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              opcion(false, Icons.playlist_add, 'Agregar a esta cuenta', 'Más platos para la misma cuenta ya abierta.'),
              opcion(true, Icons.person_add_alt, 'Nueva cuenta (dividir mesa)',
                  'Para otra persona/grupo que paga aparte en la misma mesa.'),
            ],
          ),
        );
      },
    );
