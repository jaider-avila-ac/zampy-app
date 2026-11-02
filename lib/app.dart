import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'components/layout/aviso_ubicacion.dart';
import 'context/auth_context.dart';
import 'modules/about/pages/about_page.dart';
import 'modules/auth/pages/forgot_password_page.dart';
import 'modules/auth/pages/invite_page.dart';
import 'modules/auth/pages/login_page.dart';
import 'modules/auth/pages/register_page.dart';
import 'modules/auth/pages/reset_password_page.dart';
import 'modules/auth/pages/verify_email_code_page.dart';
import 'modules/auth/pages/verify_email_sent_page.dart';
import 'modules/dashboard/pages/menu_hub_page.dart';
import 'modules/dashboard/pages/mis_menus_page.dart';
import 'modules/explore/pages/explore_page.dart';
import 'modules/growth/achievements/pages/logros_page.dart';
import 'modules/growth/invitations/pages/invitaciones_page.dart';
import 'modules/menu/create/create_menu_page.dart';
import 'modules/menu/editor/live/menu_editor_live_page.dart';
import 'modules/menu/editor/info/menu_info_page.dart';
import 'modules/menu/editor/mesas/mesas_page.dart';
import 'modules/menu/editor/stats/pages/estadisticas_page.dart';
import 'modules/menu/public/pages/demo_preview_page.dart';
import 'modules/menu/public/pages/public_menu_page.dart';
import 'modules/mesero/pages/mesero_page.dart';
import 'modules/repartidor/pages/repartidor_page.dart';
import 'modules/mesero/utils/tomar_orden.dart';
import 'modules/notifications/pages/notifications_page.dart';
import 'modules/orders/pages/menu_pedidos_page.dart';
import 'modules/orders/pages/pedidos_page.dart';
import 'modules/profile/pages/profile_page.dart';
import 'modules/profile/pages/settings_page.dart';
import 'modules/subscription/pages/checkout_page.dart';
import 'modules/subscription/pages/planes_page.dart';
import 'modules/subscription/pages/suscripcion_detail_page.dart';
import 'modules/subscription/pages/suscripcion_overview_page.dart';
import 'modules/subscription/pages/suscripcion_page.dart';
import 'services/auth_redirect.dart';
import 'shared/app_colors.dart';

// Solo PageRoute: así el "silentRefresh" al volver a Explorar se dispara con navegaciones de
// página reales, NO al cerrar un popup/menú (⋯) o un diálogo (que también son ModalRoute).
final routeObserver = RouteObserver<PageRoute<void>>();

bool _isPublicPath(String path) {
  if (path == '/' || path == '/explore' || path == '/about') return true;
  if (path == '/preview/demo') return true;
  if (path.startsWith('/menu/')) return true;
  if (path.startsWith('/invite/')) return true;
  if (path == '/login' || path == '/register') return true;
  if (path == '/auth/verify-sent' ||
      path == '/auth/verify-code' ||
      path == '/auth/forgot-password' ||
      path == '/auth/reset-password') {
    return true;
  }
  return false;
}

bool _isGuestPath(String path) {
  return path == '/login' || path == '/register' || path.startsWith('/invite/');
}

