import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart' hide MenuTheme;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../context/auth_context.dart';
import '../../../../services/interaccion_service.dart';
import '../models/public_menu_model.dart';

// Equivalente a src/components/ProductModal.jsx en React

class ProductModal extends StatefulWidget {
  const ProductModal({
    super.key,
    required this.product,
    required this.theme,
    this.menuSlug,
    this.info,
    this.grupos = const [],
  });

  final MenuProduct     product;
  final MenuTheme       theme;
  final String?         menuSlug;
  final MenuInfo?       info;
  final List<MenuGrupo> grupos;

  static Future<void> show(
    BuildContext context,
    MenuProduct product,
    MenuTheme theme, {
    String?        menuSlug,
    MenuInfo?      info,
    List<MenuGrupo> grupos = const [],
  }) {
    return showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      barrierColor:       Colors.black.withValues(alpha: 0.68),
      builder: (_) => ProductModal(
        product:  product,
        theme:    theme,
        menuSlug: menuSlug,
        info:     info,
        grupos:   grupos,
      ),
    );
  }

  @override
  State<ProductModal> createState() => _ProductModalState();
}

class _ProductModalState extends State<ProductModal> {
  double _avgRating  = 0;
  int    _myRating   = 0;
  bool   _submitting = false;
  bool   _ratedToast = false;
  Timer? _toastTimer;

  String?              _selectedSizeId;
  final List<String>   _selIngredients = [];
  final List<String>   _selExtras      = [];
  final Map<String, Set<String>> _selGrupos = {};

