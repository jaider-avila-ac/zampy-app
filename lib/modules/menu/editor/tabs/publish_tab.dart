import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/app_colors.dart';
import '../../../../services/menu_editor_service.dart';
import '../models/editor_menu_model.dart';

// Equivalente a src/modules/menu/editor/tabs/publish/PublishTab.jsx en React
// Incluye: PlanBadgeBar, SubscriptionBanners, StatusCard, RequirementsBlock,
// PublishActions y modal de confirmación.

class PublishTab extends StatefulWidget {
  const PublishTab({
    super.key,
    required this.menu,
    required this.onPublish,
    required this.onUnpublish,
    required this.publishing,
  });

  final EditorMenu menu;
  final Future<void> Function() onPublish;
  final Future<void> Function() onUnpublish;
  final bool publishing;

  @override
  State<PublishTab> createState() => _PublishTabState();
}

class _PublishTabState extends State<PublishTab> {
  bool _confirmOpen = false;
  bool _slugTaken   = false;

  @override
  void initState() {
    super.initState();
    _checkSlug();
  }

  Future<void> _checkSlug() async {
    if (widget.menu.slug.isEmpty) return;
    try {
      final available =
          await MenuEditorService.checkSlug(widget.menu.slug, widget.menu.id);
      if (mounted) setState(() => _slugTaken = !available);
    } catch (_) {}
  }

  // ── Cálculos derivados (equivalente a usePublish hook) ─────────────────────
  EditorSubscription get _sub       => widget.menu.subscription;
  String get _subEstado             => _sub.estado;
  String? get _tipoPlan             => _sub.tipoPlan;
  int    get _limiteProductos       => _sub.limiteProductos ?? 30;
  int    get _productCount          => widget.menu.draft.products.length;

  bool   get _isFirstPublish   => _tipoPlan == null && !_sub.trialUsado;
  bool   get _isPendingPayment => widget.menu.pendingCheckout;
  bool   get _isWaitingAct    => _subEstado == 'WAITING_ACTIVATION';
  bool   get _isAtPlanLimit   =>
      _tipoPlan != 'trial' && _tipoPlan != null && _productCount >= _limiteProductos;

  bool   get _tieneBeneficio {
    final cupon       = widget.menu.cupon;
    final cuponActivo = cupon?['estado'] == 'ACTIVO';
    final tieneLogro  = (widget.menu.logrosDias ?? 0) > 0;
    return cuponActivo || tieneLogro;
  }

  bool   get _hasLogo      => (widget.menu.draft.info.logoUrl   ?? '').isNotEmpty;
  bool   get _hasBanner    => (widget.menu.draft.info.bannerUrl ?? '').isNotEmpty;
  bool   get _hasProducts  => widget.menu.draft.products.isNotEmpty;
  bool   get _hasCategories => widget.menu.draft.categories.isNotEmpty;

  Set<String> get _sinImagenesCatIds => widget.menu.draft.categories
      .where((c) => (c.tipoContenido) == 'sin_imagenes')
      .map((c) => c.id)
      .toSet();

  List<EditorProduct> get _incomplete => widget.menu.draft.products.where((p) {
        final needsImage = !_sinImagenesCatIds.contains(p.categoryId);
        return (!((p.imageUrl ?? '').isNotEmpty) && needsImage) || p.price <= 0;
      }).toList();

  bool   get _canPublish =>
      _hasLogo && _hasBanner && _hasProducts && _hasCategories &&
      _incomplete.isEmpty && !_slugTaken;

  String get _publicUrl => 'https://zammpy.com/menu/${widget.menu.slug}';

  void _onPublishClick() {
    final tieneAcceso = _tieneBeneficio ||
        ['ACTIVE', 'PAYMENT_REMINDER', 'PAST_DUE'].contains(_subEstado) ||
        _isFirstPublish;
    if (tieneAcceso) {
      setState(() => _confirmOpen = true);
    } else {
      context.push('/billing/${widget.menu.id}');
    }
  }

