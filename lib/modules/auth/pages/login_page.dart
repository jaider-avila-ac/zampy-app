import 'package:flutter/material.dart';
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
                Text('Zammpy',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                      color: AppColors.kBlue,
                      letterSpacing: -1,
                    )),
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
