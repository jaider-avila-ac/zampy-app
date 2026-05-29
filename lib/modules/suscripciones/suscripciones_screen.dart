import 'package:flutter/material.dart';
import '../../core/app_cache.dart';
import '../../shared/app_colors.dart';
import 'payment_web_view.dart';
import 'suscripcion_detalle_screen.dart';
import 'suscripcion_model.dart';
import 'suscripcion_service.dart';

class SuscripcionesScreen extends StatefulWidget {
  const SuscripcionesScreen({super.key});

  @override
  State<SuscripcionesScreen> createState() => _SuscripcionesScreenState();
}

class _SuscripcionesScreenState extends State<SuscripcionesScreen> {
  List<MenuConSuscripcion> _menus = [];
  Precio? _precio;
  bool _loading = true;
  String _error = '';
  int? _paying;

  @override
  void initState() {
    super.initState();
    final cachedMenus  = AppCache.get<List<MenuConSuscripcion>>('sus_menus');
    final cachedPrecio = AppCache.get<Precio>('sus_precio');
    if (cachedMenus != null) { _menus = cachedMenus; _loading = false; }
    if (cachedPrecio != null) _precio = cachedPrecio;
    _bgFetch();
  }

  Future<void> _bgFetch() async {
    final results = await Future.wait([
      SuscripcionService.getMenus(),
      SuscripcionService.getPrecio(),
    ]);
    if (!mounted) return;
    final menus  = results[0] as List<MenuConSuscripcion>;
    final precio = results[1] as Precio?;
    AppCache.set('sus_menus', menus);
    if (precio != null) AppCache.set('sus_precio', precio);
    setState(() { _menus = menus; _precio = precio; _loading = false; });
  }

  Future<void> _load() => _bgFetch();