  Future<void> _confirmPublish() async {
    setState(() => _confirmOpen = false);
    try {
      await widget.onPublish();
    } catch (_) {
      if (mounted) context.push('/billing/${widget.menu.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    final sub  = _sub;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [

            // ── Plan badge bar ──────────────────────────────────────────────
            _PlanBadgeBar(
              subEstado:      _subEstado,
              tipoPlan:       _tipoPlan,
              productCount:   _productCount,
              limiteProductos: _limiteProductos,
              isAtPlanLimit:  _isAtPlanLimit,
              onUpgrade:      () => context.push('/billing/${menu.id}'),
            ),
            const SizedBox(height: 16),

            // ── Banners de suscripción ──────────────────────────────────────
            _SubscriptionBanners(
              sub:       sub,
              subEstado: _subEstado,
              menuId:    menu.id,
              isPendingPayment: _isPendingPayment,
              isWaitingAct:     _isWaitingAct,
            ),

            // ── Estado del menú ─────────────────────────────────────────────
            _StatusCard(
              menu:       menu,
              publicUrl:  _publicUrl,
            ),
            const SizedBox(height: 16),

            // ── Requisitos (solo si no puede publicar) ──────────────────────
            if (!_canPublish)
              _RequirementsBlock(
                slugTaken:      _slugTaken,
                hasLogo:        _hasLogo,
                hasBanner:      _hasBanner,
                hasCategories:  _hasCategories,
                hasProducts:    _hasProducts,
                incomplete:     _incomplete,
                sinImagenesCatIds: _sinImagenesCatIds,
                menuSlug:       menu.slug,
              ),
            if (!_canPublish) const SizedBox(height: 16),

            // ── Acciones ────────────────────────────────────────────────────
            _PublishActions(
              isPublished:      menu.isPublished,
              hasDraftChanges:  menu.hasDraftChanges,
              canPublish:       _canPublish,
              isPendingPayment: _isPendingPayment,
              tieneBeneficio:   _tieneBeneficio,
              isWaitingAct:     _isWaitingAct,
              isAtPlanLimit:    _isAtPlanLimit,
              publishing:       widget.publishing,
              onPreview:        () => context.push('/preview/${menu.id}'),
              onPublic:         () => launchUrl(Uri.parse(_publicUrl)),
              onPublishClick:   _onPublishClick,
              onUnpublish:      _showConfirmUnpublish,
            ),
          ],
        ),

        // ── Modal confirmación publicar ─────────────────────────────────────
        if (_confirmOpen)
          _ConfirmModal(
            publishing: widget.publishing,
            onCancel:   () => setState(() => _confirmOpen = false),
            onConfirm:  _confirmPublish,
          ),
      ],
    );
  }

  void _showConfirmUnpublish() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Despublicar menú', style: TextStyle(fontSize: 16)),
        content: const Text(
          'El menú dejará de ser visible al público. Podrás volver a publicarlo cuando quieras.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async { Navigator.pop(ctx); await widget.onUnpublish(); },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Despublicar'),
          ),
        ],
      ),
    );
  }
}

// ── PlanBadgeBar ──────────────────────────────────────────────────────────────
class _PlanBadgeBar extends StatelessWidget {
  const _PlanBadgeBar({
    required this.subEstado,
    required this.tipoPlan,
    required this.productCount,
    required this.limiteProductos,
    required this.isAtPlanLimit,
    required this.onUpgrade,
  });

  final String  subEstado;
  final String? tipoPlan;
  final int     productCount;
  final int     limiteProductos;
  final bool    isAtPlanLimit;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final esTrial    = tipoPlan == 'trial';
    final planNombre = esTrial ? 'Prueba gratuita' : (tipoPlan ?? 'Plan activo');
    final badgeColor = esTrial ? const Color(0xFF16A34A) : AppColors.kBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(planNombre,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Text('$productCount / $limiteProductos productos',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ],
        ),

