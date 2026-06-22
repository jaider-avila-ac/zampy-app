import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/app_colors.dart';

// Equivalente a src/pages/LoginPage.jsx en React
// Fase 2 — placeholder: redirige al explorador mientras se implementa la autenticación

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/logos/imagotipo-indigo-zammpy.svg',
                  height: 40,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF4A37F2), BlendMode.srcIn),
                ),
                const SizedBox(height: 8),
                Text('Próximamente — Fase 2',
                    style: TextStyle(fontSize: 13, color: AppColors.kTextMuted)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.kBlue),
                    onPressed: () => context.go('/'),
                    child: const Text('Volver al explorador'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
