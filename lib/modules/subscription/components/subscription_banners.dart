import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../services/suscripcion_service.dart';
import '../../../shared/app_colors.dart';
import '../utils/sus_format.dart';

// Equivalente a src/modules/menu/editor/tabs/publish/SubscriptionBanners.jsx en React.
// React lee `acciones` de menu.subscription, que el backend no envía (los avisos nunca salen);
// aquí se pide la suscripción del menú (GET /suscripciones/menus/{codigo}), que sí trae `acciones`.

class SubscriptionBanners extends StatefulWidget {
  const SubscriptionBanners({super.key, required this.menuCodigo});
  final String menuCodigo;

  @override
  State<SubscriptionBanners> createState() => _SubscriptionBannersState();
}

class _SubscriptionBannersState extends State<SubscriptionBanners> {
  Map<String, dynamic>? _sus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SubscriptionBanners old) {
    super.didUpdateWidget(old);
    if (old.menuCodigo != widget.menuCodigo) _load();
  }

  Future<void> _load() async {
    try {
      final sus = await SuscripcionService.getMiSuscripcion(widget.menuCodigo);
      if (mounted) setState(() => _sus = sus);
    } catch (_) {
      // Sin avisos si no se puede consultar: la pestaña sigue funcionando.
    }
  }

  @override
  Widget build(BuildContext context) {
    final sus = _sus;
    if (sus == null) return const SizedBox.shrink();
    final ac = (sus['acciones'] as Map?) ?? const {};
    final minutos = asInt(sus['minutosRestantes']) ?? 0;
    final tiempo = fmtTiempo(asInt(sus['diasRestantes']), minutos);
    void irBilling() => context.push('/billing/${widget.menuCodigo}');

    final banners = <Widget>[
      if (ac['mostrarBannerActivo'] == true)
        _Aviso(
          icon: Icons.star_outline,
          fg: const Color(0xFF3730A3),
          bg: const Color(0xFFEEF2FF),
          border: const Color(0xFFE0E7FF),
          titulo:
              'Prueba gratuita activa${minutos > 0 ? ' · $tiempo restantes' : ''}',
          texto:
              'Tu menú está publicado. Podrás adquirir un plan cuando se active la ventana de aviso.',
        ),
      if (ac['mostrarBannerAviso'] == true)
        _Aviso(
          icon: Icons.shopping_cart_outlined,
          fg: AppColors.kTextPrimary,
          bg: const Color(0xFFF8FAFC),
          border: const Color(0xFFCBD5E1),
          titulo: 'Ventana de aviso — $tiempo restantes',
          texto:
              'Tu suscripción está próxima a vencer. Actúa ahora para no perder la publicación.',
          accion: ac['mostrarBotonComprar'] == true
              ? 'Adquirir →'
              : ac['mostrarBotonRenovar'] == true
              ? 'Renovar →'
              : null,
          onAccion: irBilling,
        ),
      if (ac['mostrarBannerGracia'] == true)
        _Aviso(
          icon: Icons.autorenew,
          fg: AppColors.kTextPrimary,
          bg: const Color(0xFFF8FAFC),
          border: const Color(0xFF94A3B8),
          titulo: 'Período de gracia — $tiempo restantes',
          texto:
              'Renueva ahora y mantén tu precio actual. Si se suspende, deberás contratar al precio vigente.',
          accion: ac['mostrarBotonRenovar'] == true ? 'Renovar →' : null,
          onAccion: irBilling,
        ),
      if (sus['estado'] == 'WAITING_ACTIVATION')
        const _Aviso(
          icon: Icons.schedule,
          fg: Color(0xFF3730A3),
          bg: Color(0xFFEEF2FF),
          border: Color(0xFFC7D2FE),
          titulo: 'Pago aprobado — activando suscripción',
          texto:
              'Tu pago fue confirmado. Estamos activando tu menú automáticamente. Recarga en unos segundos.',
        ),
    ];
    if (banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final b in banners)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: b),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icon,
    required this.fg,
    required this.bg,
    required this.border,
    required this.titulo,
    required this.texto,
    this.accion,
    this.onAccion,
  });

  final IconData icon;
  final Color fg;
  final Color bg;
  final Color border;
  final String titulo;
  final String texto;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (accion != null)
            TextButton(
              onPressed: onAccion,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.kTextPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                accion!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
