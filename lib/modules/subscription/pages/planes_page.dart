import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/suscripcion_service.dart';
import '../../../services/menu_editor_service.dart';
import '../../../shared/app_colors.dart';

// Equivalente a src/modules/subscription/pages/PlanesPage.jsx en React

class PlanesPage extends StatefulWidget {
  const PlanesPage({super.key, required this.menuId});
  final int menuId;

  @override
  State<PlanesPage> createState() => _PlanesPageState();
}

class _PlanesPageState extends State<PlanesPage> {
  Map<String, dynamic>? _precio;
  Map<String, dynamic>? _sub;
  bool   _loading      = true;
  bool   _trialLoading = false;
  String _error        = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final precioFuture = SuscripcionService.getPrecio();
      final subFuture    = SuscripcionService.getMiSuscripcion(widget.menuId)
          .catchError((_) => null as Map<String, dynamic>?);
      final precio = await precioFuture;
      final sub    = await subFuture;
      if (!mounted) return;

      final estado = sub?['estado'] as String? ?? '';
      if (['ACTIVE', 'PAYMENT_REMINDER', 'WAITING_ACTIVATION'].contains(estado)) {
        context.go('/menus/${widget.menuId}/edit');
        return;
      }

      setState(() {
        _precio  = precio;
        _sub     = sub;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error   = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  // ── Derivados (igual que React) ────────────────────────────────────────────
  String? get _subEstado      => _sub?['estado']     as String?;
  bool    get _trialUsado     => _sub?['trialUsado'] as bool? ?? false;
  bool    get _isFirstPublish => (_subEstado == null || _subEstado!.isEmpty) && !_trialUsado;
  bool    get _isPastDue      => _subEstado == 'PAST_DUE';

  // duracionMinutos vive en precio.planes.trial.duracionMinutos (no en precio raíz)
  int get _trialDuracion {
    final planes = _precio?['planes'] as Map<String, dynamic>?;
    final trial  = planes?['trial']   as Map<String, dynamic>?;
    return (trial?['duracionMinutos'] as num?)?.toInt() ?? 0;
  }

  List<Map<String, dynamic>> get _plansList {
    final planes = _precio?['planes'] as Map<String, dynamic>? ?? {};
    return planes.entries
        .where((e) => e.key != 'trial')
        .map((e) => {'code': e.key, ...(e.value as Map<String, dynamic>)})
        .toList();
  }

  Future<void> _usarTrial() async {
    setState(() { _trialLoading = true; _error = ''; });
    try {
      await MenuEditorService.publish(widget.menuId, trial: true);
      if (mounted) context.go('/menus/${widget.menuId}/edit');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error       = e.toString().replaceFirst('Exception: ', '');
          _trialLoading = false;
        });
      }
    }
  }

  void _seleccionarPlan(String code) {
    if (_isPastDue) {
      context.push('/billing/${widget.menuId}/checkout?tipo=renovacion');
    } else {
      context.push('/billing/${widget.menuId}/checkout?tipo=checkout&plan=$code');
    }
  }

  // ── Título / descripción dinámicos (igual que React) ──────────────────────
  (String, String) get _header {
    if (_isPastDue) {
      return (
        'Renueva tu suscripción',
        'Tu suscripción venció. Renueva ahora para mantener tu precio — si se suspende deberás contratar al precio vigente.',
      );
    }
    if (_isFirstPublish) { return ('Publica tu menú', 'Elige cómo quieres comenzar.'); }
    return ('Elige un plan', 'Selecciona el plan que mejor se ajuste a tu negocio.');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final (titulo, descripcion) = _header;
    final promo      = _precio?['promo']      as Map<String, dynamic>?;
    final infoBloque = _precio?['infoBloque'] as Map<String, dynamic>?;
    final plansList  = _plansList;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            // ── Volver ────────────────────────────────────────────────────
            GestureDetector(
              onTap: () => context.pop(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 15, color: Color(0xFF6B7280)),
                  SizedBox(width: 6),
                  Text('Volver al editor',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Intro ──────────────────────────────────────────────────────
            Text(titulo,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827))),
            const SizedBox(height: 4),
            Text(descripcion,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            const SizedBox(height: 28),

            // ── Promo banner ───────────────────────────────────────────────
            if (promo != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                margin: const EdgeInsets.only(bottom: 28),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        size: 15, color: Color(0xFF4338CA)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(promo['mensaje'] as String? ?? '',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E1B4B))),
                    ),
                    if (promo['etiqueta'] != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.kBlue,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(promo['etiqueta'] as String,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ── Error ──────────────────────────────────────────────────────
            if (_error.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_outlined,
                        size: 14, color: Color(0xFFB91C1C)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFFB91C1C))),
                    ),
                  ],
                ),
              ),
            ],

            // ── Botón trial ────────────────────────────────────────────────
            if (_isFirstPublish && _trialDuracion > 0) ...[
              _TrialButton(
                duracionMinutos: _trialDuracion,
                loading: _trialLoading,
                onTap: _usarTrial,
              ),
              const SizedBox(height: 20),
            ],

            // ── Cards de planes ────────────────────────────────────────────
            ...plansList.asMap().entries.map((entry) {
              final idx  = entry.key;
              final plan = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _PlanCard(
                  plan:      plan,
                  iconIndex: idx,
                  isCurrent: plan['code'] == (_sub?['tipoPlan'] as String?),
                  isPastDue: _isPastDue,
                  onSelect:  () => _seleccionarPlan(plan['code'] as String),
                ),
              );
            }),

            const SizedBox(height: 8),

            // ── Info bloque inferior ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 20, color: Color(0xFF4338CA)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          infoBloque?['titulo'] as String? ??
                              'Todos nuestros planes incluyen',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          infoBloque?['descripcion'] as String? ??
                              'Soporte por chat, actualizaciones constantes y seguridad para tu negocio.',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Botón trial ───────────────────────────────────────────────────────────────