        // Banner de límite alcanzado
        if (isAtPlanLimit && !esTrial) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_circle_up, size: 16, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Límite de productos alcanzado',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text(
                        'Tienes $productCount de $limiteProductos productos en tu plan. Actualiza para agregar más.',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFDDD6FE)),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onUpgrade,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Actualizar →', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── SubscriptionBanners ───────────────────────────────────────────────────────
class _SubscriptionBanners extends StatelessWidget {
  const _SubscriptionBanners({
    required this.sub,
    required this.subEstado,
    required this.menuId,
    required this.isPendingPayment,
    required this.isWaitingAct,
  });

  final EditorSubscription sub;
  final String subEstado;
  final int    menuId;
  final bool   isPendingPayment;
  final bool   isWaitingAct;

  String _tiempo() {
    final dias = sub.diasRestantes ?? 0;
    final mins = sub.minutosRestantes ?? 0;
    if (dias > 0) return '$dias día${dias != 1 ? 's' : ''}';
    if (mins > 0) return '$mins min';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final ac     = sub.acciones;
    final tiempo = _tiempo();

    return Column(
      children: [
        if (ac['mostrarBannerActivo'] == true) ...[
          _Banner(
            color: const Color(0xFF16A34A),
            bgColor: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFFBBF7D0),
            icon: Icons.star_outline,
            title: 'Prueba gratuita activa${tiempo.isNotEmpty ? ' · $tiempo restantes' : ''}',
            subtitle: 'Tu menú está publicado. Podrás adquirir un plan cuando se active la ventana de aviso.',
          ),
          const SizedBox(height: 10),
        ],

        if (ac['mostrarBannerAviso'] == true) ...[
          _Banner(
            color: const Color(0xFFB45309),
            bgColor: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
            icon: Icons.shopping_cart_outlined,
            title: 'Ventana de aviso${tiempo.isNotEmpty ? ' — $tiempo restantes' : ''}',
            subtitle: 'Tu suscripción está próxima a vencer. Actúa ahora para no perder la publicación.',
            action: ac['mostrarBotonComprar'] == true || ac['mostrarBotonRenovar'] == true
                ? TextButton(
                    onPressed: () => context.push('/billing/$menuId'),
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB45309),
                        padding: EdgeInsets.zero),
                    child: Text(
                        ac['mostrarBotonRenovar'] == true ? 'Renovar →' : 'Adquirir →',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  )
                : null,
          ),
          const SizedBox(height: 10),
        ],

        if (ac['mostrarBannerGracia'] == true) ...[
          _Banner(
            color: const Color(0xFFEA580C),
            bgColor: const Color(0xFFFFF7ED),
            borderColor: const Color(0xFFFED7AA),
            icon: Icons.refresh,
            title: 'Período de gracia${tiempo.isNotEmpty ? ' — $tiempo restantes' : ''}',
            subtitle: 'Renueva ahora y mantén tu precio actual. Si se suspende, deberás contratar al precio vigente.',
            action: ac['mostrarBotonRenovar'] == true
                ? TextButton(
                    onPressed: () => context.push('/billing/$menuId'),
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEA580C),
                        padding: EdgeInsets.zero),
                    child: const Text('Renovar →',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  )
                : null,
          ),
          const SizedBox(height: 10),
        ],

