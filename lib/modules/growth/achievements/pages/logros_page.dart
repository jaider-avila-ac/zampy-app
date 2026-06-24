import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../hooks/use_logros.dart';
import '../components/logro_card.dart';
import '../../../../shared/app_colors.dart';
import '../../../../shared/app_header.dart';
import '../../../../components/layout/sidebar.dart';

// Equivalente a src/modules/growth/achievements/pages/LogrosPage.jsx

class LogrosPage extends StatelessWidget {
  const LogrosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UseLogros()..load(),
      child: const _LogrosView(),
    );
  }
}

class _LogrosView extends StatelessWidget {
  const _LogrosView();

  void _goBack(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      GoRouter.of(context).pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UseLogros>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => _goBack(context),
      child: Scaffold(
        backgroundColor: AppColors.kBgPage,
        drawer: const AppSidebar(),
        appBar: AppHeader(
          title: 'Logros',
          actions: [
            if (ctrl.desbloqueados.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color:        AppColors.kSkeleton,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${ctrl.desbloqueados.length} '
                      'desbloqueado${ctrl.desbloqueados.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w600,
                        color:      AppColors.kTextSecondary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            // Banner informativo
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(child: _InfoBanner()),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Cargando
            if (ctrl.loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.kBlue),
                ),
              )

            // Sin logros
            else if (ctrl.logros.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No hay logros configurados',
                        style: TextStyle(
                          fontSize:   15,
                          fontWeight: FontWeight.w700,
                          color:      AppColors.kTextPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('Vuelve pronto.',
                          style: TextStyle(fontSize: 13, color: AppColors.kTextMuted)),
                    ],
                  ),
                ),
              )

            // Listas
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (ctrl.pendientes.isNotEmpty) ...[
                      const _SectionLabel('Por desbloquear'),
                      const SizedBox(height: 8),
                      ...ctrl.pendientes.map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: LogroCard(logro: l),
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (ctrl.desbloqueados.isNotEmpty) ...[
                      const _SectionLabel('Desbloqueados'),
                      const SizedBox(height: 8),
                      ...ctrl.desbloqueados.map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: LogroCard(logro: l),
                          )),
                    ],
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:        const Color(0xFFEEF2FF),
          border:       Border.all(color: const Color(0xFFE0E7FF)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Los días que ganas se aplican la próxima vez que publiques tu menú.',
          style: TextStyle(fontSize: 12, color: Color(0xFF4338CA), height: 1.5),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize:      10,
          fontWeight:    FontWeight.w600,
          letterSpacing: 0.8,
          color:         AppColors.kTextMuted,
        ),
      );
}
