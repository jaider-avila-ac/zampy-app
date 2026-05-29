import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_cache.dart';
import '../../shared/app_colors.dart';
import 'payment_web_view.dart';
import 'suscripcion_detalle_model.dart';
import 'suscripcion_service.dart';

class SuscripcionDetalleScreen extends StatefulWidget {
  const SuscripcionDetalleScreen({
    super.key,
    required this.menId,
    required this.menuName,
  });

  final int menId;
  final String menuName;

  @override
  State<SuscripcionDetalleScreen> createState() =>
      _SuscripcionDetalleScreenState();
}

class _SuscripcionDetalleScreenState extends State<SuscripcionDetalleScreen> {
  SuscripcionDetalle? _sus;
  bool _loading = true;
  bool _paying = false;
  String _error = '';
  String _selectedPlan = 'gratuito';
  Timer? _pollTimer;

  String get _cacheKey => 'sus_detalle_${widget.menId}';

  @override
  void initState() {
    super.initState();
    final cached = AppCache.get<SuscripcionDetalle>(_cacheKey);
    if (cached != null) {
      _sus = cached;
      _loading = false;
      _selectedPlan = !cached.hasSus
          ? (cached.trialUsado ? 'basico' : 'gratuito')
          : 'gratuito';
    }
    _bgFetch();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _bgFetch() async {
    final data = await SuscripcionService.getMiSuscripcion(widget.menId);
    if (!mounted) return;
    if (data != null) AppCache.set(_cacheKey, data);
    setState(() {
      _sus = data;
      _loading = false;
      if (data != null && !data.hasSus) {
        _selectedPlan = data.trialUsado ? 'basico' : 'gratuito';
      }
    });
    _updatePolling();
  }

  Future<void> _load() => _bgFetch();

  void _updatePolling() {
    _pollTimer?.cancel();
    final estado = _sus?.estado;
    if (estado == 'PENDING_PAYMENT' || estado == 'WAITING_ACTIVATION') {
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
        final data = await SuscripcionService.getMiSuscripcion(widget.menId);
        if (!mounted) return;
        setState(() => _sus = data);
        if (data?.estado != 'PENDING_PAYMENT' &&
            data?.estado != 'WAITING_ACTIVATION') {
          _pollTimer?.cancel();
        }
      });
    }
  }

  Future<void> _openCheckout(String url) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentWebView(url: url)),
    );
    await _load();
  }

  Future<void> _handlePagar() async {
    setState(() { _paying = true; _error = ''; });
    final url = await SuscripcionService.iniciarPago(widget.menId);
    if (!mounted) return;
    setState(() => _paying = false);
    if (url == null) {
      setState(() => _error = 'Error al iniciar el pago');
      return;
    }
    await _openCheckout(url);
  }

  Future<void> _handleCheckout([String? planOverride]) async {
    final plan = planOverride ?? _selectedPlan;
    if (plan == 'gratuito') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ve al editor de menú para publicar con prueba gratuita'),
        backgroundColor: AppColors.kTextSecondary,
        duration: Duration(seconds: 3),
      ));
      return;
    }
    setState(() { _paying = true; _error = ''; });
    final url = await SuscripcionService.iniciarCheckout(widget.menId, plan);
    if (!mounted) return;
    setState(() => _paying = false);
    if (url == null) {
      setState(() => _error = 'Error al iniciar el pago');
      return;
    }
    await _openCheckout(url);
  }

  static String _fmtCOP(int centavos) {
    final pesos = (centavos / 100).round();
    return '\$$pesos COP';
  }

  static String _fmtFecha(DateTime? dt) {
    if (dt == null) return '—';
    const m = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
                'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${dt.day.toString().padLeft(2, '0')} ${m[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgPage,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.kBlue),
              ),
            )
          : RefreshIndicator(
              color: AppColors.kBlue,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (_error.isNotEmpty) _buildError(),
                  if (_sus != null && _sus!.hasSus) ...[
                    _buildEstadoCard(),
                    const SizedBox(height: 16),
                  ],
                  if (_sus?.pagos.isNotEmpty == true) ...[
                    _buildHistorialCard(),
                    const SizedBox(height: 16),
                  ],
                  if (_sus != null && !_sus!.hasSus && _error.isEmpty)
                    _buildSelectorPlan(),
                ],
              ),
            ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
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
                Expanded(
                  child: Text(
                    widget.menuName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kTextPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────
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

  // ── Estado de suscripción ──────────────────────────────────────────────────
  Widget _buildEstadoCard() {
    final sus = _sus!;
    final cfg = _estadoConfig[sus.estado] ??
        const _EstadoCfg('Suspendida', Color(0xFFDC2626), Color(0xFFFEE2E2),
            Color(0xFFFCA5A5), Icons.cancel_outlined);

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
          // Título + badge
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Estado de suscripción',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.kTextPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cfg.bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cfg.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cfg.icon, size: 12, color: cfg.textColor),
                    const SizedBox(width: 4),
                    Text(
                      cfg.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cfg.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Grid de fechas
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              if (sus.pruebaInicio != null)
                _InfoField('Prueba inició', _fmtFecha(sus.pruebaInicio)),
              if (sus.pruebaFin != null)
                _InfoField('Prueba vence', _fmtFecha(sus.pruebaFin)),
              if (sus.periodoInicio != null)
                _InfoField('Período desde', _fmtFecha(sus.periodoInicio)),
              if (sus.periodoFin != null)
                _InfoField('Período hasta', _fmtFecha(sus.periodoFin)),
              if (sus.diasRestantes > 0)
                _InfoField('Días restantes', '${sus.diasRestantes}'),
              _InfoField('Precio actual',
                  '${_fmtCOP(sus.precioActualCentavos)} / mes'),
            ],
          ),
          const SizedBox(height: 14),

          // Alertas contextuales
          if (sus.estado == 'PAYMENT_REMINDER') ...[
            _buildAlertBox(
              color: const Color(0xFFFFFBEB),
              border: const Color(0xFFFDE68A),
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFB45309),
              text:
                  'Tu prueba gratuita va en los últimos 7 días. Paga antes de que venza para evitar que tu menú se despublique. '
                  'Quedan ${sus.diasRestantes} día${sus.diasRestantes != 1 ? 's' : ''}.',
              textColor: const Color(0xFF92400E),
            ),
            const SizedBox(height: 12),
          ],
          if (sus.estado == 'PAST_DUE') ...[
            _buildAlertBox(
              color: const Color(0xFFFFF7ED),
              border: const Color(0xFFFED7AA),
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFEA580C),
              text:
                  'Suscripción vencida. Tienes ${sus.diasRestantes} día${sus.diasRestantes != 1 ? 's' : ''} '
                  'de gracia antes de que tu menú sea suspendido.',
              textColor: const Color(0xFF9A3412),
            ),
            const SizedBox(height: 12),
          ],
          if (sus.estado == 'SUSPENDED') ...[
            _buildAlertBox(
              color: const Color(0xFFFEF2F2),
              border: const Color(0xFFFECACA),
              icon: Icons.cancel_outlined,
              iconColor: const Color(0xFFDC2626),
              text:
                  'Tu menú está despublicado. Para volver a publicarlo ve al editor y usa el botón Publicar.',
              textColor: const Color(0xFF991B1B),
            ),
            const SizedBox(height: 12),
          ],
          if (sus.isWaitingAct) ...[
            _buildAlertBox(
              color: const Color(0xFFEFF6FF),
              border: const Color(0xFFBFDBFE),
              icon: Icons.refresh_rounded,
              iconColor: const Color(0xFF2563EB),
              text: 'Tu pago fue aprobado. Activando tu suscripción automáticamente…',
              textColor: const Color(0xFF1E40AF),
              spinning: true,
            ),
            const SizedBox(height: 12),
          ],
          if (sus.isPending) ...[
            _buildAlertBox(
              color: const Color(0xFFF5F3FF),
              border: const Color(0xFFDDD6FE),
              icon: Icons.access_time_rounded,
              iconColor: const Color(0xFF7C3AED),
              text:
                  'Si ya completaste el pago en Wompi, el menú se publicará automáticamente en unos segundos. '
                  'Si el pago falló o lo cancelaste, intenta de nuevo.',
              textColor: const Color(0xFF4C1D95),
            ),
            const SizedBox(height: 12),
            _buildPrimaryButton(
              icon: Icons.credit_card_outlined,
              label: 'Intentar pago de nuevo',
              onPressed: () => _handleCheckout(sus.tipoPlan),
            ),
          ],
          if (sus.needsPay)
            _buildPrimaryButton(
              icon: Icons.credit_card_outlined,
              label:
                  'Pagar ${_fmtCOP(sus.precioActualCentavos)} con Wompi',
              onPressed: _handlePagar,
            ),
          if (sus.estado == 'TRIAL_FREE') ...[
            _buildSecondaryButton(
              icon: Icons.credit_card_outlined,
              label: 'Pagar ahora y saltar la prueba',
              onPressed: _handlePagar,
            ),
          ],
          if (sus.estado == 'ACTIVE') ...[
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 13, color: Color(0xFF059669)),
                const SizedBox(width: 6),
                Text(
                  'Suscripción activa — se renovará el ${_fmtFecha(sus.periodoFin)}.',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF059669)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Historial de pagos ─────────────────────────────────────────────────────
  Widget _buildHistorialCard() {
    final pagos = _sus!.pagos;
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
          const Text(
            'Historial de pagos',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.kTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...pagos.map((p) => _PagoRow(pago: p, fmtFecha: _fmtFecha, fmtCOP: _fmtCOP)),
        ],
      ),
    );
  }

  // ── Sin suscripción — selector de plan ────────────────────────────────────
  Widget _buildSelectorPlan() {
    final sus = _sus!;
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
          const Text(
            'Elige tu plan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.kTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Selecciona el plan que mejor se adapte a tu negocio.',
            style: TextStyle(fontSize: 11, color: AppColors.kTextMuted),
          ),
          const SizedBox(height: 14),
          if (!sus.trialUsado)
            _PlanCard(
              icon: Icons.eco_outlined,
              iconColor: const Color(0xFF059669),
              title: 'Prueba gratuita',
              description: '7 días gratis, sin tarjeta de crédito',
              price: 'Gratis',
              selected: _selectedPlan == 'gratuito',
              onTap: () => setState(() => _selectedPlan = 'gratuito'),
            ),
          _PlanCard(
            icon: Icons.credit_card_outlined,
            iconColor: AppColors.kBlue,
            title: 'Básico',
            description: 'Hasta ${sus.limiteBasicoPlan ?? 30} productos',
            price: sus.precioBasicoCentavos != null
                ? _fmtCOP(sus.precioBasicoCentavos!)
                : '—',
            perMonth: true,
            selected: _selectedPlan == 'basico',
            onTap: () => setState(() => _selectedPlan = 'basico'),
          ),
          _PlanCard(
            icon: Icons.bolt_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: 'Avanzado',
            description: 'Hasta ${sus.limiteAvanzadoPlan ?? 100} productos',
            price: sus.precioAvanzadoCentavos != null
                ? _fmtCOP(sus.precioAvanzadoCentavos!)
                : '—',
            perMonth: true,
            selected: _selectedPlan == 'avanzado',
            onTap: () => setState(() => _selectedPlan = 'avanzado'),
          ),
          const SizedBox(height: 14),
          if (_selectedPlan == 'gratuito')
            _buildSecondaryButton(
              icon: Icons.eco_outlined,
              label: 'Iniciar prueba gratuita',
              onPressed: () => _handleCheckout('gratuito'),
            )
          else
            _buildPrimaryButton(
              icon: Icons.credit_card_outlined,
              label: _selectedPlan == 'avanzado'
                  ? 'Suscribirme al plan avanzado — ${sus.precioAvanzadoCentavos != null ? _fmtCOP(sus.precioAvanzadoCentavos!) : ''}/mes'
                  : 'Suscribirme al plan básico — ${sus.precioBasicoCentavos != null ? _fmtCOP(sus.precioBasicoCentavos!) : ''}/mes',
              onPressed: _paying ? null : () => _handleCheckout(),
            ),
        ],
      ),
    );
  }

  // ── Helpers de botones ─────────────────────────────────────────────────────
  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _paying ? null : onPressed,
        icon: _paying
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 14),
        label: Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _paying ? null : onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kSkeleton,
          foregroundColor: AppColors.kTextPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildAlertBox({
    required Color color,
    required Color border,
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
    bool spinning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          spinning
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: iconColor),
                )
              : Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12, color: textColor, height: 1.5)),
          ),
        ],
      ),
    );
  }

  // ── Config de estados ──────────────────────────────────────────────────────
  static const _estadoConfig = {
    'PENDING_PAYMENT': _EstadoCfg('Pago pendiente', Color(0xFF6D28D9),
        Color(0xFFF5F3FF), Color(0xFFDDD6FE), Icons.access_time_rounded),
    'WAITING_ACTIVATION': _EstadoCfg('Activando…', Color(0xFF2563EB),
        Color(0xFFEFF6FF), Color(0xFFBFDBFE), Icons.access_time_rounded),
    'TRIAL_FREE': _EstadoCfg('Prueba gratuita', Color(0xFF059669),
        Color(0xFFECFDF5), Color(0xFFA7F3D0), Icons.access_time_rounded),
    'PAYMENT_REMINDER': _EstadoCfg('Recordatorio de pago', Color(0xFFB45309),
        Color(0xFFFFFBEB), Color(0xFFFDE68A), Icons.warning_amber_rounded),
    'ACTIVE': _EstadoCfg('Activa', Color(0xFF059669), Color(0xFFECFDF5),
        Color(0xFFA7F3D0), Icons.check_circle_outline),
    'PAST_DUE': _EstadoCfg('Vencida (gracia)', Color(0xFFEA580C),
        Color(0xFFFFF7ED), Color(0xFFFED7AA), Icons.warning_amber_rounded),
    'SUSPENDED': _EstadoCfg('Suspendida', Color(0xFFDC2626),
        Color(0xFFFEF2F2), Color(0xFFFECACA), Icons.cancel_outlined),
    'CANCELED': _EstadoCfg('Cancelada', Color(0xFF64748B),
        Color(0xFFF8FAFC), Color(0xFFE2E8F0), Icons.cancel_outlined),
  };
}