class _TrialButton extends StatelessWidget {
  const _TrialButton({
    required this.duracionMinutos,
    required this.loading,
    required this.onTap,
  });

  final int  duracionMinutos;
  final bool loading;
  final VoidCallback onTap;

  // Equivalente a fmtTiempo(0, minutos) de React
  static String _fmt(int m) {
    if (m <= 0)   { return '0 minutos'; }
    if (m < 60)   { return '$m minuto${m != 1 ? 's' : ''}'; }
    if (m < 1440) { final h = (m / 60).round(); return '$h hora${h != 1 ? 's' : ''}'; }
    final d = (m / 1440).round();
    return '$d día${d != 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Opacity(
        opacity: loading ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
          ),
          child: loading
              ? const Center(
                  child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5)))
              : Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_fmt(duracionMinutos)} gratis',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(
                            'Sin tarjeta de crédito · Prueba todas las funciones',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.65)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Tarjeta de plan ───────────────────────────────────────────────────────────
// Equivalente a PlanCard en React (incluyendo badge flotante, icono por índice,
// campo `display` para precio, y beneficios del backend)
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.iconIndex,
    required this.isCurrent,
    required this.isPastDue,
    required this.onSelect,
  });

  final Map<String, dynamic> plan;
  final int  iconIndex;
  final bool isCurrent;
  final bool isPastDue;
  final VoidCallback onSelect;

  // [Box, Rocket, Sparkles] de React → equivalentes Material
  static const _icons = [
    Icons.inventory_2_outlined,
    Icons.rocket_launch_outlined,
    Icons.auto_awesome,
  ];

  @override
  Widget build(BuildContext context) {
    final etiqueta   = plan['etiqueta'] as String?
        ?? ((plan['popular'] as bool? ?? false) ? 'Más popular' : null);
    final isHighlight = etiqueta != null;

    final nombre = (isPastDue && isCurrent)
        ? 'Renovar — ${plan['nombre'] ?? plan['code']}'
        : (plan['nombre'] as String? ?? plan['code'] as String? ?? '');

    final limite              = plan['limite']              as num?;
    final limiteCategorias    = plan['limiteCategorias']    as num?;
    final limiteColaboradores = plan['limiteColaboradores'] as num?;
    final beneficiosExtra     = (plan['beneficios']         as List?)?.cast<String>() ?? [];

    final beneficios = [
      if (limite              != null) 'Hasta ${limite.toInt()} productos',
      if (limiteCategorias    != null) 'Hasta ${limiteCategorias.toInt()} categorías',
      if (limiteColaboradores != null) 'Hasta ${limiteColaboradores.toInt()} colaboradores',
      ...beneficiosExtra,
    ];

    final icon = _icons[iconIndex % _icons.length];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Card ──────────────────────────────────────────────────────────
        Container(
          margin: EdgeInsets.only(top: etiqueta != null ? 14 : 0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isHighlight ? AppColors.kBlue : const Color(0xFFE5E7EB),
              width: isHighlight ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isHighlight
                      ? const Color(0xFFE0E7FF)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 18,
                    color: isHighlight
                        ? const Color(0xFF4338CA)
                        : const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),

              // Nombre
              Text(nombre,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827))),
              const SizedBox(height: 16),

              // Precio — `display` viene pre-formateado del backend
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    plan['display'] as String? ?? '',
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4338CA)),
                  ),
                  const SizedBox(width: 4),
                  const Text('/mes',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF9CA3AF))),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF3F4F6), height: 1),

              // Beneficios
              if (beneficios.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...beneficios.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 14, color: Color(0xFF4338CA)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(b,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF374151))),
                          ),
                        ],
                      ),
                    )),
              ],

              const SizedBox(height: 20),

              // CTA
              SizedBox(
                width: double.infinity,
                child: isHighlight
                    ? FilledButton(
                        onPressed: onSelect,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.kBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Elegir plan →',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                      )
                    : OutlinedButton(
                        onPressed: onSelect,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFF4338CA), width: 2),
                          foregroundColor: const Color(0xFF4338CA),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Elegir plan →',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
              ),
            ],
          ),
        ),

        // ── Badge flotante centrado (-top-3.5 left-1/2 de React) ──────────
        if (etiqueta != null)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.kBlue,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(etiqueta,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ),
      ],
    );
  }
}
