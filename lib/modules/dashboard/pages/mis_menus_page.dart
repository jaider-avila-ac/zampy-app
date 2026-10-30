import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/responsive.dart';

import '../../../components/layout/sidebar.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/app_header.dart';
import '../../explore/components/menu_card.dart';
import '../components/colaborador_row.dart';
import '../hooks/use_mis_menus.dart';

// Equivalente a src/modules/dashboard/pages/MisMenusPage.jsx en React.

class MisMenusPage extends StatelessWidget {
  const MisMenusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UseMisMenus()..load(),
      child: const _MisMenusView(),
    );
  }
}

class _MisMenusView extends StatelessWidget {
  const _MisMenusView();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UseMisMenus>();

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
        appBar: AppHeader(
          title: 'Mis Menús',
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Opacity(
                opacity: ctrl.atLimit ? 0.5 : 1,
                child: IgnorePointer(
                  ignoring: ctrl.atLimit,
                  child: GestureDetector(
                    onTap: () => context.push('/menus/new'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.kBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 15, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Nuevo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          color: AppColors.kBlue,
          onRefresh: ctrl.reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: contenidoPadding(context, maxWidth: 960, bottom: 40),
            children: [
              if (!ctrl.loading && ctrl.limiteMenus != null) ...[
                _LimitBadge(
                  count: ctrl.menus.length,
                  limit: ctrl.limiteMenus!,
                  atLimit: ctrl.atLimit,
                ),
                const SizedBox(height: 12),
              ],

              if (ctrl.loading && ctrl.menus.isEmpty)
                ...[1, 2, 3].map(
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: _MenuSkeleton(),
                  ),
                )
              else if (ctrl.errorMenus != null && ctrl.menus.isEmpty)
                _ErrorCard(message: ctrl.errorMenus!, onRetry: ctrl.retryMenus)
              else if (ctrl.menus.isEmpty)
                _EmptyMenus(onNew: () => context.push('/menus/new'))
              else ...[
                if (ctrl.errorMenus != null) ...[
                  _InlineError(
                    message: ctrl.errorMenus!,
                    onRetry: ctrl.retryMenus,
                  ),
                  const SizedBox(height: 8),
                ],
                ...ctrl.menus.map(
                  (menu) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MenuCard(
                      menu: menu,
                      showActions: false,
                      onTap: () => context.push('/menus/${menu.codigo}'),
                    ),
                  ),
                ),
              ],

              if (ctrl.colaborados.isNotEmpty || ctrl.errorColab != null) ...[
                const SizedBox(height: 24),
                const _SectionTitle(),
                const SizedBox(height: 10),
                if (ctrl.errorColab != null) ...[
                  _InlineError(
                    message: ctrl.errorColab!,
                    onRetry: ctrl.retryColaboraciones,
                  ),
                  const SizedBox(height: 8),
                ],
                ...ctrl.colaborados.map(
                  (menu) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ColaboradorRow(
                      menu: menu,
                      onOpen: () => context.push('/menus/${menu.codigo}'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LimitBadge extends StatelessWidget {
  const _LimitBadge({
    required this.count,
    required this.limit,
    required this.atLimit,
  });

  final int count;
  final int limit;
  final bool atLimit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$count/$limit menús',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: atLimit ? const Color(0xFFEF4444) : AppColors.kTextMuted,
          ),
        ),
        if (atLimit) ...[
          const SizedBox(width: 6),
          const Icon(Icons.lock_outline, size: 11, color: Color(0xFFEF4444)),
          const SizedBox(width: 3),
          const Text(
            'Límite alcanzado',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.people_outline, size: 16, color: AppColors.kBlueLight),
        SizedBox(width: 6),
        Text(
          'Colaborando en',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _MenuSkeleton extends StatelessWidget {
  const _MenuSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.kSkeleton,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 13,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.kSkeleton,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 11,
                  width: 200,
                  decoration: BoxDecoration(
                    color: AppColors.kSkeleton,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 11,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.kSkeleton,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMenus extends StatelessWidget {
  const _EmptyMenus({required this.onNew});

  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.no_food_outlined,
            size: 36,
            color: AppColors.kTextMuted,
          ),
          const SizedBox(height: 12),
          const Text(
            'No tienes menús aún',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.kTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Crea tu primer menú digital y compártelo con tus clientes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.kTextMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add, size: 15),
            label: const Text('Crear mi primer menú'),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 34,
            color: AppColors.kTextMuted,
          ),
          const SizedBox(height: 10),
          const Text(
            'No se pudieron cargar tus menús',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.kTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 15),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            size: 15,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Reintentar', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