// ── Info field ────────────────────────────────────────────────────────────────
class _InfoField extends StatelessWidget {
  const _InfoField(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.kTextMuted)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.kTextPrimary,
              )),
        ],
      ),
    );
  }
}

// ── Fila de pago ──────────────────────────────────────────────────────────────
class _PagoRow extends StatelessWidget {
  const _PagoRow({
    required this.pago,
    required this.fmtFecha,
    required this.fmtCOP,
  });
  final Pago pago;
  final String Function(DateTime?) fmtFecha;
  final String Function(int) fmtCOP;

  static const _pagoConfig = {
    'APPROVED': _PagoCfg('Aprobado', Color(0xFF059669), Color(0xFFECFDF5)),
    'PENDING':  _PagoCfg('Pendiente', Color(0xFFB45309), Color(0xFFFFFBEB)),
    'DECLINED': _PagoCfg('Rechazado', Color(0xFFDC2626), Color(0xFFFEF2F2)),
    'ERROR':    _PagoCfg('Error', Color(0xFFDC2626), Color(0xFFFEF2F2)),
    'VOIDED':   _PagoCfg('Anulado', Color(0xFF64748B), Color(0xFFF8FAFC)),
  };

  static const _metodoLabels = {
    'CARD': 'Tarjeta',
    'PSE': 'PSE',
    'NEQUI': 'Nequi',
    'BANCOLOMBIA_TRANSFER': 'Bancolombia',
    'BANCOLOMBIA_COLLECT': 'Bancolombia Collect',
  };

