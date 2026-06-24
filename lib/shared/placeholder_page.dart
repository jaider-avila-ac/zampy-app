import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_colors.dart';
import 'app_header.dart';

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) {
        if (GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
        } else {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.kBgPage,
        appBar: AppHeader(title: title),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction_outlined, size: 40, color: AppColors.kTextMuted),
              SizedBox(height: 12),
              Text(
                'Próximamente',
                style: TextStyle(
                  fontSize:   16,
                  fontWeight: FontWeight.w700,
                  color:      AppColors.kTextPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Esta sección está en desarrollo.',
                style: TextStyle(fontSize: 13, color: AppColors.kTextMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
