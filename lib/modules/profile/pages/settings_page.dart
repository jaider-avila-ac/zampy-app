import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // context.push('/perfil')
import 'package:provider/provider.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/app_header.dart';
import '../../../components/layout/sidebar.dart';
import '../hooks/use_settings.dart';

// Equivalente a src/modules/profile/pages/SettingsPage.jsx en React
// + toggle de notificaciones push (funcionalidad exclusiva móvil)

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UseSettings()..load(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UseSettings>();

    return Scaffold(
      backgroundColor: AppColors.kBgPage,
      drawer: const AppSidebar(),
      appBar: const AppHeader(title: 'Ajustes'),
      body: RefreshIndicator(
        color: AppColors.kBlue,
        onRefresh: ctrl.recargarDisp,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [

            // ── Header ─────────────────────────────────────────────────────
            const Text('Ajustes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                    color: AppColors.kTextPrimary)),
            const SizedBox(height: 2),
            const Text('Gestiona tu cuenta y sesiones activas',
                style: TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
            const SizedBox(height: 20),

            // ── Perfil ──────────────────────────────────────────────────────
            _ProfileButton(onTap: () => context.push('/perfil')),
            const SizedBox(height: 20),

            // ── Notificaciones push (nueva — exclusivo móvil) ───────────────
            _NotifToggle(ctrl: ctrl),
            const SizedBox(height: 20),

            // ── Código de invitación ────────────────────────────────────────
            _InvCodeSection(ctrl: ctrl),
            const SizedBox(height: 20),

            // ── Sesiones activas ────────────────────────────────────────────
            _SessionsSection(ctrl: ctrl),
          ],
        ),
      ),
    );
  }
}

// ── Perfil ────────────────────────────────────────────────────────────────────

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: AppColors.kCardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_circle_outlined,
                size: 20, color: AppColors.kBlue),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mi perfil',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.kTextPrimary)),
                  Text('Edita tu nombre, foto y datos personales',
                      style: TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.kTextMuted),
          ],
        ),
      ),
    );
  }
}

// ── Toggle de notificaciones push ─────────────────────────────────────────────