  @override
  Widget build(BuildContext context) {
    final pc = _pagoConfig[pago.estado] ??
        const _PagoCfg('Desconocido', Color(0xFF64748B), Color(0xFFF8FAFC));
    final metodo = _metodoLabels[pago.metodo] ?? pago.metodo;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.kBgPage,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card_outlined,
              size: 15, color: AppColors.kTextMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      fmtCOP(pago.montoCentavos),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: pc.bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pc.label,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: pc.text),
                      ),
                    ),
                    if (metodo != null)
                      Text(metodo,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.kTextMuted)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    fmtFecha(pago.creadoEn),
                    if (pago.periodoInicio != null && pago.periodoFin != null)
                      '${fmtFecha(pago.periodoInicio)} → ${fmtFecha(pago.periodoFin)}',
                  ].join(' · '),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.kTextMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de plan ───────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.price,
    required this.selected,
    required this.onTap,
    this.perMonth = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String price;
  final bool selected;
  final VoidCallback onTap;
  final bool perMonth;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.kBlue : AppColors.kCardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFE0E7FF)
                    : AppColors.kSkeleton,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextPrimary,
                      )),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.kTextMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.kTextPrimary,
                    )),
                if (perMonth)
                  const Text('/ mes',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.kTextMuted)),
              ],
            ),
            const SizedBox(width: 10),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.kBlue : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.kBlue : AppColors.kCardBorder,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Center(
                      child: CircleAvatar(
                          radius: 3, backgroundColor: Colors.white))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Config helpers ────────────────────────────────────────────────────────────
class _EstadoCfg {
  final String label;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;
  const _EstadoCfg(
      this.label, this.textColor, this.bgColor, this.borderColor, this.icon);
}

class _PagoCfg {
  final String label;
  final Color text;
  final Color bg;
  const _PagoCfg(this.label, this.text, this.bg);
}
