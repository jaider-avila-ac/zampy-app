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
  bool _loading     = true;
  bool _trialLoading = false;
  String _error     = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final precioFuture = SuscripcionService.getPrecio();
      final subFuture    = SuscripcionService.getMiSuscripcion(widget.menuId)
          .catchError((_) => null as Map<String, dynamic>?);
      final precio = await precioFuture;
      final sub    = await subFuture;

      if (!mounted) return;

      // Si ya está activo/aviso/esperando → volver al editor
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

  bool get _isFirstPublish {
    final tipoPlan   = _sub?['tipoPlan'] as String?;
    final trialUsado = _sub?['trialUsado'] as bool? ?? false;
    return tipoPlan == null && !trialUsado;
  }

  int get _trialDuracion => (_precio?['trialDuracion'] as num?)?.toInt() ?? 0;

  Future<void> _usarTrial() async {
    setState(() => _trialLoading = true);
    try {
      await MenuEditorService.publish(widget.menuId);
      if (mounted) context.go('/menus/${widget.menuId}/edit');
    } catch (e) {
      if (mounted) {
        setState(() => _trialLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _seleccionarPlan(String codigoPlan) {
    final estado = _sub?['estado'] as String? ?? '';
    final tipo   = estado == 'PAST_DUE' || estado == 'CANCELLED' ? 'renovacion' : 'checkout';
    context.push('/billing/${widget.menuId}/checkout?tipo=$tipo&plan=$codigoPlan');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Planes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _ErrorView(error: _error, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final planes = _precio?['planes'] as Map<String, dynamic>? ?? {};
    final plansList = planes.entries
        .where((e) => e.key != 'trial')
        .map((e) => {'codigo': e.key, ...(e.value as Map<String, dynamic>)})
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Elige tu plan',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Publica tu menú y empieza a recibir clientes',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),

        // ── Botón trial ──
        if (_isFirstPublish && _trialDuracion > 0) ...[
          _TrialButton(
            dias: _trialDuracion,
            loading: _trialLoading,
            onTap: _usarTrial,
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('o elige un plan',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // ── Tarjetas de planes ──
        ...plansList.map((plan) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _PlanCard(
            plan: plan,
            onSelect: () => _seleccionarPlan(plan['codigo'] as String),
          ),
        )),

        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Todos los precios incluyen IVA · Cancela cuando quieras',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }
}

// ── Botón trial ───────────────────────────────────────────────────────────────
class _TrialButton extends StatelessWidget {
  const _TrialButton({required this.dias, required this.loading, required this.onTap});
  final int  dias;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF16A34A), Color(0xFF15803D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_outline, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('$dias días gratis',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const Spacer(),
                      const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sin tarjeta de crédito · Publica ahora',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Tarjeta de plan ───────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onSelect});
  final Map<String, dynamic> plan;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final nombre         = plan['nombre'] as String? ?? plan['codigo'] as String? ?? '';
    final precio         = (plan['precio'] as num?)?.toInt() ?? 0;
    final limiteProductos = (plan['limiteProductos'] as num?)?.toInt();
    final descripcion    = plan['descripcion'] as String?;
    final esRecomendado  = plan['recomendado'] as bool? ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: esRecomendado ? AppColors.kBlue : const Color(0xFFE2E8F0),
          width: esRecomendado ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (esRecomendado)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.kBlue,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Center(
                child: Text('Más popular',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nombre,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A))),
                          if (descripcion != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(descripcion,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF64748B))),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${_formatPrice(precio)}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.kBlue),
                        ),
                        const Text('/mes',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),

                if (limiteProductos != null) ...[
                  const SizedBox(height: 12),
                  _Feature(
                    icon: Icons.fastfood_outlined,
                    text: 'Hasta $limiteProductos productos',
                  ),
                ],

                // Features adicionales del plan si las hay
                ..._buildFeatures(plan),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onSelect,
                    style: FilledButton.styleFrom(
                      backgroundColor: esRecomendado ? AppColors.kBlue : const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Elegir $nombre',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeatures(Map<String, dynamic> plan) {
    final features = plan['features'] as List?;
    if (features == null || features.isEmpty) return [];
    return [
      const SizedBox(height: 8),
      ...features.map<Widget>((f) => _Feature(
        icon: Icons.check_circle_outline,
        text: f.toString(),
      )),
    ];
  }

  String _formatPrice(int cents) {
    final n = (cents / 100).round();
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});
  final IconData icon;
  final String   text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xFF16A34A)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              Text(error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
}
