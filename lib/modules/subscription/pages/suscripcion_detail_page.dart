import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../components/layout/sidebar.dart';
import '../../../context/notificacion_context.dart';
import '../../../services/suscripcion_service.dart';
import '../../../shared/app_colors.dart';
import '../components/auto_charge_section.dart';
import '../utils/sus_format.dart';

// Equivalente a src/modules/subscription/pages/SuscripcionDetailPage.jsx en React
// (+ hooks/useSuscripcionDetail.js: recarga con el aviso en vivo de suscripción, sin sondeo).

typedef _Cfg = (String label, Color fg, Color bg, Color border, IconData icon);

const Map<String, _Cfg> _estadoCfg = {
  'WAITING_ACTIVATION': (
    'Activando…',
    Color(0xFF1D4ED8),
    Color(0xFFEFF6FF),
    Color(0xFFBFDBFE),
    Icons.autorenew,
  ),
  'TRIAL': (
    'Prueba gratuita',
    Color(0xFF047857),
    Color(0xFFECFDF5),
    Color(0xFFA7F3D0),
    Icons.schedule,
  ),
  'TRIAL_REMINDER': (
    'Prueba por vencer',
    Color(0xFFB45309),
    Color(0xFFFFFBEB),
    Color(0xFFFDE68A),
    Icons.warning_amber_rounded,
  ),
  'PAYMENT_REMINDER': (
    'Por vencer',
    Color(0xFFB45309),
    Color(0xFFFFFBEB),
    Color(0xFFFDE68A),
    Icons.warning_amber_rounded,
  ),
  'ACTIVE': (
    'Activa',
    Color(0xFF047857),
    Color(0xFFECFDF5),
    Color(0xFFA7F3D0),
    Icons.check_circle_outline,
  ),
  'PAST_DUE': (
    'Vencida (en gracia)',
    Color(0xFFC2410C),
    Color(0xFFFFF7ED),
    Color(0xFFFED7AA),
    Icons.warning_amber_rounded,
  ),
  'SUSPENDED': (
    'Suspendida',
    Color(0xFFB91C1C),
    Color(0xFFFEF2F2),
    Color(0xFFFECACA),
    Icons.cancel_outlined,
  ),
  'CANCELED': (
    'Cancelada',
    Color(0xFF475569),
    Color(0xFFF1F5F9),
    Color(0xFFE2E8F0),
    Icons.cancel_outlined,
  ),
};

const Map<String, (String, Color, Color)> _pagoCfg = {
  'APPROVED': ('Aprobado', Color(0xFF047857), Color(0xFFECFDF5)),
  'PENDING': ('Pendiente', Color(0xFFB45309), Color(0xFFFFFBEB)),
  'DECLINED': ('Rechazado', Color(0xFFB91C1C), Color(0xFFFEF2F2)),
  'REJECTED': ('Rechazado', Color(0xFFB91C1C), Color(0xFFFEF2F2)),
  'ERROR': ('Error', Color(0xFFB91C1C), Color(0xFFFEF2F2)),
  'VOIDED': ('Anulado', Color(0xFF475569), Color(0xFFF1F5F9)),
};

const Map<String, String> _metodoLabels = {
  'CARD': 'Tarjeta',
  'PSE': 'PSE',
  'NEQUI': 'Nequi',
  'DAVIPLATA': 'Daviplata',
  'BANCOLOMBIA_TRANSFER': 'Bancolombia',
  'BANCOLOMBIA_COLLECT': 'Bancolombia Collect',
};

class SuscripcionDetailPage extends StatefulWidget {
  const SuscripcionDetailPage({super.key, required this.susId, this.wompiTxId});
  final String susId;

  /// id de la transacción de Wompi al volver de pagar (?id=)
  final String? wompiTxId;

  @override
  State<SuscripcionDetailPage> createState() => _SuscripcionDetailPageState();
}

