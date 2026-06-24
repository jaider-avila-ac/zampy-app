import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'modules/explore/pages/explore_page.dart';
import 'modules/menu/public/pages/public_menu_page.dart';
import 'modules/menu/public/pages/demo_preview_page.dart';
import 'modules/notifications/pages/notifications_page.dart';
import 'modules/growth/achievements/pages/logros_page.dart';
import 'modules/growth/invitations/pages/invitaciones_page.dart';
import 'modules/auth/pages/login_page.dart';
import 'modules/auth/pages/register_page.dart';
import 'modules/auth/pages/verify_email_code_page.dart';
import 'modules/auth/pages/forgot_password_page.dart';
import 'modules/auth/pages/reset_password_page.dart';
import 'shared/app_colors.dart';
import 'modules/profile/pages/settings_page.dart';
import 'modules/profile/pages/profile_page.dart';
import 'modules/dashboard/pages/mis_menus_page.dart';
import 'modules/menu/public/pages/preview_page.dart';
import 'modules/menu/editor/stats/pages/estadisticas_page.dart';
import 'modules/menu/editor/pages/menu_editor_page.dart';
import 'modules/menu/editor/pages/menu_info_page.dart';
import 'modules/menu/editor/pages/product_form_page.dart';
import 'modules/menu/create/create_menu_page.dart';
import 'modules/subscription/pages/suscripcion_page.dart';
import 'modules/subscription/pages/suscripcion_overview_page.dart';
import 'modules/subscription/pages/suscripcion_detail_page.dart';
import 'modules/subscription/pages/planes_page.dart';
import 'modules/subscription/pages/checkout_page.dart';
import 'modules/about/pages/about_page.dart';

// Equivalente a src/App.jsx + src/router/ en React
// Rutas Fase 1 + Fase 2

// RouteObserver global — permite que _ExploreViewState detecte cuando el usuario
// vuelve al explorador desde otra pantalla y haga refetch en background
final routeObserver = RouteObserver<ModalRoute<void>>();

final _router = GoRouter(
  observers:       [routeObserver],
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
    GoRoute(
      path: '/preview/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return PreviewPage(menuId: id);
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/menus',
      builder: (context, state) => const MisMenusPage(),
    ),
    GoRoute(
      path: '/menus/new',
      builder: (context, state) => const CreateMenuPage(),
    ),
    GoRoute(
      path: '/menus/:id/estadisticas',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return EstadisticasPage(menuId: id);
      },
    ),
    GoRoute(
      path: '/menus/:id/edit',
      builder: (context, state) {
        final id  = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        final tab = state.uri.queryParameters['tab'];
        return MenuEditorPage(menuId: id, initialTab: tab);
      },
    ),
    GoRoute(
      path: '/menus/:id/info',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return MenuInfoPage(menuId: id);
      },
    ),
    GoRoute(
      path: '/menus/:id/products/new',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return ProductFormPage(menuId: id);
      },
    ),
    GoRoute(
      path: '/menus/:id/products/:pid',
      builder: (context, state) {
        final id  = int.tryParse(state.pathParameters['id']  ?? '') ?? 0;
        final pid = state.pathParameters['pid'] ?? '';
        return ProductFormPage(menuId: id, productId: pid);
      },
    ),
    GoRoute(
      path: '/logros',
      builder: (context, state) => const LogrosPage(),
    ),
    GoRoute(
      path: '/invitaciones',
      builder: (context, state) => const InvitacionesPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/suscripcion',
      builder: (context, state) => const SuscripcionOverviewPage(),
    ),
    GoRoute(
      path: '/perfil',
      builder: (context, state) => const ProfilePage(),
    ),
    // ── Planes de suscripción ─────────────────────────────────────────────
    GoRoute(
      path: '/menus/:id/planes',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return PlanesPage(menuId: id);
      },
    ),

    // ── Suscripción / Billing ──────────────────────────────────────────────
    // IMPORTANTE: /billing/sus/:susId debe ir ANTES de /billing/:menuId
    // para que el segmento literal "sus" tenga prioridad.
    GoRoute(
      path: '/billing/sus/:susId',
      builder: (context, state) {
        final susId = int.tryParse(state.pathParameters['susId'] ?? '') ?? 0;
        return SuscripcionDetailPage(susId: susId);
      },
    ),
    GoRoute(
      path: '/billing/:menuId',
      builder: (context, state) {
        final menuId = int.tryParse(state.pathParameters['menuId'] ?? '') ?? 0;
        return SuscripcionPage(menuId: menuId);
      },
      routes: [
        GoRoute(
          path: 'checkout',
          builder: (context, state) {
            final menuId = int.tryParse(state.pathParameters['menuId'] ?? '') ?? 0;
            final q      = state.uri.queryParameters;
            return CheckoutPage(
              menuId: menuId,
              tipo:   q['tipo'] ?? 'checkout',
              plan:   q['plan'],
            );
          },
        ),
      ],
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
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutPage(),
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