        if (isWaitingAct) ...[
          _Banner(
            color: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFBFDBFE),
            icon: Icons.access_time,
            title: 'Pago aprobado — activando suscripción',
            subtitle: 'Tu pago fue confirmado. Estamos activando tu menú automáticamente. Recarga en unos segundos.',
          ),
          const SizedBox(height: 10),
        ],

        if (isPendingPayment) ...[
          _Banner(
            color: const Color(0xFF7C3AED),
            bgColor: const Color(0xFFF5F3FF),
            borderColor: const Color(0xFFDDD6FE),
            icon: Icons.access_time,
            title: 'Pago pendiente de confirmación',
            subtitle: 'Si ya pagaste, espera unos segundos. Si el pago falló, intenta de nuevo.',
            action: TextButton(
              onPressed: () => context.push('/billing/$menuId'),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED), padding: EdgeInsets.zero),
              child: const Text('Intentar de nuevo',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final Color    color;
  final Color    bgColor;
  final Color    borderColor;
  final IconData icon;
  final String   title;
  final String   subtitle;
  final Widget?  action;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        bgColor,
          border:       Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.85))),
                  if (action case final w?) w,
                ],
              ),
            ),
          ],
        ),
      );
}

// ── StatusCard ────────────────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.menu, required this.publicUrl});
  final EditorMenu menu;
  final String     publicUrl;

  @override
  Widget build(BuildContext context) {
    final published = menu.isPublished;
    final hasDraft  = menu.hasDraftChanges;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('Estado del menú',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),

          // Publicado / Borrador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: published
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  published ? Icons.check_circle : Icons.access_time,
                  size: 18,
                  color: published
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFB45309),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      published
                          ? 'Publicado y visible al público'
                          : 'Borrador — no visible al público aún',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: published
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB45309),
                      ),
                    ),
                    if (published && menu.publishedAt != null)
                      Text(
                        'Última publicación: ${_fmtDate(menu.publishedAt!)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A)),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Cambios sin publicar
          if (published && hasDraft) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_outlined, size: 16, color: Color(0xFFF59E0B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tienes cambios sin publicar. Publica para que sean visibles.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Info rows
          _InfoRow(
            icon: Icons.language_outlined,
            label: 'URL pública',
            value: publicUrl,
            onTap: () => launchUrl(Uri.parse(publicUrl)),
          ),
          _InfoRow(
            icon: Icons.fastfood_outlined,
            label: 'Productos',
            value: '${menu.draft.products.length} productos',
          ),
          _InfoRow(
            icon: Icons.category_outlined,
            label: 'Categorías',
            value: '${menu.draft.categories.length} categorías',
            isLast: true,
          ),
        ],
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.isLast = false,
  });

  final IconData   icon;
  final String     label;
  final String     value;
  final VoidCallback? onTap;
  final bool       isLast;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: onTap != null ? AppColors.kBlue : const Color(0xFF0F172A),
                      decoration: onTap != null ? TextDecoration.underline : null,
                      decorationColor: AppColors.kBlue,
                    ),
                    overflow: TextOverflow.ellipsis,
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

// ── RequirementsBlock ─────────────────────────────────────────────────────────
class _RequirementsBlock extends StatelessWidget {
  const _RequirementsBlock({
    required this.slugTaken,
    required this.hasLogo,
    required this.hasBanner,
    required this.hasCategories,
    required this.hasProducts,
    required this.incomplete,
    required this.sinImagenesCatIds,
    required this.menuSlug,
  });

