import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'modules/explore/pages/explore_page.dart';
import 'modules/menu/public/pages/public_menu_page.dart';
import 'modules/menu/public/pages/demo_preview_page.dart';
import 'modules/auth/pages/login_page.dart';
import 'shared/app_colors.dart';

// Equivalente a src/App.jsx + src/router/ en React
// Configura go_router con las rutas de la Fase 1

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ExplorePage(),
    ),
    GoRoute(
      path: '/menu/:slug',
      builder: (context, state) {
        final slug = state.pathParameters['slug']!;
        return PublicMenuPage(slug: slug);
      },
    ),
    GoRoute(
      path: '/preview/demo',
      builder: (context, state) => const DemoPreviewPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
  ],
);

class ZammpyApp extends StatelessWidget {
  const ZammpyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Zammpy',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        colorSchemeSeed: AppColors.kBlue,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
    );
  }
}
