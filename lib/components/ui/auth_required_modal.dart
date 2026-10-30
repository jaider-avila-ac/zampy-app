import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_redirect.dart';
import '../../shared/app_colors.dart';

Future<void> showAuthRequiredDialog(
  BuildContext context, {
  String returnTo = '/',
}) async {
  final goLogin = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'Inicia sesión',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
      content: const Text(
        'Necesitas una cuenta para guardar lo que te encanta.',
        style: TextStyle(fontSize: 14, color: AppColors.kTextSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.kBlue),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Iniciar sesión'),
        ),
      ],
    ),
  );

  if (goLogin != true || !context.mounted) return;
  AuthRedirect.remember(returnTo);
  context.push('/login');
}
