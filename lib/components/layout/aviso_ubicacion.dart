import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../../context/auth_context.dart';

// Equivalente a src/components/layout/AvisoUbicacion.jsx en React.
// Aviso para quien aún no tiene municipio (p. ej. entró con Google): lo completa en su perfil.
// Se muestra sobre las páginas del DashboardLayout (Explorar y la app privada).

bool _muestraAviso(String path) {
  if (path == '/perfil') return false;
  if (path.startsWith('/menu/') || path.startsWith('/preview/')) return false;
  if (path.startsWith('/auth/') || path.startsWith('/invite/')) return false;
  if (path == '/login' || path == '/register') return false;
  return true;
}

class AvisoUbicacion extends StatefulWidget {
  const AvisoUbicacion({
    super.key,
    required this.auth,
    required this.router,
    required this.child,
  });

  final AuthContext auth;
  final GoRouter router;
  final Widget child;

  @override
  State<AvisoUbicacion> createState() => _AvisoUbicacionState();
}

class _AvisoUbicacionState extends State<AvisoUbicacion> {
  late final Listenable _fuentes = Listenable.merge([
    widget.auth,
    widget.router.routerDelegate,
  ]);

  @override
  void initState() {
    super.initState();
    _fuentes.addListener(_cambio);
  }

  @override
  void dispose() {
    _fuentes.removeListener(_cambio);
    super.dispose();
  }

  // El router/auth pueden avisar DURANTE un build (incluido el primer attach, que corre en fase
  // `idle` pero dentro de buildScope). Llamar setState ahí dispara el assert '!_dirty' del SDK nuevo,
  // así que el redibujo siempre se difiere al final del frame (nunca durante el build).
  void _cambio() {
    if (!mounted) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    final router = widget.router;
    final child = widget.child;
    if (router.routerDelegate.currentConfiguration.isEmpty) return child;
    // Ruta superior (incluye las abiertas con push, p. ej. /perfil).
    final path = router.state.matchedLocation;
    if (!auth.isLoggedIn || !auth.requiereUbicacion || !_muestraAviso(path)) {
      return child;
    }
    return Column(
      children: [
        Material(
          color: const Color(0xFFFFFBEB),
          child: SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFFDE68A))),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: Color(0xFF92400E),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Agrega tu municipio para ver lugares y promociones cerca de ti.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => router.push('/perfil'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF92400E),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Completar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // El aviso ya ocupa la barra de estado: la página no debe volver a reservarla.
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
