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

            // Mensajes y aplicar días a un menú
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(child: _Avisos(ctrl: ctrl)),
            ),

            // Cargando
            if (ctrl.loading && ctrl.logros.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.kBlue),
                ),
              )

            // Error sin datos: se muestra en _Avisos con reintento
            else if (ctrl.error)
              const SliverToBoxAdapter(child: SizedBox.shrink())

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
                            child: LogroCard(
                              logro: l,
                              selectable: l.disponible,
                              selected: ctrl.selected.contains(l.codigo),
                              onSelect: () => ctrl.toggleSelected(l.codigo),
                              menuNombre: ctrl.nombreMenu(l.menuCodigoAplicado),
                            ),
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

// ── Avisos y aplicar recompensas ──────────────────────────────────────────────

class _Avisos extends StatelessWidget {
  const _Avisos({required this.ctrl});
  final UseLogros ctrl;

  @override
  Widget build(BuildContext context) {
    final n = ctrl.selected.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ctrl.error)
          _Mensaje(
            color: const Color(0xFFB91C1C),
            bg: const Color(0xFFFEF2F2),
            border: const Color(0xFFFECACA),
            texto: 'No se pudieron cargar los logros.',
            accion: 'Reintentar',
            onAccion: ctrl.refetch,
          ),
        if (ctrl.actionError.isNotEmpty)
          _Mensaje(
            color: const Color(0xFFB91C1C),
            bg: const Color(0xFFFEF2F2),
            border: const Color(0xFFFECACA),
            texto: ctrl.actionError,
          ),
        if (ctrl.success.isNotEmpty)
          _Mensaje(
            color: const Color(0xFF047857),
            bg: const Color(0xFFECFDF5),
            border: const Color(0xFFA7F3D0),
            texto: ctrl.success,
          ),
        if (ctrl.disponibles.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              border: Border.all(color: const Color(0xFFC7D2FE)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Aplicar días a un menú',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B))),
                const SizedBox(height: 2),
                const Text('Selecciona recompensas completas. Después no se pueden trasladar.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4338CA))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  // initialValue solo se lee al crear el campo: se recrea al llegar los menús
                  key: ValueKey('${ctrl.menus.length}-${ctrl.menuCodigo}'),
                  initialValue: ctrl.menuCodigo,
                  isExpanded: true,
                  hint: const Text('Selecciona un menú', style: TextStyle(fontSize: 13)),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFC7D2FE)),
                    ),
                  ),
                  items: [
                    for (final m in ctrl.menus)
                      DropdownMenuItem(
                        value: m.codigo,
                        child: Text(m.nombre.isNotEmpty ? m.nombre : m.slug,
                            overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                      ),
                  ],
                  onChanged: ctrl.applying ? null : ctrl.setMenu,
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: ctrl.puedeAplicar ? ctrl.aplicar : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.kBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(ctrl.applying
                      ? 'Aplicando…'
                      : n == 0
                          ? 'Marca las recompensas que quieres aplicar'
                          : 'Aplicar $n recompensa${n == 1 ? '' : 's'}'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({
    required this.color,
    required this.bg,
    required this.border,
    required this.texto,
    this.accion,
    this.onAccion,
  });
  final Color color;
  final Color bg;
  final Color border;
  final String texto;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(child: Text(texto, style: TextStyle(fontSize: 12, color: color))),
            if (accion != null)
              TextButton(
                onPressed: onAccion,
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(accion!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline)),
              ),
          ],
        ),
      );
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
          'Los días ganados quedan disponibles hasta que elijas el menú donde quieres aplicarlos.',
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
