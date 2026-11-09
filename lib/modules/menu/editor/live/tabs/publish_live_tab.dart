import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/responsive.dart';

import '../../../../../services/live_editor_service.dart';
import '../../../../../shared/app_colors.dart';
import '../../../../growth/achievements/components/logros_aplicados_section.dart';
import '../../../../subscription/components/subscription_banners.dart';
import '../editor_models.dart';

class PublishLiveTab extends StatefulWidget {
  const PublishLiveTab({
    super.key,
    required this.menu,
    required this.onChanged,
    required this.onSnack,
  });

  final LiveMenu menu;
  final Future<void> Function() onChanged;
  final void Function(String msg, {bool error}) onSnack;

  @override
  State<PublishLiveTab> createState() => _PublishLiveTabState();
}

class _PublishLiveTabState extends State<PublishLiveTab> {
  final _coupon = TextEditingController();
  bool _busy = false;
  bool _slugTaken = false;

  @override
  void initState() {
    super.initState();
    _checkSlug();
  }

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  Future<void> _checkSlug() async {
    final ok = await LiveEditorService.checkSlug(
      widget.menu.slug,
      excludeCodigo: widget.menu.codigo,
    );
    if (mounted) setState(() => _slugTaken = !ok);
  }

  bool get _hasLogo => (widget.menu.info.logoUrl ?? '').isNotEmpty;
  bool get _hasBanner => (widget.menu.info.bannerUrl ?? '').isNotEmpty;
  bool get _hasContact => [
    widget.menu.info.phone,
    widget.menu.info.whatsapp,
    widget.menu.info.email,
  ].any((v) => (v ?? '').trim().isNotEmpty);
  bool get _hasCategories => widget.menu.categories.isNotEmpty;
  bool get _hasProducts => widget.menu.products.isNotEmpty;

  // La foto del producto ya no es obligatoria (el menú muestra el logo como respaldo):
  // un producto solo está "incompleto" si le falta el precio.
  List<LiveProduct> get _incomplete =>
      widget.menu.products.where((p) => p.price <= 0).toList();

  bool get _canPublish =>
      _hasLogo &&
      _hasBanner &&
      _hasContact &&
      _hasCategories &&
      _hasProducts &&
      _incomplete.isEmpty &&
      !_slugTaken;