GoRouter _buildRouter(AuthContext auth) {
  return GoRouter(
    observers: [routeObserver],
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.matchedLocation;

      if (auth.loading) {
        if (_isPublicPath(path)) return null;
        AuthRedirect.remember(state.uri.toString());
        return '/login';
      }

      final loggedIn = auth.isLoggedIn;

      if (!loggedIn && !_isPublicPath(path)) {
        AuthRedirect.remember(state.uri.toString());
        return '/login';
      }

      if (loggedIn && _isGuestPath(path)) {
        return AuthRedirect.consume() ?? '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const ExplorePage()),
      GoRoute(
        path: '/explore',
        builder: (context, state) => const ExplorePage(),
      ),
      GoRoute(
        path: '/menu/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          final query = state.uri.queryParameters;
          return PublicMenuPage(
            slug: slug,
            staffMode: query['staff'] == '1',
            initialProductId: query['producto'],
            editar: query['editar'],
            mesero: DestinoOrden.deQuery(query),
          );
        },
      ),
      GoRoute(
        path: '/preview/demo',
        builder: (context, state) => const DemoPreviewPage(),
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
        path: '/menus/:codigo',
        builder: (context, state) =>
            MenuHubPage(codigo: state.pathParameters['codigo'] ?? ''),
      ),
      GoRoute(
        path: '/menus/:codigo/estadisticas',
        builder: (context, state) =>
            EstadisticasPage(menuId: state.pathParameters['codigo'] ?? ''),
      ),
      GoRoute(
        path: '/menus/:codigo/edit',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          return LiveMenuEditorPage(
            codigo: state.pathParameters['codigo'] ?? '',
            initialTab: tab,
          );
        },
      ),
      // La información completa del menú (como MenuInfoPage de React); ?paso=horario abre en el horario.
      // Los productos ya no tienen pantalla propia: se crean y editan en el propio menú.
      GoRoute(
        path: '/menus/:codigo/info',
        builder: (context, state) => MenuInfoPage(
          codigo: state.pathParameters['codigo'] ?? '',
          enfocarHorario: state.uri.queryParameters['paso'] == 'horario',
        ),
      ),
      // pedidos y mesas del negocio (dueño o editor)
      GoRoute(
        path: '/menus/:codigo/pedidos',
        builder: (context, state) => MenuPedidosPage(codigo: state.pathParameters['codigo'] ?? ''),
      ),
      GoRoute(
        path: '/menus/:codigo/mesas',
        builder: (context, state) => MesasPage(codigo: state.pathParameters['codigo'] ?? ''),
      ),
      GoRoute(
        path: '/mesero/:codigo',
        builder: (context, state) => MeseroPage(codigo: state.pathParameters['codigo'] ?? ''),
      ),
      GoRoute(
        path: '/repartidor/:codigo',
        builder: (context, state) => RepartidorPage(codigo: state.pathParameters['codigo'] ?? ''),
      ),
      GoRoute(path: '/logros', builder: (context, state) => const LogrosPage()),
      GoRoute(path: '/pedidos', builder: (context, state) => const PedidosPage()),
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
      // Menús y suscripciones se identifican por su código público (texto).
      GoRoute(
        path: '/menus/:codigo/planes',
        builder: (context, state) =>
            PlanesPage(menuId: state.pathParameters['codigo'] ?? ''),
      ),
      GoRoute(
        path: '/billing/sus/:susId',
        builder: (context, state) =>
            SuscripcionDetailPage(
              susId: state.pathParameters['susId'] ?? '',
              wompiTxId: state.uri.queryParameters['id'],
            ),
      ),
      GoRoute(
        path: '/billing/:menuId',
        builder: (context, state) =>
            SuscripcionPage(
              menuId: state.pathParameters['menuId'] ?? '',
              wompiTxId: state.uri.queryParameters['id'],
            ),
        routes: [
          GoRoute(
            path: 'checkout',
            builder: (context, state) {
              final menuId = state.pathParameters['menuId'] ?? '';
              final q = state.uri.queryParameters;
              return CheckoutPage(
                menuId: menuId,
                tipo: q['tipo'] ?? 'checkout',
                plan: q['plan'],
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return LoginPage(
            registered: q['registered'] == 'true',
            verified: q['verified'] == 'true',
            resetSuccess: q['resetSuccess'] == 'true',
            verifyError: q['verifyError'],
            oauthError: q['error'],
          );
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/invite/:code',
        builder: (context, state) {
          return InvitePage(code: state.pathParameters['code'] ?? '');
        },
      ),
      GoRoute(
        path: '/auth/verify-code',
        builder: (context, state) {
          final extra = state.extra;
          final email = extra is Map
              ? (extra['email']?.toString() ?? '')
              : (extra as String? ?? '');
          final fresh = extra is Map
              ? extra['fresh'] == true
              : state.uri.queryParameters['fresh'] == 'true';
          return VerifyEmailCodePage(email: email, fresh: fresh);
        },
      ),
      GoRoute(
        path: '/auth/verify-sent',
        builder: (context, state) {
          final extra = state.extra;
          final email = extra is Map
              ? extra['email']?.toString()
              : extra as String?;
          return VerifyEmailSentPage(email: email);
        },
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/auth/reset-password',
        builder: (context, state) {
          final extra = state.extra;
          final email = extra is Map
              ? extra['email']?.toString()
              : extra as String?;
          return ResetPasswordPage(email: email);
        },
      ),
      GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
    ],
  );
}

class ZammpyApp extends StatefulWidget {
  const ZammpyApp({super.key, required this.auth});

  final AuthContext auth;

  @override
  State<ZammpyApp> createState() => _ZammpyAppState();
}

class _ZammpyAppState extends State<ZammpyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter(widget.auth);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Zammpy',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      builder: (context, child) => AvisoUbicacion(
        auth: widget.auth,
        router: _router,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: ThemeData(
        colorSchemeSeed: AppColors.kBlue,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
    );
  }
}
