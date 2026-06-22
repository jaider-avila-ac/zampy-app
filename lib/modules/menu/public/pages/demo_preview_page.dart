import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../hooks/use_public_menu.dart';
import '../../../../components/menu_page.dart';
import '../../../../shared/app_colors.dart';

// Equivalente a src/pages/DemoPreviewPage.jsx en React
// Muestra el menú demo (/preview/demo) cargado con datos estáticos de fallback

class DemoPreviewPage extends StatelessWidget {
  const DemoPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UsePublicMenu()..load(isDemo: true),
      child: const _DemoView(),
    );
  }
}

class _DemoView extends StatelessWidget {
  const _DemoView();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UsePublicMenu>();

    if (ctrl.loading) {
      return const Scaffold(
        backgroundColor: AppColors.kBgPage,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (ctrl.menuData == null) {
      return const Scaffold(
        backgroundColor: AppColors.kBgPage,
        body: Center(child: Text('Error al cargar demo')),
      );
    }

    return Scaffold(
      backgroundColor: ctrl.menuData!.theme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Banner "DEMO" + botón cerrar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF7C3AED),
              child: Row(
                children: [
                  const Icon(Icons.visibility, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Vista previa del menú demo',
                      style: TextStyle(color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: MenuPage(
                menuData: ctrl.menuData!,
                isPublished: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