  Future<void> _publish({bool trial = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await LiveEditorService.publish(widget.menu.codigo, trial: trial);
      await widget.onChanged();
      if (mounted) widget.onSnack('Menú publicado.');
    } catch (e) {
      if (mounted) {
        widget.onSnack(
          e.toString().replaceFirst('Exception: ', ''),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unpublish() async {
    setState(() => _busy = true);
    try {
      await LiveEditorService.unpublish(widget.menu.codigo);
      await widget.onChanged();
      if (mounted) widget.onSnack('Menú despublicado.');
    } catch (e) {
      if (mounted) {
        widget.onSnack(
          e.toString().replaceFirst('Exception: ', ''),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyCoupon() async {
    if (_coupon.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final dias = await LiveEditorService.applyCoupon(
        widget.menu.codigo,
        _coupon.text.trim().toUpperCase(),
      );
      await widget.onChanged();
      _coupon.clear();
      if (mounted) widget.onSnack('Cupón aplicado: $dias días.');
    } catch (e) {
      if (mounted) {
        widget.onSnack(
          e.toString().replaceFirst('Exception: ', ''),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmAndPublish({bool trial = false}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publicar menú'),
        content: const Text(
          'El menú quedará visible para todos en su URL pública.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, publicar'),
          ),
        ],
      ),
    );
    if (ok == true) await _publish(trial: trial);
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.menu.subscription;
    final coupon = widget.menu.cupon;
    final firstPublish = sub.estado.isEmpty && !sub.trialUsado;
    final bloqueadoColaborador =
        !widget.menu.esPropio && (firstPublish || !widget.menu.tieneAcceso);

    return ListView(
      padding: contenidoPadding(context, bottom: 30),
      children: [
        // Avisos de la suscripción (solo el dueño puede consultarla); se recargan al cambiar su estado.
        if (widget.menu.esPropio)
          SubscriptionBanners(
            key: ValueKey('${widget.menu.codigo}-${widget.menu.status}-${sub.estado}'),
            menuCodigo: widget.menu.codigo,
          ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.menu.publicado
                ? const Color(0xFFEEF2FF)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.menu.publicado
                  ? const Color(0xFFC7D2FE)
                  : AppColors.kCardBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.menu.publicado ? 'Publicado' : 'No publicado',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: widget.menu.publicado
                      ? const Color(0xFF4338CA)
                      : AppColors.kTextPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                sub.estado.isEmpty
                    ? 'Sin suscripción activa'
                    : 'Plan: ${sub.tipoPlan ?? '—'} · ${sub.estado}'
                          '${sub.diasRestantes != null ? ' · ${sub.diasRestantes} días' : ''}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.kTextMuted,
                ),
              ),
              if (coupon?.existe == true) ...[
                const SizedBox(height: 4),
                Text(
                  coupon!.activo
                      ? 'Cupón activo · ${coupon.diasRestantes} días'
                      : 'Cupón listo (inicia al publicar) · ${coupon.diasTotal} días',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kBlue,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!widget.menu.publicado && !_canPublish) _requirementsCard(),
        if (!widget.menu.publicado && _canPublish)
          FilledButton.icon(
            onPressed: _busy || bloqueadoColaborador
                ? null
                // Igual que React: con acceso (plan/cupón) se publica; sin acceso se abre la
                // página de planes — donde la prueba gratuita es UNA opción más, no algo forzado.
                : () {
                    if (widget.menu.tieneAcceso) {
                      _confirmAndPublish();
                    } else {
                      context.push('/menus/${widget.menu.codigo}/planes');
                    }
                  },
            icon: const Icon(Icons.rocket_launch_outlined, size: 17),
            label: Text(
              widget.menu.tieneAcceso ? 'Publicar menú' : 'Ver planes',
            ),
          ),
        if (widget.menu.publicado) ...[
          FilledButton.icon(
            onPressed: _busy ? null : _unpublish,
            icon: const Icon(Icons.visibility_off_outlined, size: 17),
            label: const Text('Despublicar'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push('/${widget.menu.slug}'),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Ver menú público'),
          ),
        ],
        if (widget.menu.logrosDias != null && widget.menu.logrosDias! > 0) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.push('/logros'),
            icon: const Icon(Icons.emoji_events_outlined, size: 16),
            label: Text(
              'Aplicar logros (${widget.menu.logrosDias} días disponibles)',
            ),
          ),
        ],
        const SizedBox(height: 18),
        const Text(
          'Cupón',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _coupon,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Código de cupón',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _busy ? null : _applyCoupon,
              child: const Text('Aplicar'),
            ),
          ],
        ),
        if (widget.menu.pendingCheckout) ...[
          const SizedBox(height: 12),
          const Text(
            'Hay un pago pendiente de confirmación. Espera unos segundos o revisa tu suscripción.',
            style: TextStyle(fontSize: 11, color: Colors.orange),
          ),
        ],
        LogrosAplicadosSection(menuCodigo: widget.menu.codigo),
      ],
    );
  }

  Widget _requirementsCard() {
    final missing = <String>[
      if (!_hasLogo) 'Sube el logo.',
      if (!_hasBanner) 'Sube la portada.',
      if (!_hasContact) 'Agrega teléfono, WhatsApp o correo.',
      if (!_hasCategories) 'Agrega al menos una categoría.',
      if (!_hasProducts) 'Agrega al menos un producto.',
      if (_slugTaken) 'El link ya está publicado por otro negocio.',
      for (final p in _incomplete.take(6))
        'Ponle precio a "${p.name}".',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Requisitos para publicar',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          for (final m in missing)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '• $m',
                style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
              ),
            ),
        ],
      ),
    );
  }
}
