import 'package:flutter/material.dart';

import '../../../shared/app_colors.dart';

// Equivalente a src/modules/explore/components/AccionesTarjeta.jsx en React

class AccionesTarjeta extends StatelessWidget {
  const AccionesTarjeta({
    super.key,
    required this.encanta,
    required this.conSesion,
    required this.onVerMas,
    required this.onEncanta,
    required this.onRequireLogin,
  });

  final bool encanta;
  final bool conSesion;
  final VoidCallback onVerMas;
  final VoidCallback onEncanta;
  final VoidCallback onRequireLogin;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Más opciones',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 180),
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.more_horiz,
          size: 17,
          color: AppColors.kTextPrimary,
        ),
      ),
      onSelected: (value) {
        if (value == 'ver') {
          onVerMas();
        } else if (value == 'encanta') {
          if (!conSesion) {
            onRequireLogin();
          } else {
            onEncanta();
          }
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'ver',
          child: Row(
            children: [
              Icon(
                Icons.open_in_new,
                size: 16,
                color: AppColors.kTextSecondary,
              ),
              SizedBox(width: 8),
              Text('Ver más', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'encanta',
          child: Row(
            children: [
              Icon(
                encanta ? Icons.favorite : Icons.favorite_border,
                size: 16,
                color: encanta
                    ? const Color(0xFFE11D48)
                    : AppColors.kTextSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                encanta ? 'Te encanta' : 'Me encanta',
                style: TextStyle(
                  fontSize: 13,
                  color: encanta
                      ? const Color(0xFFE11D48)
                      : AppColors.kTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
