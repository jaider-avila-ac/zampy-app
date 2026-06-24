import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/suscripcion_service.dart';
import '../../../shared/app_colors.dart';

// Equivalente a src/modules/subscription/pages/SuscripcionOverviewPage.jsx en React
// Accesible desde el sidebar (/suscripcion).
// Muestra todas las suscripciones del usuario con su estado y acciones rápidas.

class SuscripcionOverviewPage extends StatefulWidget {
  const SuscripcionOverviewPage({super.key});

  @override
  State<SuscripcionOverviewPage> createState() => _SuscripcionOverviewPageState();
}

class _SuscripcionOverviewPageState extends State<SuscripcionOverviewPage> {
  List<dynamic> _suscripciones = [];
  bool   _loading = true;
  String _error   = '';
  int?   _paying;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final data = await SuscripcionService.getMisSuscripciones();
      if (mounted) setState(() { _suscripciones = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error   = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _renovar(int menId) async {
    if (!mounted) return;
    // Navegar al checkout de renovación
    context.push('/billing/$menId/checkout?tipo=renovacion');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Suscripciones',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 20),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_error.isNotEmpty)
                  _ErrorBanner(error: _error),
                Expanded(
                  child: _suscripciones.isEmpty
                      ? _EmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _suscripciones.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final sus = _suscripciones[i] as Map<String, dynamic>;
                            return _SuscripcionCard(
                              sus:      sus,
                              paying:   _paying == (sus['id'] as int?),
                              onRenovar: () => _renovar(
                                  (sus['menId'] ?? sus['menuId']) as int),
                              onVer: () => context.push('/billing/sus/${sus['id']}'),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// ── Tarjeta de suscripción ────────────────────────────────────────────────────
class _SuscripcionCard extends StatelessWidget {
  const _SuscripcionCard({
    required this.sus,
    required this.paying,
    required this.onRenovar,
    required this.onVer,
  });

  final Map<String, dynamic> sus;
  final bool paying;
  final VoidCallback onRenovar;
  final VoidCallback onVer;

  @override
  Widget build(BuildContext context) {
    final tipoPlan     = sus['tipoPlan'] as String? ?? '';
    final estadoRaw    = sus['estado']   as String? ?? '';
    final esTrial      = tipoPlan == 'trial';
    final estadoEfect  = (estadoRaw == 'ACTIVE' && esTrial) ? 'TRIAL' : estadoRaw;
    final needsRenovar = (sus['acciones'] as Map?)?['mostrarBotonRenovar'] == true;

    final menuNombre   = sus['menuNombre'] as String?
        ?? 'Menú #${sus['menId'] ?? sus['menuId'] ?? ''}';
    final periodoInicio = sus['periodoInicio'] as String?;
    final periodoFin    = sus['periodoFin']    as String?;

    final (badgeColor, badgeBg, estadoLabel) = _estadoInfo(estadoEfect);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Badge estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(estadoLabel,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor)),
          ),
          const SizedBox(width: 10),

          // Nombre + fechas
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(menuNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A))),
                if (periodoInicio != null || periodoFin != null)
                  Text(
                    '${_fmtDate(periodoInicio)} → ${_fmtDate(periodoFin)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),

          // Botón renovar (si aplica)
          if (needsRenovar) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: paying ? null : onRenovar,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.kBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: paying
                    ? const SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.credit_card, size: 11, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Renovar',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
              ),
            ),
          ],

          // Chevron ver detalle
          const SizedBox(width: 4),
          IconButton(
            onPressed: onVer,
            icon: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  (Color, Color, String) _estadoInfo(String estado) {
    return switch (estado) {
      'ACTIVE'             => (const Color(0xFF15803D), const Color(0xFFF0FDF4), 'Activa'),
      'TRIAL'              => (const Color(0xFF15803D), const Color(0xFFF0FDF4), 'Prueba gratuita'),
      'PAYMENT_REMINDER'   => (const Color(0xFF92400E), const Color(0xFFFFFBEB), 'Recordatorio pago'),
      'PAST_DUE'           => (const Color(0xFFC2410C), const Color(0xFFFFF7ED), 'Vencida (gracia)'),
      'WAITING_ACTIVATION' => (const Color(0xFF1D4ED8), const Color(0xFFEFF6FF), 'Activando…'),
      'SUSPENDED'          => (const Color(0xFF991B1B), const Color(0xFFFEF2F2), 'Suspendida'),
      'CANCELLED' || 'CANCELED' => (const Color(0xFF64748B), const Color(0xFFF1F5F9), 'Cancelada'),
      _                    => (const Color(0xFF64748B), const Color(0xFFF1F5F9), estado),
    };
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '—';
    }
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.credit_card_outlined,
                  size: 44, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 14),
              const Text('No tienes suscripciones aún',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B))),
              const SizedBox(height: 6),
              const Text(
                'Publica un menú para adquirir tu primera suscripción.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go('/menus'),
                icon: const Icon(Icons.restaurant_menu_outlined, size: 16),
                label: const Text('Mis Menús'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.kBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Text(error,
            style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B))),
      );
}
