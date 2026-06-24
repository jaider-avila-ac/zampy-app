import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../hooks/use_invitaciones.dart';
import '../../../../shared/app_colors.dart';
import '../../../../shared/app_header.dart';
import '../../../../components/layout/sidebar.dart';

// Equivalente a src/modules/growth/invitations/pages/InvitacionesPage.jsx

class InvitacionesPage extends StatelessWidget {
  const InvitacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UseInvitaciones()..load(),
      child: const _InvitacionesView(),
    );
  }
}

class _InvitacionesView extends StatelessWidget {
  const _InvitacionesView();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UseInvitaciones>();

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
        drawer: const AppSidebar(),
        appBar: const AppHeader(title: 'Invitaciones'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtítulo
              const Text(
                'Invita personas y gana días gratis al completar logros',
                style: TextStyle(fontSize: 12, color: AppColors.kTextMuted),
              ),
              const SizedBox(height: 20),

              // Cargando
              if (ctrl.loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: CircularProgressIndicator(color: AppColors.kBlue),
                  ),
                )

              // Error
              else if (ctrl.error.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:        const Color(0xFFFEF2F2),
                    border:       Border.all(color: const Color(0xFFFECACA)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(ctrl.error,
                      style: const TextStyle(fontSize: 12, color: AppColors.kRed)),
                ),
              ]

              // Contenido
              else if (ctrl.estado != null) ...[
                // Stats grid — Completadas / Pendientes
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon:  Icons.person_outlined,
                        value: '${ctrl.estado!['completadas'] ?? 0}',
                        label: 'Completadas',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon:  Icons.access_time_outlined,
                        value: '${ctrl.estado!['pendientes'] ?? 0}',
                        label: 'Pendientes',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tarjeta enlace
                _EnlaceCard(ctrl: ctrl),
                const SizedBox(height: 16),

                // Cómo funciona
                _ComoFunciona(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String   value;
  final String   label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        Colors.white,
          border:       Border.all(color: AppColors.kCardBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.kBlueLight),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize:   30,
                fontWeight: FontWeight.w900,
                color:      AppColors.kTextPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w500,
                color:      AppColors.kTextSecondary,
              ),
            ),
          ],
        ),
      );
}

// ── Tarjeta de enlace ─────────────────────────────────────────────────────────

class _EnlaceCard extends StatelessWidget {
  const _EnlaceCard({required this.ctrl});
  final UseInvitaciones ctrl;

  @override
  Widget build(BuildContext context) {
    final activo = ctrl.estado!['invActivo'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        border:       Border.all(color: AppColors.kCardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + badge activo/inactivo
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tu enlace de invitación',
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color:      AppColors.kTextPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color:        activo
                      ? const Color(0xFF059669) // emerald-600
                      : AppColors.kTextMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  activo ? 'Activo' : 'Inactivo',
                  style: const TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color:      Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // URL + botón copiar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color:        AppColors.kBgPage,
              border:       Border.all(color: AppColors.kCardBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ctrl.enlace,
                    style: const TextStyle(
                      fontSize:   11,
                      fontFamily: 'monospace',
                      color:      AppColors.kTextSecondary,
                    ),
                    maxLines:  1,
                    overflow:  TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: ctrl.copyEnlace,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      ctrl.copied ? Icons.check : Icons.copy_outlined,
                      size:  16,
                      color: ctrl.copied
                          ? AppColors.kBlue : AppColors.kTextMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Botón activar/desactivar
          GestureDetector(
            onTap: ctrl.toggling ? null : ctrl.toggle,
            child: AnimatedOpacity(
              opacity: ctrl.toggling ? 0.5 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width:   double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color:        activo
                      ? AppColors.kSkeleton
                      : AppColors.kBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.power_settings_new,
                      size:  14,
                      color: activo
                          ? AppColors.kTextSecondary : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ctrl.toggling
                          ? 'Cambiando…'
                          : activo
                              ? 'Desactivar enlace'
                              : 'Activar enlace',
                      style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color:      activo
                            ? AppColors.kTextSecondary : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Descripción estado
          Text(
            activo
                ? 'El enlace está activo. Los registros a través de él serán rastreados. '
                    'Desactivar no afecta las invitaciones ya en progreso.'
                : 'El enlace está inactivo. Los registros desde él no contarán. '
                    'Desactivar no afecta las invitaciones ya en progreso.',
            style: const TextStyle(
                fontSize: 11, color: AppColors.kTextMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Cómo funciona ─────────────────────────────────────────────────────────────

class _ComoFunciona extends StatelessWidget {
  const _ComoFunciona();

  static const _pasos = [
    'Comparte tu enlace con quien quieras.',
    'Cuando se registren, quedan vinculados a tu código.',
    'Una invitación se completa cuando el invitado reacciona a 3 menús distintos.',
    'Cada invitación completada cuenta para desbloquear logros y ganar días gratis.',
  ];

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        Colors.white,
          border:       Border.all(color: AppColors.kCardBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CÓMO FUNCIONA',
              style: TextStyle(
                fontSize:      10,
                fontWeight:    FontWeight.w600,
                letterSpacing: 0.8,
                color:         AppColors.kTextMuted,
              ),
            ),
            const SizedBox(height: 12),
            ..._pasos.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width:  18,
                        height: 18,
                        margin: const EdgeInsets.only(top: 1, right: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEF2FF),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(
                              fontSize:   9,
                              fontWeight: FontWeight.w800,
                              color:      AppColors.kBlue,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(
                            fontSize: 13,
                            color:    AppColors.kTextSecondary,
                            height:   1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
}