  Future<void> _handlePagar(int menId) async {
    setState(() => _paying = menId);
    final url = await SuscripcionService.iniciarPago(menId);
    if (!mounted) return;
    setState(() => _paying = null);
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al iniciar el pago'),
        backgroundColor: AppColors.kRed,
      ));
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentWebView(url: url),
      ),
    );
  }

  void _goToDetalle(MenuConSuscripcion m) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SuscripcionDetalleScreen(
          menId: m.id,
          menuName: m.displayName,
        ),
      ),
    ).then((_) => _load());
  }

  List<MenuConSuscripcion> get _menusConSus =>
      _menus.where((m) => m.subscription?.estado.isNotEmpty == true).toList();
  List<MenuConSuscripcion> get _menusSinSus =>
      _menus.where((m) => m.subscription == null || m.subscription!.estado.isEmpty).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgPage,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: AppColors.kBlue,
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.kBlue),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  if (_error.isNotEmpty)
                    _buildError(),
                  if (_menus.isEmpty)
                    _buildEmpty()
                  else ...[
                    if (_menusConSus.isNotEmpty) ...[
                      ..._menusConSus.map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MenuSuscripcionCard(
                              menu: m,
                              paying: _paying == m.id,
                              onPagar: () => _handlePagar(m.id),
                              onVerDetalles: () => _goToDetalle(m),
                            ),
                          )),
                    ],
                    if (_menusSinSus.isNotEmpty) ...[
                      const Text(
                        'SIN PUBLICAR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._menusSinSus.map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MenuSuscripcionCard(
                              menu: m,
                              paying: _paying == m.id,
                              onPagar: () => _handlePagar(m.id),
                              onVerDetalles: () => _goToDetalle(m),
                            ),
                          )),
                    ],
                  ],
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.kCardBorder)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      size: 20, color: AppColors.kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
                const Icon(Icons.credit_card_outlined,
                    size: 18, color: AppColors.kBlue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Suscripciones',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final display = _precio?.display ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'Estado de cada menú',
            style: const TextStyle(
                fontSize: 12, color: AppColors.kTextMuted),
            children: display.isNotEmpty
                ? [
                    const TextSpan(text: ' · Precio actual: '),
                    TextSpan(
                      text: '$display/mes',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ]
                : [],
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.kRed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(_error,
          style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.restaurant_menu_outlined,
              size: 32, color: AppColors.kSkeleton),
          SizedBox(height: 12),
          Text(
            'No tienes menús creados aún',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de menú con suscripción ──────────────────────────────────────────

class _MenuSuscripcionCard extends StatelessWidget {
  const _MenuSuscripcionCard({
    required this.menu,
    required this.paying,
    required this.onPagar,
    required this.onVerDetalles,
  });

  final MenuConSuscripcion menu;
  final bool paying;
  final VoidCallback onPagar;
  final VoidCallback onVerDetalles;

  static const _estadoConfig = {
    'PENDING_PAYMENT':    _EstadoInfo('Pago pendiente',    Color(0xFF7C3AED)),
    'WAITING_ACTIVATION': _EstadoInfo('Activando…',        Color(0xFF2563EB)),
    'TRIAL_FREE':         _EstadoInfo('Prueba gratuita',   Color(0xFF059669)),
    'PAYMENT_REMINDER':   _EstadoInfo('Recordatorio pago', Color(0xFFF59E0B)),
    'ACTIVE':             _EstadoInfo('Activa',             Color(0xFF059669)),
    'PAST_DUE':           _EstadoInfo('Vencida (gracia)',   Color(0xFFEA580C)),
    'SUSPENDED':          _EstadoInfo('Suspendida',         Color(0xFFDC2626)),
    'CANCELED':           _EstadoInfo('Cancelada',          Color(0xFF64748B)),
  };

  static String _fmtFecha(DateTime? dt) {
    if (dt == null) return '—';
    const m = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
                'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${dt.day.toString().padLeft(2, '0')} ${m[dt.month]} ${dt.year}';
  }

  static String _fmtCOP(int? centavos) {
    if (centavos == null) return '';
    final val = (centavos / 100).round();
    return '\$$val COP';
  }

  @override
  Widget build(BuildContext context) {
    final sub = menu.subscription;
    final cfg = sub != null
        ? (_estadoConfig[sub.estado] ?? const _EstadoInfo('Suspendida', Color(0xFFDC2626)))
        : null;

    final needsPay = sub?.needsPay ?? false;
    final diasRestantes = sub?.diasRestantes ?? 0;

    // Calcular fechas de período
    final DateTime? triInicio = sub?.trialFin != null
        ? sub!.trialFin!.subtract(const Duration(days: 14))
        : null;
    final DateTime? perInicio = sub?.periodoFin != null
        ? sub!.periodoFin!.subtract(const Duration(days: 30))
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ícono + nombre + badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.kSkeleton,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant_menu_outlined,
                    size: 18, color: AppColors.kTextSecondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '/${menu.slug}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.kTextMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cfg?.color ?? AppColors.kTextMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cfg?.label ?? 'Sin suscripción',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          // Fechas
          if (sub != null &&
              (sub.estado == 'TRIAL_FREE' ||
                  sub.estado == 'PAYMENT_REMINDER')) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _DateCol(label: 'Inicio prueba', value: _fmtFecha(triInicio)),
                _DateCol(label: 'Vence prueba',  value: _fmtFecha(sub.trialFin)),
                _DateCol(
                  label: 'Días restantes',
                  value: '$diasRestantes día${diasRestantes != 1 ? 's' : ''}',
                  highlight: diasRestantes <= 3,
                ),
              ],
            ),
          ] else if (sub != null &&
              (sub.estado == 'ACTIVE' || sub.estado == 'PAST_DUE')) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _DateCol(label: 'Período desde', value: _fmtFecha(perInicio)),
                _DateCol(label: 'Próximo pago',  value: _fmtFecha(sub.periodoFin)),
                _DateCol(
                  label: 'Días restantes',
                  value: '$diasRestantes día${diasRestantes != 1 ? 's' : ''}',
                  highlight: diasRestantes <= 3,
                ),
              ],
            ),
          ],

          // Alerta SUSPENDED
          if (sub?.estado == 'SUSPENDED') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cancel_outlined,
                      size: 13, color: Colors.white),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tu menú está despublicado. Para volver a publicarlo ve al editor y usa el botón Publicar.',
                      style: TextStyle(fontSize: 11, color: Colors.white, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Alerta PAYMENT_REMINDER urgente
          if (sub?.estado == 'PAYMENT_REMINDER' && diasRestantes <= 3) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 13, color: Colors.white),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '¡Quedan solo $diasRestantes día${diasRestantes != 1 ? 's' : ''}! Paga para no perder la publicación.',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Acciones
          const SizedBox(height: 14),
          Row(
            children: [
              if (needsPay)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: paying ? null : onPagar,
                    icon: paying
                        ? const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.credit_card_outlined, size: 13),
                    label: Text(
                      paying
                          ? 'Iniciando…'
                          : 'Pagar ${_fmtCOP(sub?.precioActualCentavos)}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: onVerDetalles,
                icon: const Icon(Icons.chevron_right,
                    size: 13, color: AppColors.kTextMuted),
                label: const Text(
                  'Ver detalles',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.kTextMuted),
                ),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EstadoInfo {
  final String label;
  final Color color;
  const _EstadoInfo(this.label, this.color);
}

class _DateCol extends StatelessWidget {
  const _DateCol({
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.kTextMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: highlight
                  ? AppColors.kRed
                  : AppColors.kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

