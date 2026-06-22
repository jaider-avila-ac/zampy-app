import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'modules/explore/pages/explore_page.dart';
import 'modules/menu/public/pages/public_menu_page.dart';
import 'modules/menu/public/pages/demo_preview_page.dart';
import 'modules/auth/pages/login_page.dart';
import 'modules/auth/pages/register_page.dart';
import 'modules/auth/pages/verify_email_code_page.dart';
import 'modules/auth/pages/forgot_password_page.dart';
import 'modules/auth/pages/reset_password_page.dart';
import 'shared/app_colors.dart';

// Equivalente a src/App.jsx + src/router/ en React
// Rutas Fase 1 + Fase 2

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    // ── Fase 1: explorador y menú público ──────────────────────────────────
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

    // ── Fase 2: autenticación ───────────────────────────────────────────────
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final q           = state.uri.queryParameters;
        final registered  = q['registered'] == 'true';
        final verified    = q['verified']   == 'true';
        final oauthError  = q['oauthError'];
        return LoginPage(
          registered: registered,
          verified:   verified,
          oauthError: oauthError,
        );
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/auth/verify-code',
      builder: (context, state) {
        // El email se pasa como extra desde RegisterPage
        final email = state.extra as String? ?? '';
        return VerifyEmailCodePage(email: email);
      },
    ),
    GoRoute(
      path: '/auth/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/auth/reset-password',
      builder: (context, state) => const ResetPasswordPage(),
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
