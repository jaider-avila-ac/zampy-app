import 'package:flutter/material.dart';

// Pantalla de splash animada — se muestra como overlay sobre ExplorePage
// mientras no hay datos cacheados. Si hay caché, nunca se muestra.
//
// SIN animación de entrada: el logo arranca a tamaño completo para que
// la transición desde el splash nativo de Android sea imperceptible.
// Solo hay pulso suave mientras carga y fade-out al terminar.

class SplashOverlay extends StatefulWidget {
  const SplashOverlay({
    super.key,
    required this.loading,
    required this.noInternet,
    required this.onDismissed,
    required this.onRetry,
  });

  final bool         loading;
  final bool         noInternet;
  final VoidCallback onDismissed;
  final VoidCallback onRetry;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;

  double _opacity = 1.0;
  bool   _exiting = false;

  // Mismo color que en flutter_native_splash + styles.xml → transición invisible
  static const _bg = Color(0xFF0F172A); // slate-950

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant SplashOverlay old) {
    super.didUpdateWidget(old);
    if (!widget.loading && !widget.noInternet && !_exiting) {
      _startExit();
    }
  }

  void _startExit() {
    _exiting = true;
    _pulseCtrl.stop();
    setState(() => _opacity = 0.0);
    Future.delayed(const Duration(milliseconds: 420), () {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 380),
      child: IgnorePointer(
        ignoring: _exiting,
        child: Material(
          color: _bg,
          child: Align(
            alignment: Alignment.center,
            child: widget.noInternet
                ? _NoInternetContent(onRetry: widget.onRetry)
                : _LoadingContent(pulseCtrl: _pulseCtrl, pulseAnim: _pulseAnim),
          ),
        ),
      ),
    );
  }
}

// ── Contenido de carga ────────────────────────────────────────────────────────

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({
    required this.pulseCtrl,
    required this.pulseAnim,
  });

  final AnimationController pulseCtrl;
  final Animation<double>   pulseAnim;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo: mismo ícono de la app, sin animación de entrada para que
        // el paso desde el splash nativo sea invisible
        AnimatedBuilder(
          animation: pulseCtrl,
          builder: (_, child) => Transform.scale(
            scale: pulseAnim.value,
            child: child,
          ),
          child: Image.asset(
            'assets/logos/Zammpy-logo-fondo-azul.png',
            width: 120,
            height: 120,
          ),
        ),
        const SizedBox(height: 44),
        // Indicador de carga sutil
        SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Colors.white.withValues(alpha: 0.40),
            strokeWidth: 2,
          ),
        ),
      ],
    );
  }
}

// ── Sin conexión a internet ───────────────────────────────────────────────────

class _NoInternetContent extends StatelessWidget {
  const _NoInternetContent({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 56,
            color: Colors.white.withValues(alpha: 0.50),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sin conexión a internet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize:   18,
              fontWeight: FontWeight.w700,
              color:      Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Verifica tu conexión e intenta de nuevo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color:    Colors.white.withValues(alpha: 0.55),
              height:   1.4,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                color:        Colors.white.withValues(alpha: 0.10),
                border:       Border.all(color: Colors.white.withValues(alpha: 0.22)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Reintentar',
                    style: TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                      color:      Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