class _NotifToggle extends StatelessWidget {
  const _NotifToggle({required this.ctrl});
  final UseSettings ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:        ctrl.notifEnabled
                      ? AppColors.kBlue.withValues(alpha: 0.12)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  ctrl.notifEnabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  size: 18,
                  color: ctrl.notifEnabled ? AppColors.kBlue : AppColors.kTextMuted,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notificaciones push',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppColors.kTextPrimary)),
                    Text('Recibe alertas aunque la app esté cerrada',
                        style: TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
                  ],
                ),
              ),
              Switch(
                value:          ctrl.notifEnabled,
                activeThumbColor: AppColors.kBlue,
                onChanged: (_) async {
                  final granted = await ctrl.toggleNotificaciones(context);
                  if (!granted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Permiso denegado. Actívalo desde los ajustes del sistema.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          if (ctrl.notifEnabled) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:        const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 12, color: AppColors.kBlue),
                  SizedBox(width: 5),
                  Text('Notificaciones activas',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppColors.kBlue)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Código de invitación ──────────────────────────────────────────────────────

class _InvCodeSection extends StatelessWidget {
  const _InvCodeSection({required this.ctrl});
  final UseSettings ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Código de invitación',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.kTextPrimary)),
        const SizedBox(height: 4),
        const Text(
          'Comparte este código para que alguien te agregue como colaborador o te transfiera uno de sus menús.',
          style: TextStyle(fontSize: 11, color: AppColors.kTextMuted, height: 1.4),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: AppColors.kCardBorder),
          ),
          child: Row(
            children: [
              if (ctrl.codigoInv != null) ...[
                Expanded(
                  child: Text(
                    ctrl.codigoInv!,
                    style: const TextStyle(
                      fontFamily:  'monospace',
                      fontSize:    22,
                      fontWeight:  FontWeight.w900,
                      letterSpacing: 6,
                      color:       AppColors.kBlue,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: ctrl.copiarCodigo,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:        ctrl.copied
                          ? const Color(0xFFD1FAE5)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ctrl.copied ? Icons.check : Icons.copy_outlined,
                          size:  13,
                          color: ctrl.copied
                              ? const Color(0xFF065F46)
                              : AppColors.kTextMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          ctrl.copied ? 'Copiado' : 'Copiar',
                          style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                            color:      ctrl.copied
                                ? const Color(0xFF065F46)
                                : AppColors.kTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                Container(
                  height: 28,
                  width:  140,
                  decoration: BoxDecoration(
                    color:        AppColors.kSkeleton,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Sesiones activas ──────────────────────────────────────────────────────────

class _SessionsSection extends StatelessWidget {
  const _SessionsSection({required this.ctrl});
  final UseSettings ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sesiones activas',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.kTextPrimary)),
                  SizedBox(height: 2),
                  Text('Dispositivos con sesión iniciada',
                      style: TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
                ],
              ),
            ),
            GestureDetector(
              onTap: ctrl.recargarDisp,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:        const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh_rounded,
                    size: 16, color: AppColors.kTextMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (ctrl.loading)
          ...[1, 2].map((_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color:        AppColors.kSkeleton,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ))
        else if (ctrl.loadError)
          _ErrorCard(onRetry: ctrl.recargarDisp)
        else if (ctrl.dispositivos.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(16),
              border:       Border.all(color: AppColors.kCardBorder),
            ),
            child: const Text('No hay sesiones activas.',
                style: TextStyle(fontSize: 13, color: AppColors.kTextMuted)),
          )
        else
          ...ctrl.dispositivos.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SessionCard(
              d:        d,
              revoking: ctrl.revoking,
              onRevoke: () async {
                try {
                  await ctrl.revocar(d['id'].toString());
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo cerrar esa sesión. Intenta de nuevo.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          )),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.d,
    required this.revoking,
    required this.onRevoke,
  });

  final Map<String, dynamic> d;
  final String?              revoking;
  final VoidCallback         onRevoke;

  static IconData _deviceIcon(String? ua) {
    if (ua == null) return Icons.monitor_outlined;
    final s = ua.toLowerCase();
    if (s.contains('mobile') || s.contains('android') || s.contains('iphone')) {
      return Icons.smartphone_outlined;
    }
    return Icons.monitor_outlined;
  }

  static String _parseBrowser(String? ua) {
    if (ua == null) return 'Dispositivo desconocido';
    if (ua.contains('Chrome') && !ua.contains('Edg')) return 'Chrome';
    if (ua.contains('Firefox')) return 'Firefox';
    if (ua.contains('Safari') && !ua.contains('Chrome')) return 'Safari';
    if (ua.contains('Edg')) return 'Edge';
    if (ua.contains('Opera') || ua.contains('OPR')) return 'Opera';
    return 'Navegador';
  }

  static String _parseOS(String? ua) {
    if (ua == null) return '';
    if (ua.contains('Windows')) return 'Windows';
    if (ua.contains('Mac OS')) return 'macOS';
    if (ua.contains('Android')) return 'Android';
    if (ua.contains('iPhone') || ua.contains('iPad')) return 'iOS';
    if (ua.contains('Linux')) return 'Linux';
    return '';
  }

  static String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
      return '${dt.day.toString().padLeft(2,'0')} ${months[dt.month-1]} ${dt.year} '
             '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ua       = d['nombre'] as String?;
    final esEste   = d['esEste'] as bool? ?? false;
    final navegando = d['navegando'] as bool? ?? false;
    final ip       = d['ip'] as String? ?? 'IP desconocida';
    final creadoEn = _formatDate(d['creadoEn'] as String?);
    final browser  = _parseBrowser(ua);
    final os       = _parseOS(ua);
    final label    = os.isNotEmpty ? '$browser · $os' : browser;
    final isRevoking = revoking == d['id'].toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        esEste ? const Color(0xFFEEF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(
          color: esEste ? const Color(0xFFC7D2FE) : AppColors.kCardBorder,
        ),
      ),
      child: Row(
        children: [
          // Ícono dispositivo
          Container(
            width: 40, height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:        esEste
                  ? const Color(0xFFE0E7FF)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _deviceIcon(ua),
              size:  20,
              color: esEste ? AppColors.kBlue : AppColors.kTextMuted,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 5, runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(label,
                        style: const TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          color:      AppColors.kTextPrimary,
                        )),
                    if (esEste)
                      _Chip(label: 'Este dispositivo',
                          bg: AppColors.kBlue, text: Colors.white),
                    if (navegando)
                      _Chip(
                        label: '● Activo',
                        bg:    const Color(0xFFD1FAE5),
                        text:  const Color(0xFF065F46),
                      )
                    else
                      _Chip(
                        label: 'Inactivo',
                        bg:    const Color(0xFFF1F5F9),
                        text:  AppColors.kTextMuted,
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$ip · Iniciado $creadoEn',
                  style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Botón revocar (solo en otros dispositivos)
          if (!esEste) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isRevoking ? null : onRevoke,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:        const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isRevoking
                    ? const SizedBox(
                        width: 15, height: 15,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.kTextMuted),
                      )
                    : const Icon(Icons.delete_outline,
                        size: 15, color: AppColors.kTextMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.bg, required this.text});
  final String label;
  final Color  bg;
  final Color  text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: text)),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:        const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Text('No se pudieron cargar las sesiones.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: Color(0xFFB91C1C))),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onRetry,
            child: const Text('Reintentar',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626),
                    decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }
}