class _SuscripcionDetailPageState extends State<SuscripcionDetailPage> {
  Map<String, dynamic>? _sus;
  bool _loading = true;
  String _error = '';
  bool _canceling = false;
  bool _expandAutoCharge = false;
  String? _comprobanteAbierto;
  int _ultimoAviso = 0;
  final _autoChargeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ultimoAviso = context.read<NotificacionContext>().suscripcionSeq;
    _load().whenComplete(() {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // El estado nuevo (pago aprobado, recordatorios…) llega por el aviso en vivo.
    final seq = Provider.of<NotificacionContext>(context).suscripcionSeq;
    if (seq != _ultimoAviso) {
      _ultimoAviso = seq;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final data = await SuscripcionService.getMiSuscripcionById(widget.susId);
      if (mounted) {
        setState(() {
          _sus = data;
          _error = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _irACheckout(String tipo) {
    final menId = _sus?['menId'];
    if (menId == null) return;
    context.push('/billing/$menId/checkout?tipo=$tipo');
  }

  Future<void> _confirmarCancelar() async {
    final sus = _sus!;
    final fecha = (sus['periodoFin'] ?? sus['pruebaFin']) as String?;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar suscripción?'),
        content: Text(
          'Tu cobro automático se desactivará y tu menú seguirá publicado'
          '${fecha != null ? ' hasta el ${fmtFecha(fecha)}' : ''}. '
          'Después de esa fecha el menú será suspendido automáticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.kRed),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _canceling = true);
    try {
      await SuscripcionService.cancelarAlFin(widget.susId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', '').isEmpty
                  ? 'Error al cancelar la suscripción.'
                  : e.toString().replaceFirst('Exception: ', ''),
            ),
            backgroundColor: AppColors.kRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _canceling = false);
    }
  }

  void _administrarPago() {
    setState(() => _expandAutoCharge = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _autoChargeKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppSidebar(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mi suscripción',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Mis suscripciones',
          onPressed: () => context.go('/suscripcion'),
        ),
        actions: [
          Builder(
            builder: (ctx) {
              final hasDrawer = Scaffold.maybeOf(ctx)?.hasDrawer ?? false;
              if (!hasDrawer) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.menu, size: 22),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: _load, child: _contenido()),
    );
  }

  Widget _contenido() {
    final sus = _sus;
    final estado = sus?['estado'] as String?;
    final hasSus = estado != null && estado.isNotEmpty;
    final pagos =
        (sus?['pagos'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (widget.wompiTxId != null &&
            (!hasSus || estado == 'WAITING_ACTIVATION')) ...[
          const _Banner(
            variant: _Variant.warning,
            spin: true,
            message:
                'Procesando tu pago. Detectando el resultado automáticamente…',
          ),
          const SizedBox(height: 12),
        ],
        if (_error.isNotEmpty) ...[
          _Banner(variant: _Variant.error, message: _error),
          const SizedBox(height: 12),
        ],
        if (hasSus) ...[_resumen(sus!), const SizedBox(height: 16)],
        if (AutoChargeSection.aplica(sus)) ...[
          AutoChargeSection(
            key: _autoChargeKey,
            sus: sus!,
            onRefresh: _load,
            forceExpand: _expandAutoCharge,
          ),
          const SizedBox(height: 16),
        ],
        if (pagos.isNotEmpty)
          _historial(pagos)
        else if (sus != null)
          _Card(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No hay pagos registrados para esta suscripción.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.kTextSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _resumen(Map<String, dynamic> sus) {
    final estado = sus['estado'] as String;
    final tipoPlan = sus['tipoPlan'] as String?;
    final esTrial = tipoPlan == 'trial';
    final efectivo = esTrial && estado == 'ACTIVE'
        ? 'TRIAL'
        : esTrial && estado == 'PAYMENT_REMINDER'
        ? 'TRIAL_REMINDER'
        : estado;
    final cfg = _estadoCfg[efectivo] ?? _estadoCfg['SUSPENDED']!;
    final acciones = sus['acciones'] as Map?;
    final needsAdquirir = acciones?['mostrarBotonComprar'] == true;
    final needsRenovar = acciones?['mostrarBotonRenovar'] == true;
    final dias = asInt(sus['diasRestantes']) ?? 0;
    final minutos = asInt(sus['minutosRestantes']) ?? 0;
    final tiempo = fmtTiempo(dias, minutos);
    final precio = sus['precioActualCentavos'] ?? sus['precioCobradoCentavos'];
    final canceladaAlFin = sus['canceladaAlFin'] == true;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sus['menuNombre'] as String? ??
                          'Menú #${sus['menId'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Suscripción #${sus['id']} · ${tipoPlan ?? '—'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.kTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cfg.$3,
                  border: Border.all(color: cfg.$4),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cfg.$5, size: 13, color: cfg.$2),
                    const SizedBox(width: 4),
                    Text(
                      cfg.$1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cfg.$2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            runSpacing: 12,
            children: [
              _Dato('Plan', esTrial ? 'Prueba gratuita' : (tipoPlan ?? '—')),
              if (precio != null && precio != 0)
                _Dato('Precio', '${fmtCOP(precio as num)} /mes'),
              if (sus['periodoInicio'] != null)
                _Dato('Desde', fmtFecha(sus['periodoInicio'] as String?)),
              if (sus['periodoFin'] != null)
                _Dato(
                  'Próxima renovación',
                  fmtFecha(sus['periodoFin'] as String?),
                ),
              if (sus['pruebaInicio'] != null)
                _Dato(
                  'Prueba inició',
                  fmtFecha(sus['pruebaInicio'] as String?),
                ),
              if (sus['pruebaFin'] != null)
                _Dato('Prueba vence', fmtFecha(sus['pruebaFin'] as String?)),
              if (minutos > 0 || dias > 0) _Dato('Tiempo restante', tiempo),
              if (sus['tieneTarjetaGuardada'] == true)
                const _Dato(
                  'Pago guardado',
                  'Tarjeta registrada',
                  color: Color(0xFF047857),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (needsAdquirir)
            _Banner(
              variant: esTrial ? _Variant.warning : _Variant.error,
              message: esTrial
                  ? 'Tu prueba gratuita está por vencer.${minutos > 0 ? ' Quedan $tiempo.' : ''} '
                        'Adquiere un plan para seguir publicado.'
                  : 'Tu menú está suspendido. Adquiere un plan para volver a publicarlo.',
            ),
          if (estado == 'PAYMENT_REMINDER' && !esTrial)
            _Banner(
              variant: _Variant.warning,
              message:
                  'Tu suscripción está por vencer.${minutos > 0 ? ' Quedan $tiempo.' : ''} '
                  'Renueva ahora y los días restantes se suman al nuevo período.',
            ),
          if (estado == 'PAST_DUE')
            _Banner(
              variant: _Variant.orange,
              message:
                  'Suscripción vencida. Tienes $tiempo de gracia antes de la suspensión.',
            ),
          if (estado == 'SUSPENDED')
            const _Banner(
              variant: _Variant.error,
              message:
                  'Tu menú está despublicado. Para reactivarlo, renueva tu suscripción.',
            ),
          if (estado == 'WAITING_ACTIVATION')
            const _Banner(
              variant: _Variant.info,
              spin: true,
              message:
                  'Tu pago fue aprobado. Activando suscripción automáticamente…',
            ),
          if (canceladaAlFin)
            _Banner(
              variant: _Variant.warning,
              icon: Icons.block,
              message:
                  'Cancelación programada — tu menú permanecerá activo hasta el '
                  '${fmtFecha((sus['periodoFin'] ?? sus['pruebaFin']) as String?)}. '
                  'Después será suspendido automáticamente.',
            ),
          if (!canceladaAlFin &&
              estado == 'ACTIVE' &&
              !esTrial &&
              sus['periodoFin'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: Color(0xFF047857),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Suscripción activa${sus['cobroAuto'] == true ? ' — se renovará automáticamente' : ' — vence el ${fmtFecha(sus['periodoFin'] as String?)}'}.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (needsAdquirir)
            FilledButton.icon(
              onPressed: () => context.push('/menus/${sus['menId']}/planes'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
              ),
              icon: const Icon(Icons.bolt, size: 16),
              label: const Text('Ver planes disponibles →'),
            ),
          if (needsRenovar) ...[
            if (needsAdquirir) const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _irACheckout('renovacion'),
              icon: const Icon(Icons.credit_card, size: 16),
              label: Text('Renovar suscripción — ${fmtCOP(precio as num?)}'),
            ),
          ],
          if (sus['tieneTarjetaGuardada'] == true && estado == 'ACTIVE')
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _administrarPago,
                icon: const Icon(Icons.settings_outlined, size: 14),
                label: const Text(
                  'Administrar método de pago',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.kTextSecondary,
                ),
              ),
            ),
          if (!canceladaAlFin &&
              !const [
                'SUSPENDED',
                'CANCELED',
                'WAITING_ACTIVATION',
              ].contains(estado))
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _canceling ? null : _confirmarCancelar,
                icon: _canceling
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.block, size: 14),
                label: const Text(
                  'Cancelar suscripción',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _historial(List<Map<String, dynamic>> pagos) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.history, size: 16, color: AppColors.kTextMuted),
              SizedBox(width: 6),
              Text(
                'Historial de pagos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final p in pagos) ...[
            _PagoTile(
              pago: p,
              expanded: _comprobanteAbierto == p['id'],
              onToggle: () => setState(
                () => _comprobanteAbierto = _comprobanteAbierto == p['id']
                    ? null
                    : p['id'] as String?,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _PagoTile extends StatelessWidget {
  const _PagoTile({
    required this.pago,
    required this.expanded,
    required this.onToggle,
  });
  final Map<String, dynamic> pago;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final estado = pago['estado'] as String? ?? '';
    final pc =
        _pagoCfg[estado] ??
        (estado, const Color(0xFF475569), const Color(0xFFF1F5F9));
    final metodo = pago['metodo'] as String?;
    final comprobante = pago['comprovanteUrl'] as String?;
    final tieneComprobante =
        estado == 'APPROVED' && comprobante != null && comprobante.isNotEmpty;
    final inicio = pago['periodoInicio'] as String?;
    final fin = pago['periodoFin'] as String?;
    final motivo = pago['motivoRechazo'] as String?;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.credit_card,
                    size: 15,
                    color: AppColors.kTextMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            fmtCOP(pago['montoCentavos'] as num?),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kTextPrimary,
                            ),
                          ),
                          _Pill(pc.$1, pc.$2, pc.$3),
                          if (metodo != null)
                            Text(
                              _metodoLabels[metodo] ?? metodo,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.kTextSecondary,
                              ),
                            ),
                          if (pago['esAuto'] == true)
                            const _Pill(
                              'Auto',
                              AppColors.kBlue,
                              Color(0xFFEEF2FF),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${fmtFecha(pago['creadoEn'] as String?)}'
                        '${inicio != null && fin != null ? ' · ${fmtFecha(inicio)} → ${fmtFecha(fin)}' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.kTextMuted,
                        ),
                      ),
                      if (motivo != null && motivo.isNotEmpty)
                        Text(
                          motivo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                    ],
                  ),
                ),
                if (tieneComprobante)
                  IconButton(
                    tooltip: expanded
                        ? 'Ocultar comprobante'
                        : 'Ver comprobante',
                    onPressed: onToggle,
                    icon: Icon(
                      expanded
                          ? Icons.expand_less
                          : Icons.receipt_long_outlined,
                      size: 18,
                      color: AppColors.kTextMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (expanded && tieneComprobante)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      comprobante,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (_, _, _) => const Text(
                        'No se pudo cargar el comprobante.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.kTextMuted,
                        ),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(comprobante),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.download_outlined, size: 14),
                    label: const Text(
                      'Descargar imagen',
                      style: TextStyle(fontSize: 12),
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

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.kCardBorder),
    ),
    child: child,
  );
}

class _Dato extends StatelessWidget {
  const _Dato(this.label, this.value, {this.color = AppColors.kTextPrimary});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: 0.5,
    child: Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.fg, this.bg);
  final String text;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
    ),
  );
}

enum _Variant { warning, error, orange, info }

class _Banner extends StatelessWidget {
  const _Banner({
    required this.variant,
    required this.message,
    this.icon,
    this.spin = false,
  });
  final _Variant variant;
  final String message;
  final IconData? icon;
  final bool spin;

  @override
  Widget build(BuildContext context) {
    final (fg, bg, border, defIcon) = switch (variant) {
      _Variant.warning => (
        const Color(0xFF92400E),
        const Color(0xFFFFFBEB),
        const Color(0xFFFDE68A),
        Icons.warning_amber_rounded,
      ),
      _Variant.error => (
        const Color(0xFF991B1B),
        const Color(0xFFFEF2F2),
        const Color(0xFFFECACA),
        Icons.cancel_outlined,
      ),
      _Variant.orange => (
        const Color(0xFF9A3412),
        const Color(0xFFFFF7ED),
        const Color(0xFFFED7AA),
        Icons.warning_amber_rounded,
      ),
      _Variant.info => (
        const Color(0xFF1E40AF),
        const Color(0xFFEFF6FF),
        const Color(0xFFBFDBFE),
        Icons.autorenew,
      ),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: spin
                ? SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                : Icon(icon ?? defIcon, size: 14, color: fg),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 12, color: fg)),
          ),
        ],
      ),
    );
  }
}
