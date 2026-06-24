import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/app_header.dart';
import '../hooks/use_mis_menus.dart';

// Equivalente a src/modules/dashboard/pages/MisMenusPage.jsx en React
// Fase actual: solo listado + estadísticas + preview. Edición/delete se implementa después.

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

    return GestureDetector(
      // Cerrar dropdown al tocar fuera (equiv. document.addEventListener('click', close))
      onTap: ctrl.closeDropdown,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.kBgPage,
        appBar: AppHeader(
          title: 'Mis Menús',
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: ctrl.atLimit ? null : () => context.push('/menus/new'),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: ctrl.atLimit ? 0.5 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color:        AppColors.kBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 15, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Nuevo',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [

              // ── Contador de menús ──────────────────────────────────────────
              if (!ctrl.loading && ctrl.limiteMenus != null) ...[
                _LimitBadge(
                    count: ctrl.menus.length,
                    limit: ctrl.limiteMenus!,
                    atLimit: ctrl.atLimit),
                const SizedBox(height: 12),
              ],

              // ── Skeletons ──────────────────────────────────────────────────
              if (ctrl.loading)
                ...[1, 2, 3].map((_) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: _MenuSkeleton(),
                )),

              // ── Empty state ────────────────────────────────────────────────
              if (!ctrl.loading && ctrl.menus.isEmpty)
                _EmptyMenus(onNew: () => context.push('/menus/new')),

              // ── Lista de menús propios ──────────────────────────────────────
              if (!ctrl.loading && ctrl.menus.isNotEmpty)
                ...ctrl.menus.map((menu) {
                  final m = menu as Map<String, dynamic>;
                  final id = m['id'] as int;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _MenuRow(
                      menu:         m,
                      expanded:     ctrl.openMenuId == id,
                      onTap:        () { ctrl.toggleDropdown(id); },
                      onEdit:       () => context.push('/menus/$id/edit'),
                      onPreview:    () => context.push('/preview/$id'),
                      onStats:      () => context.push('/menus/$id/estadisticas'),
                    ),
                  );
                }),

              // ── Colaboraciones ─────────────────────────────────────────────
              if (!ctrl.loadingColab && ctrl.colaborados.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Icon(Icons.people_outlined, size: 15, color: AppColors.kBlue),
                    SizedBox(width: 6),
                    Text('Colaborando en',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                            color: AppColors.kTextPrimary)),
                  ],
                ),
                const SizedBox(height: 10),
                ...ctrl.colaborados.map((menu) {
                  final m  = menu as Map<String, dynamic>;
                  final id = m['id'] as int;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ColaboradorRow(
                      menu:      m,
                      expanded:  ctrl.openMenuId == id,
                      onTap:     () => ctrl.toggleDropdown(id),
                      onEdit:    () => context.push('/menus/$id/edit'),
                      onPreview: () => context.push('/preview/$id'),
                      onStats:   () => context.push('/menus/$id/estadisticas'),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Contador / límite ─────────────────────────────────────────────────────────

class _LimitBadge extends StatelessWidget {
  const _LimitBadge({
    required this.count,
    required this.limit,
    required this.atLimit,
  });
  final int  count;
  final int  limit;
  final bool atLimit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$count/$limit menús',
          style: TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w600,
            color:      atLimit ? const Color(0xFFEF4444) : AppColors.kTextMuted,
          ),
        ),
        if (atLimit) ...[
          const SizedBox(width: 6),
          const Icon(Icons.lock_outline, size: 11, color: Color(0xFFEF4444)),
          const SizedBox(width: 3),
          const Text('Límite alcanzado',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444))),
        ],
      ],
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _MenuSkeleton extends StatelessWidget {
  const _MenuSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColors.kCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(
              color: AppColors.kSkeleton, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 13, width: 120,
                    decoration: BoxDecoration(color: AppColors.kSkeleton,
                        borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 8),
                Container(height: 11, width: 200,
                    decoration: BoxDecoration(color: AppColors.kSkeleton,
                        borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 6),
                Container(height: 11, width: 80,
                    decoration: BoxDecoration(color: AppColors.kSkeleton,
                        borderRadius: BorderRadius.circular(6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyMenus extends StatelessWidget {
  const _EmptyMenus({required this.onNew});
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColors.kCardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.no_food_outlined, size: 36, color: AppColors.kTextMuted),
          const SizedBox(height: 12),
          const Text('No tienes menús aún',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.kTextPrimary)),
          const SizedBox(height: 6),
          const Text(
            'Crea tu primer menú digital y compártelo con tus clientes.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.kTextMuted, height: 1.5),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onNew,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color:        AppColors.kBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Crear mi primer menú',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── MenuRow (menús propios) ───────────────────────────────────────────────────

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.menu,
    required this.expanded,
    required this.onTap,
    required this.onEdit,
    required this.onPreview,
    required this.onStats,
  });

  final Map<String, dynamic> menu;
  final bool                 expanded;
  final VoidCallback         onTap;
  final VoidCallback         onEdit;
  final VoidCallback         onPreview;
  final VoidCallback         onStats;

  @override
  Widget build(BuildContext context) {
    final info        = (menu['draft'] as Map<String, dynamic>)['info'] as Map<String, dynamic>;
    final isPublished = menu['status'] == 'published';
    final hasDraft    = menu['hasDraftChanges'] as bool? ?? false;
    final vistas      = menu['totalVistas']  as int? ?? 0;
    final encantas    = menu['meEncantas']   as int? ?? 0;
    final resenas     = menu['totalResenas'] as int? ?? 0;
    final logoUrl     = info['logoUrl'] as String?;
    final name        = info['name']   as String? ?? '';
    final slogan      = info['slogan'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: AppColors.kCardBorder),
        ),
        child: Column(
          children: [
            // ── Fila principal ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  _Thumb(logoUrl: logoUrl, name: name),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.kTextPrimary,
                                height: 1.3)),
                        const SizedBox(height: 3),
                        Text(slogan.isNotEmpty ? slogan : 'Sin slogan',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11,
                                color: AppColors.kTextMuted, height: 1.35)),
                        // Estadísticas inline
                        if (vistas > 0 || encantas > 0 || resenas > 0) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 10, runSpacing: 4,
                            children: [
                              if (vistas > 0)
                                _StatChip(icon: Icons.visibility_outlined,
                                    label: '$vistas vista${vistas != 1 ? 's' : ''}'),
                              if (encantas > 0)
                                _StatChip(icon: Icons.favorite,
                                    label: '$encantas', filled: true),
                              if (resenas > 0)
                                _StatChip(icon: Icons.chat_bubble_outline,
                                    label: '$resenas reseña${resenas != 1 ? 's' : ''}',
                                    muted: true),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badges
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusBadge(published: isPublished),
                      if (hasDraft && isPublished) ...[
                        const SizedBox(height: 4),
                        const _DraftBadge(),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Acciones expandidas ─────────────────────────────────────
            if (expanded)
              GestureDetector(
                onTap: () {}, // stopPropagation
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    children: [
                      _ActionBtn(icon: Icons.edit_outlined,
                          label: 'Editar', onTap: onEdit),
                      _ActionBtn(icon: Icons.open_in_new_outlined,
                          label: 'Preview', onTap: onPreview),
                      _ActionBtn(icon: Icons.bar_chart_outlined,
                          label: 'Estadísticas', onTap: onStats),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── ColaboradorRow ────────────────────────────────────────────────────────────

class _ColaboradorRow extends StatelessWidget {
  const _ColaboradorRow({
    required this.menu,
    required this.expanded,
    required this.onTap,
    required this.onEdit,
    required this.onPreview,
    required this.onStats,
  });

  final Map<String, dynamic> menu;
  final bool                 expanded;
  final VoidCallback         onTap;
  final VoidCallback         onEdit;
  final VoidCallback         onPreview;
  final VoidCallback         onStats;

  @override
  Widget build(BuildContext context) {
    final info        = (menu['draft'] as Map<String, dynamic>)['info'] as Map<String, dynamic>;
    final isPublished = menu['status'] == 'published';
    final logoUrl     = info['logoUrl'] as String?;
    final name        = info['name']   as String? ?? '';
    final slogan      = info['slogan'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: AppColors.kCardBorder),
        ),
        child: Column(
          children: [
            // ── Fila principal ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumb(logoUrl: logoUrl, name: name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.kTextPrimary, height: 1.3)),
                        const SizedBox(height: 3),
                        Text(slogan.isNotEmpty ? slogan : 'Sin slogan',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11,
                                color: AppColors.kTextMuted, height: 1.35)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(published: isPublished),
                ],
              ),
            ),

            // ── Acciones expandidas ─────────────────────────────────────
            if (expanded)
              GestureDetector(
                onTap: () {},
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    children: [
                      _ActionBtn(icon: Icons.edit_outlined,
                          label: 'Editar', onTap: onEdit),
                      _ActionBtn(icon: Icons.open_in_new_outlined,
                          label: 'Preview', onTap: onPreview),
                      _ActionBtn(icon: Icons.bar_chart_outlined,
                          label: 'Estadísticas', onTap: onStats),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets reutilizables ─────────────────────────────────────────────────────

class _Thumb extends StatelessWidget {
  const _Thumb({required this.logoUrl, required this.name});
  final String? logoUrl;
  final String  name;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48, height: 48,
      child: ClipOval(
        child: logoUrl != null && logoUrl!.isNotEmpty
            ? Image.network(logoUrl!, fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => _GradientThumb())
            : _GradientThumb(),
      ),
    );
  }
}

class _GradientThumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.published});
  final bool published;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        published ? AppColors.kBlue : const Color(0xFF64748B),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        published ? 'Publicado' : 'Borrador',
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
            color: Colors.white),
      ),
    );
  }
}

class _DraftBadge extends StatelessWidget {
  const _DraftBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        const Color(0xFF818CF8),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text('Cambios',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
              color: Colors.white)),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    this.filled = false,
    this.muted  = false,
  });
  final IconData icon;
  final String   label;
  final bool     filled;
  final bool     muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.kTextMuted : AppColors.kBlue;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color,
            fill: filled ? 1.0 : 0.0),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          margin:  const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color:        const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.kTextMuted),
        ),
      ),
    );
  }
}