  @override
  void initState() {
    super.initState();
    _avgRating      = widget.product.rating ?? 0;
    // Auto-selecciona el primer tamaño igual que React
    _selectedSizeId = widget.product.sizes.isNotEmpty
        ? widget.product.sizes.first.id
        : null;
    _loadMyRating();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  ProductSize? get _sizeObj => _selectedSizeId == null
      ? null
      : widget.product.sizes.where((s) => s.id == _selectedSizeId).firstOrNull;

  double get _displayPrice {
    final p       = widget.product;
    final sizeObj = _sizeObj;
    final base    = sizeObj != null
        ? sizeObj.price
        : (p.hasPromo ? p.promoPrice! : p.price);
    final ingAdd  = _selIngredients
        .map((id) => p.ingredients.where((i) => i.id == id).firstOrNull?.price ?? 0.0)
        .fold<double>(0, (a, b) => a + b);
    final extAdd  = _selExtras
        .map((id) => p.extras.where((e) => e.id == id).firstOrNull?.price ?? 0.0)
        .fold<double>(0, (a, b) => a + b);
    return base + ingAdd + extAdd;
  }

  // Precio original tachado: solo si hay promo Y no hay tamaño seleccionado
  double? get _originalPrice {
    final p = widget.product;
    return (p.hasPromo && _sizeObj == null) ? p.price : null;
  }

  bool get _hasVariants =>
      widget.product.sizes.isNotEmpty ||
      widget.product.ingredients.isNotEmpty ||
      widget.product.extras.isNotEmpty;

  List<MenuGrupo> get _visibleGrupos => widget.product.grupoIds
      .map((id) => widget.grupos.where((g) => g.id == id && g.isActive).firstOrNull)
      .whereType<MenuGrupo>()
      .toList();

  // ── Interactions ──────────────────────────────────────────────────────────

  void _toggleMulti(String id, List<String> list) {
    setState(() {
      if (list.contains(id)) { list.remove(id); } else { list.add(id); }
    });
  }

  void _toggleGrupoItem(String grupoId, String itemName) {
    setState(() {
      final set = _selGrupos.putIfAbsent(grupoId, () => {});
      if (set.contains(itemName)) { set.remove(itemName); } else { set.add(itemName); }
    });
  }

  Future<void> _loadMyRating() async {
    if (widget.menuSlug == null || widget.product.id.isEmpty) { return; }
    if (!context.read<AuthContext>().isLoggedIn) { return; }
    final data = await InteraccionService.miCalificacion(
        widget.menuSlug!, widget.product.id);
    if (data != null && mounted) {
      setState(() => _myRating = (data['estrellas'] as num?)?.toInt() ?? 0);
    }
  }

  Future<void> _handleRate(int stars) async {
    if (!context.read<AuthContext>().isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Inicia sesión para calificar'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (widget.menuSlug == null || _submitting) { return; }
    setState(() => _submitting = true);
    try {
      final data = await InteraccionService.calificar(
          widget.menuSlug!, widget.product.id, stars);
      if (data != null && mounted) {
        setState(() {
          _myRating   = stars;
          _avgRating  = (data['promedio'] as num?)?.toDouble() ?? stars.toDouble();
          _ratedToast = true;
        });
        _toastTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _ratedToast = false);
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Construye el mensaje de WhatsApp incluyendo selecciones — igual que React
  String _buildWaMessage() {
    final p       = widget.product;
    final sizeObj = _sizeObj;
    final lines   = <String>['Hola, quiero hacer un pedido:\n*${p.name}*'];
    if (sizeObj != null) lines.add('• Tamaño: ${sizeObj.label}');
    if (_selIngredients.isNotEmpty) {
      final names = _selIngredients
          .map((id) => p.ingredients.where((i) => i.id == id).firstOrNull?.label)
          .whereType<String>()
          .join(', ');
      if (names.isNotEmpty) lines.add('• Personalización: $names');
    }
    if (_selExtras.isNotEmpty) {
      final names = _selExtras
          .map((id) => p.extras.where((e) => e.id == id).firstOrNull?.label)
          .whereType<String>()
          .join(', ');
      if (names.isNotEmpty) lines.add('• Adiciones: $names');
    }
    for (final g in _visibleGrupos) {
      final sel = _selGrupos[g.id] ?? {};
      if (sel.isNotEmpty) lines.add('• ${g.name}: ${sel.join(', ')}');
    }
    final price = _displayPrice;
    if (price > 0) lines.add('\nTotal: \$${_fmt(price)}');
    lines.add(
        '\nPor favor indícame tu *nombre completo* y *dirección de entrega* para coordinar el pedido.');
    return lines.join('\n');
  }

  void _openImageViewer(String imgSrc) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => _ImageViewer(
        imgSrc:      imgSrc,
        name:        widget.product.name,
        cardRadius:  widget.theme.cardRadius,
        surfaceColor: widget.theme.surface,
        textColor:   widget.theme.text,
      ),
      transitionBuilder: (_, anim, secondAnim, child) {
        final scale = Tween<double>(begin: 0.80, end: 1.0).animate(
          CurvedAnimation(
            parent:       anim,
            curve:        const Cubic(0.34, 1.56, 0.64, 1),
            reverseCurve: Curves.easeIn,
          ),
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
          child:   ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  Future<void> _openWhatsapp() async {
    final info   = widget.info;
    final raw    = info?.whatsapp?.isNotEmpty == true
        ? info!.whatsapp!
        : (info?.phone ?? '');
    if (raw.isEmpty) return;
    final number  = raw.replaceAll(RegExp(r'\D'), '');
    final encoded = Uri.encodeComponent(_buildWaMessage());
    final url     = Uri.parse('https://wa.me/$number?text=$encoded');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static String _fmt(double p) {
    final s   = p.toStringAsFixed(0);
    final buf = StringBuffer();
    int   c   = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (c > 0 && c % 3 == 0) buf.write('.');
      buf.write(s[i]);
      c++;
    }
    return buf.toString().split('').reversed.join();
  }

  // ── Build helpers ─────────────────────────────────────────────────────────

  // Selector de variantes — equivale a VariantSelector.jsx
  // title: label de sección, items: lista de (id, label, price)
  // multi: true=multi-select, false=single-select
  Widget _variantSelector({
    required MenuTheme t,
    required String title,
    required List<({String id, String label, double price})> items,
    required bool multi,
    required bool Function(String id) isSelected,
    required void Function(String id) onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1, color: t.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: items.map((item) {
              final active = isSelected(item.id);
              return GestureDetector(
                onTap: () => onSelect(item.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:        active ? t.primary : t.surfaceAlt,
                    borderRadius: BorderRadius.circular(t.badgeRadius),
                    border:       Border.all(
                      color: active ? t.primary : t.border,
                      width: 1.5,
                    ),
                  ),
                  child: Text.rich(TextSpan(
                    text: item.label,
                    style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                      color:      active ? Colors.white : t.text,
                    ),
                    children: item.price > 0
                        ? [
                            TextSpan(
                              text: ' +\$${_fmt(item.price)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                color:      active
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : t.textMuted,
                              ),
                            ),
                          ]
                        : null,
                  )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t        = widget.theme;
    final p        = widget.product;
    final info     = widget.info;
    final imgSrc   = p.imageUrl;
    final hasImg   = imgSrc != null && imgSrc.isNotEmpty;
    final promoOn  = p.hasPromo;
    final displayP = _displayPrice;
    final origP    = _originalPrice;
    final priceCol = (promoOn && _sizeObj == null) ? const Color(0xFF22C55E) : t.primary;
    final hasWa    = info?.hasWhatsapp == true;
    final hasPhone = info?.hasPhone    == true;

    final visibleGrupos = _visibleGrupos;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize:     0.50,
      maxChildSize:     0.95,
      builder: (ctx, ctrl) => Container(
        decoration: BoxDecoration(
          color:        t.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [

            // ── Imagen 200px con overlays ─────────────────────────────
            SizedBox(
              height: 200,
              width:  double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [

                  hasImg
                      ? GestureDetector(
                          onTap: () => _openImageViewer(imgSrc),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(imgSrc, fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(color: t.surfaceAlt)),
                              // Zoom hint — indica que la imagen es tappable
                              Positioned(
                                bottom: 8, left: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color:        Colors.black.withValues(alpha: 0.40),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.zoom_in_rounded,
                                      size: 13, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          color: t.surfaceAlt,
                          child: Icon(Icons.restaurant_menu_outlined, size: 48,
                            color: t.primary.withValues(alpha: 0.3)),
                        ),

                  // Gradiente negro 55% → transparent — pointer-events-none igual que React
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin:  Alignment.bottomCenter,
                            end:    Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Botón cerrar — top-right
                  Positioned(
                    top: 10, right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 34, height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.52),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 17, color: Colors.white),
                      ),
                    ),
                  ),

                  // Tags — top-left (máx 2)
                  if (p.tags.isNotEmpty)
                    Positioned(
                      top: 12, left: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: p.tags.take(2).map((tag) => Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:        t.primary,
                            borderRadius: BorderRadius.circular(t.badgeRadius),
                          ),
                          child: Text(tag, style: const TextStyle(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                        )).toList(),
                      ),
                    ),

                  // Precio badge — bottom-right (dinámico)
                  Positioned(
                    bottom: 12, right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (origP != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2, right: 4),
                            child: Text(
                              '\$${_fmt(origP)}',
                              style: const TextStyle(
                                color:           Color(0xA6FFFFFF),
                                fontSize:        11,
                                decoration:      TextDecoration.lineThrough,
                                decorationColor: Color(0xA6FFFFFF),
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:        priceCol,
                            borderRadius: BorderRadius.circular(t.badgeRadius),
                          ),
                          child: Text(
                            displayP > 0 ? '\$${_fmt(displayP)}' : '—',
                            style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Contenido scrolleable ─────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Nombre + rating promedio ───────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            p.name.isNotEmpty ? p.name : 'Sin nombre',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize:   21,
                              color:      t.text,
                              height:     1.2,
                            ),
                          ),
                        ),
                        if (_avgRating > 0) ...[
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(children: [
                              const Icon(Icons.star, size: 13, color: Color(0xFFFFD700)),
                              const SizedBox(width: 3),
                              Text(_avgRating.toStringAsFixed(1),
                                style: TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.w700, color: t.text)),
                            ]),
                          ),
                        ],
                      ],
                    ),

                    // ── Descripción ────────────────────────────────────
                    if (p.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(p.description!,
                        style: TextStyle(fontSize: 14, color: t.textMuted, height: 1.6)),
                    ],

                    // ── Componentes (ingredientes informativos) — chips ─
                    if (p.components.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text('INGREDIENTES',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          letterSpacing: 1, color: t.textMuted)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6, runSpacing: 6,
                        children: p.components.map((comp) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:        t.surfaceAlt,
                            borderRadius: BorderRadius.circular(99),
                            border:       Border.all(color: t.border),
                          ),
                          child: Text(comp,
                            style: TextStyle(fontSize: 11, color: t.textMuted)),
                        )).toList(),
                      ),
                    ],

                    // ── Tamaños / Personalización / Adiciones ──────────
                    // React: hasVariants = sizes > 0 || ingredients > 0 || extras > 0
                    if (_hasVariants) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:        t.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border:       Border.all(color: t.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Tamaños disponibles — single-select
                            if (p.sizes.isNotEmpty)
                              _variantSelector(
                                t: t,
                                title: 'Tamaños disponibles',
                                items: p.sizes.map((s) => (id: s.id, label: s.label, price: s.price)).toList(),
                                multi: false,
                                isSelected: (id) => id == _selectedSizeId,
                                onSelect: (id) => setState(() {
                                  _selectedSizeId = (_selectedSizeId == id) ? null : id;
                                }),
                              ),

                            // Personalización — multi-select
                            if (p.ingredients.isNotEmpty)
                              _variantSelector(
                                t: t,
                                title: 'Personalización',
                                items: p.ingredients.map((i) => (id: i.id, label: i.label, price: i.price)).toList(),
                                multi: true,
                                isSelected: _selIngredients.contains,
                                onSelect: (id) => _toggleMulti(id, _selIngredients),
                              ),

                            // Adiciones — multi-select
                            if (p.extras.isNotEmpty)
                              _variantSelector(
                                t: t,
                                title: 'Adiciones',
                                items: p.extras.map((e) => (id: e.id, label: e.label, price: e.price)).toList(),
                                multi: true,
                                isSelected: _selExtras.contains,
                                onSelect: (id) => _toggleMulti(id, _selExtras),
                              ),
                          ],
                        ),
                      ),
                    ],

                    // ── Grupos informativos ────────────────────────────
                    if (visibleGrupos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...visibleGrupos.map((g) {
                        if (g.items.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.name.toUpperCase(),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                  letterSpacing: 1, color: t.textMuted)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6, runSpacing: 6,
                                children: g.items.map((itemName) {
                                  final sel = _selGrupos[g.id]?.contains(itemName) == true;
                                  return GestureDetector(
                                    onTap: () => _toggleGrupoItem(g.id, itemName),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 120),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color:        sel ? t.primary : t.surfaceAlt,
                                        borderRadius: BorderRadius.circular(99),
                                        border:       Border.all(
                                          color: sel ? t.primary : t.border),
                                      ),
                                      child: Text(itemName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: sel ? Colors.white : t.textMuted,
                                        )),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    // ── Calificación ───────────────────────────────────
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color:        t.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border:       Border.all(color: t.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 13, color: t.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            _myRating > 0 ? 'Tu calificación' : 'Califica este plato',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: t.textMuted),
                          ),
                          const Spacer(),
                          Stack(
                            clipBehavior: Clip.none,
                            alignment:    Alignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(5, (i) {
                                  final filled = (i + 1) <= _myRating;
                                  return GestureDetector(
                                    onTap: _submitting ? null : () => _handleRate(i + 1),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: Icon(
                                        filled ? Icons.star : Icons.star_border_outlined,
                                        size:  22,
                                        color: filled ? const Color(0xFFFFD700) : t.border,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              if (_ratedToast)
                                Positioned(
                                  bottom: 30, right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color:        const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow:    const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                                    ),
                                    child: const Text('¡Gracias por calificar!',
                                      style: TextStyle(color: Colors.white, fontSize: 11)),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Botón WhatsApp ─────────────────────────────────
                    const SizedBox(height: 24),
                    Opacity(
                      opacity: (hasWa || hasPhone) ? 1.0 : 0.5,
                      child: SizedBox(
                        width:  double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: (hasWa || hasPhone) ? _openWhatsapp : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:         const Color(0xFF25D366),
                            foregroundColor:         Colors.white,
                            disabledBackgroundColor: const Color(0xFF25D366),
                            disabledForegroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(t.badgeRadius.clamp(0, 16)),
                            ),
                          ),
                          icon:  const Icon(Icons.chat_outlined, size: 17),
                          label: const Text('Pedir por WhatsApp',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ),
                    ),

                    if (!hasWa && hasPhone) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:        t.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(t.badgeRadius.clamp(0, 16)),
                          border:       Border.all(color: t.primary.withValues(alpha: 0.16)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 14, color: t.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(TextSpan(
                                text:     'Contáctanos: ',
                                style:    TextStyle(fontSize: 13, color: t.textMuted),
                                children: [
                                  TextSpan(
                                    text:  info!.phone!,
                                    style: TextStyle(fontWeight: FontWeight.w700, color: t.text),
                                  ),
                                ],
                              )),
                            ),
                          ],
                        ),
                      ),
                    ],
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

// ── Viewer de imagen a pantalla completa ──────────────────────────────────────
// Equivalente al imgViewer en ProductModal.jsx de React:
// overlay con blur + scale spring animation al abrir/cerrar

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({
    required this.imgSrc,
    required this.name,
    required this.cardRadius,
    required this.surfaceColor,
    required this.textColor,
  });

  final String imgSrc;
  final String name;
  final double cardRadius;
  final Color  surfaceColor;
  final Color  textColor;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            color: const Color(0x38000000), // rgba(0,0,0,0.22)
            child: Center(
              child: GestureDetector(
                onTap: () {}, // evita cerrar al tocar la imagen
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Imagen centrada — max 88vw / 72vh
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:  size.width  * 0.88,
                        maxHeight: size.height * 0.72,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(cardRadius),
                        child: Image.network(
                          imgSrc,
                          fit: BoxFit.contain,
                          errorBuilder: (_, err, stack) => Container(
                            width:  size.width * 0.88,
                            height: size.height * 0.40,
                            color:  const Color(0xFF1E293B),
                            child:  const Icon(Icons.broken_image_outlined,
                                color: Colors.white38, size: 48),
                          ),
                        ),
                      ),
                    ),
                    // Botón cerrar — top-right fuera de la imagen (equiv. -top-3 -right-3)
                    Positioned(
                      top: -12, right: -12,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 30, height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:     surfaceColor,
                            shape:     BoxShape.circle,
                            boxShadow: const [BoxShadow(
                                color: Colors.black26, blurRadius: 8)],
                          ),
                          child: Icon(Icons.close, size: 15, color: textColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