  final bool             slugTaken;
  final bool             hasLogo;
  final bool             hasBanner;
  final bool             hasCategories;
  final bool             hasProducts;
  final List<EditorProduct> incomplete;
  final Set<String>      sinImagenesCatIds;
  final String           menuSlug;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          border: Border.all(color: const Color(0xFFFDE68A)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_outlined, size: 15, color: Color(0xFFB45309)),
                SizedBox(width: 6),
                Text('Requisitos para publicar',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309))),
              ],
            ),
            const SizedBox(height: 8),

            if (slugTaken)
              _Req('El dominio /$menuSlug ya está publicado por otro negocio. Cámbialo en la pestaña Información.'),
            if (!hasLogo)
              _Req('Sube el logo del negocio en la pestaña Información.'),
            if (!hasBanner)
              _Req('Sube la portada (banner) del menú en la pestaña Información.'),
            if (!hasCategories)
              _Req('Agrega al menos una categoría en la pestaña Categorías.'),
            if (!hasProducts)
              _Req('Agrega al menos un producto en la pestaña Productos.'),

            if (incomplete.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${incomplete.length} producto${incomplete.length != 1 ? 's' : ''} sin imagen o sin precio:',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                ),
              ),
              ...incomplete.map((p) {
                final needsImage = !sinImagenesCatIds.contains(p.categoryId);
                final missingImg  = (p.imageUrl ?? '').isEmpty && needsImage;
                final missingPrc  = p.price <= 0;
                final label       = missingImg && missingPrc
                    ? '(sin imagen y sin precio)'
                    : missingImg
                        ? '(sin imagen)'
                        : '(sin precio)';
                return Padding(
                  padding: const EdgeInsets.only(top: 2, left: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: CircleAvatar(
                            radius: 2.5, backgroundColor: Color(0xFFF59E0B)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${p.name} $label',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      );
}

class _Req extends StatelessWidget {
  const _Req(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ',
                style: TextStyle(fontSize: 11, color: Color(0xFFB45309),
                    fontWeight: FontWeight.w700)),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFB45309))),
            ),
          ],
        ),
      );
}

// ── PublishActions ────────────────────────────────────────────────────────────
class _PublishActions extends StatelessWidget {
  const _PublishActions({
    required this.isPublished,
    required this.hasDraftChanges,
    required this.canPublish,
    required this.isPendingPayment,
    required this.tieneBeneficio,
    required this.isWaitingAct,
    required this.isAtPlanLimit,
    required this.publishing,
    required this.onPreview,
    required this.onPublic,
    required this.onPublishClick,
    required this.onUnpublish,
  });

  final bool isPublished;
  final bool hasDraftChanges;
  final bool canPublish;
  final bool isPendingPayment;
  final bool tieneBeneficio;
  final bool isWaitingAct;
  final bool isAtPlanLimit;
  final bool publishing;

  final VoidCallback onPreview;
  final VoidCallback onPublic;
  final VoidCallback onPublishClick;
  final VoidCallback onUnpublish;

  bool get _publishDisabled =>
      !canPublish ||
      (isPendingPayment && !tieneBeneficio) ||
      isWaitingAct ||
      (isAtPlanLimit && !tieneBeneficio);

  String get _publishLabel {
    if (isPublished && hasDraftChanges) return 'Republicar cambios';
    if (isPublished) return 'Republicar';
    return 'Publicar menú';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Preview
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPreview,
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('Abrir preview'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            // Ver menú público (solo si publicado)
            if (isPublished) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPublic,
                  icon: const Icon(Icons.language_outlined, size: 14),
                  label: const Text('Ver público'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF16A34A),
                    side: const BorderSide(color: Color(0xFFBBF7D0)),
                    backgroundColor: const Color(0xFFF0FDF4),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            const SizedBox(width: 8),

            // Publicar
            Expanded(
              child: FilledButton.icon(
                onPressed: (_publishDisabled || publishing) ? null : onPublishClick,
                icon: publishing
                    ? const SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.rocket_launch_outlined, size: 14),
                label: Text(_publishLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.kBlue,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),

        if (isPublished) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: onUnpublish,
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF94A3B8)),
              child: const Text('Despublicar menú',
                  style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Modal de confirmación ─────────────────────────────────────────────────────
class _ConfirmModal extends StatelessWidget {
  const _ConfirmModal({
    required this.publishing,
    required this.onCancel,
    required this.onConfirm,
  });

  final bool publishing;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCancel,
      child: Container(
        color: Colors.black45,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.rocket_launch_outlined, size: 18, color: AppColors.kBlue),
                      SizedBox(width: 8),
                      Text('Publicar menú',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'El menú quedará visible para todos en la URL pública.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: publishing ? null : onConfirm,
                          icon: publishing
                              ? const SizedBox(
                                  width: 12, height: 12,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.rocket_launch_outlined, size: 14),
                          label: const Text('Sí, publicar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.kBlue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
