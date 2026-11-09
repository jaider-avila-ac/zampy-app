import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart' hide MenuTheme;
import 'package:provider/provider.dart';
import '../../../../shared/responsive.dart';

import '../../../../components/ui/auth_required_modal.dart';
import '../../../../context/auth_context.dart';
import '../../../../context/cart_context.dart';
import '../../../../context/likes_context.dart';
import '../../../../services/estadisticas_service.dart';
import '../models/public_menu_model.dart';
import 'product_image.dart';

// Equivalente a src/components/ProductModal.jsx en React

class ProductModal extends StatefulWidget {
  const ProductModal({
    super.key,
    required this.product,
    required this.theme,
    this.menuSlug,
    this.menuCodigo,
    this.info,
    this.grupos = const [],
    this.trackView = false,
    this.staffMode = false,
    this.esPropio = false,
    this.onConfiguredAdd,
  });

  /// Personal del negocio (staffMode): recibe el ítem configurado (misma forma que el carrito) en lugar de ir al
  /// carrito, como onConfiguredAdd de React. La hoja se cierra al agregar.
  final void Function(Map<String, dynamic> item)? onConfiguredAdd;

  final MenuProduct product;
  final MenuTheme theme;
  final String? menuSlug;
  final String? menuCodigo;
  final MenuInfo? info;
  final List<MenuGrupo> grupos;
  final bool trackView;
  final bool staffMode;
  final bool esPropio;

  static Future<void> show(
    BuildContext context,
    MenuProduct product,
    MenuTheme theme, {
    String? menuSlug,
    String? menuCodigo,
    MenuInfo? info,
    List<MenuGrupo> grupos = const [],
    bool trackView = false,
    bool staffMode = false,
    bool esPropio = false,
    void Function(Map<String, dynamic> item)? onConfiguredAdd,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: hojaConstraints(context, maxWidth: 640),
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.68),
      builder: (_) => ProductModal(
        product: product,
        theme: theme,
        menuSlug: menuSlug,
        menuCodigo: menuCodigo,
        info: info,
        grupos: grupos,
        trackView: trackView,
        staffMode: staffMode,
        esPropio: esPropio,
        onConfiguredAdd: onConfiguredAdd,
      ),
    );
  }

  @override
  State<ProductModal> createState() => _ProductModalState();
}

class _ProductModalState extends State<ProductModal> {
  double _avgRating = 0;

  String? _selectedSizeId;
  final List<String> _selIngredients = [];
  final List<String> _selExtras = [];
  final Map<String, Set<String>> _selGrupos = {};
  final _notaCocina = TextEditingController(); // solo personal (staffMode)

  @override
  void initState() {
    super.initState();
    _avgRating = widget.product.rating ?? 0;
    // Auto-selecciona el primer tamaño igual que React
    _selectedSizeId = widget.product.sizes.isNotEmpty
        ? widget.product.sizes.first.id
        : null;

    if (widget.trackView &&
        widget.menuSlug != null &&
        widget.product.id.isNotEmpty) {
      EstadisticasService.registrarVistaProducto(
        widget.menuSlug!,
        widget.product.id,
      );
    }
  }

  @override
  void dispose() {
    _notaCocina.dispose();
    super.dispose();
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  ProductSize? get _sizeObj => _selectedSizeId == null
      ? null
      : widget.product.sizes.where((s) => s.id == _selectedSizeId).firstOrNull;

  double get _displayPrice {
    final p = widget.product;
    final sizeObj = _sizeObj;
    final base = sizeObj != null
        ? sizeObj.price
        : (p.hasPromo ? p.promoPrice! : p.price);
    final ingAdd = _selIngredients
        .map(
          (id) =>
              p.ingredients.where((i) => i.id == id).firstOrNull?.price ?? 0.0,
        )
        .fold<double>(0, (a, b) => a + b);
    final extAdd = _selExtras
        .map(
          (id) => p.extras.where((e) => e.id == id).firstOrNull?.price ?? 0.0,
        )
        .fold<double>(0, (a, b) => a + b);
    var gruposAdd = 0.0;
    for (final grupo in _visibleGrupos) {
      final seleccionados = _selGrupos[grupo.id] ?? const <String>{};
      for (final item in grupo.items) {
        if (seleccionados.contains(item.name)) gruposAdd += item.price;
      }
    }
    return base + ingAdd + extAdd + gruposAdd;
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
      .map(
        (id) =>
            widget.grupos.where((g) => g.id == id && g.isActive).firstOrNull,
      )
      .whereType<MenuGrupo>()
      .toList();

  // ── Interactions ──────────────────────────────────────────────────────────

  void _toggleMulti(String id, List<String> list) {
    setState(() {
      if (list.contains(id)) {
        list.remove(id);
      } else {
        list.add(id);
      }
    });
  }

  void _toggleGrupoItem(String grupoId, String itemName) {
    setState(() {
      final set = _selGrupos.putIfAbsent(grupoId, () => {});
      if (set.contains(itemName)) {
        set.remove(itemName);
      } else {
        set.add(itemName);
      }
    });
  }

  Future<void> _toggleLike() async {
    final auth = context.read<AuthContext>();
    if (!auth.isLoggedIn) {
      showAuthRequiredDialog(
        context,
        returnTo: widget.menuSlug == null ? '/' : '/menu/${widget.menuSlug}',
      );
      return;
    }
    if (widget.menuSlug == null || widget.product.id.isEmpty) return;
    await context.read<LikesContext>().toggleProducto(
      widget.menuSlug!,
      widget.product.id,
    );
  }

  // ── Carrito (pedidos activos) ─────────────────────────────────────────────

  /// El personal arma una orden (mesero en una mesa, o el admin agregando a una cuenta): nota para cocina y
  /// "Agregar a la orden". Con ?staff=1 (repartidor) solo se consulta el menú.
  bool get _tomaOrden => widget.onConfiguredAdd != null;

  bool get _pedidosActivos =>
      !widget.staffMode && widget.menuCodigo != null && (widget.info?.pedidosActivos ?? false);

  // Ítem configurado con la misma forma que handleAddToCart de React: el carrito se
  // guarda en el servidor y lo comparten la web y la app.
  Map<String, dynamic> _configuredItem() {
    final p = widget.product;
    final sizeObj = _sizeObj;
    ProductModifier? mod(List<ProductModifier> l, String id) => l.where((m) => m.id == id).firstOrNull;
    final ingredientDetails = [
      for (final id in _selIngredients)
        {'id': id, 'label': mod(p.ingredients, id)?.label ?? '', 'price': mod(p.ingredients, id)?.price ?? 0},
    ];
    final extraDetails = [
      for (final id in _selExtras)
        {'id': id, 'label': mod(p.extras, id)?.label ?? '', 'price': mod(p.extras, id)?.price ?? 0},
    ];
    final grupoDetails = <Map<String, dynamic>>[];
    final gruposResumen = <String, List<String>>{};
    var gruposTotal = 0.0;
    for (final g in _visibleGrupos) {
      final sel = (_selGrupos[g.id] ?? const <String>{}).toList();
      if (sel.isEmpty) continue;
      final precio = g.items.where((it) => sel.contains(it.name)).fold<double>(0, (s, it) => s + it.price);
      gruposTotal += precio;
      gruposResumen[g.name] = sel;
      grupoDetails.add({'id': g.id, 'name': g.name, 'selectedItems': sel, 'price': precio});
    }
    final basePrice = sizeObj != null ? sizeObj.price : (p.hasPromo ? p.promoPrice! : p.price);
    final ingredientsTotal = ingredientDetails.fold<double>(0, (s, i) => s + (i['price'] as double));
    final extrasTotal = extraDetails.fold<double>(0, (s, e) => s + (e['price'] as double));
    return {
      'productId': p.id,
      'productName': p.name,
      'productImage': p.imageUrl,
      'sizeId': _selectedSizeId,
      'sizeLabel': sizeObj?.label,
      'ingredientIds': [..._selIngredients],
      'ingredientLabels': [for (final i in ingredientDetails) i['label']],
      'extraIds': [..._selExtras],
      'extraLabels': [for (final e in extraDetails) e['label']],
      'grupos': {for (final e in _selGrupos.entries) e.key: e.value.toList()},
      'gruposResumen': gruposResumen,
      'unitPrice': _displayPrice,
      'ingredientDetails': ingredientDetails,
      'extraDetails': extraDetails,
      'grupoDetails': grupoDetails,
      'promo': (p.hasPromo && sizeObj == null)
          ? {'active': true, 'originalPrice': p.price, 'promoPrice': p.promoPrice}
          : null,
      'priceBreakdown': {
        'basePrice': basePrice,
        'ingredientsTotal': ingredientsTotal,
        'extrasTotal': extrasTotal,
        'gruposTotal': gruposTotal,
      },
      'note': _tomaOrden && _notaCocina.text.trim().isNotEmpty ? _notaCocina.text.trim() : null,
    };
  }

  // Evita el doble toque: al agregar se cierra el modal, pero protegemos la ventana entre toques rápidos.
  bool _agregando = false;

  void _agregarALaOrden() {
    if (_agregando) return;
    _agregando = true;
    widget.onConfiguredAdd?.call(_configuredItem());
    Navigator.of(context).pop();
  }

  void _agregarAlCarrito() {
    if (_agregando) return;
    if (!context.read<AuthContext>().isLoggedIn) {
      showAuthRequiredDialog(
        context,
        returnTo: '/${widget.menuSlug}',
        message: 'Necesitas una cuenta para hacer pedidos.',
      );
      return;
    }
    _agregando = true;
    context.read<CartContext>().addItem(_configuredItem());
    // al agregar se cierra el "ver más" (así no se puede volver a tocar y se evita el spam)
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('¡Agregado al carrito!'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ));
  }

  void _openImageViewer(String imgSrc) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) => _ImageViewer(
        imgSrc: imgSrc,
        name: widget.product.name,
        cardRadius: widget.theme.cardRadius,
        surfaceColor: widget.theme.surface,
        textColor: widget.theme.text,
      ),
      transitionBuilder: (_, anim, secondAnim, child) {
        final scale = Tween<double>(begin: 0.80, end: 1.0).animate(
          CurvedAnimation(
            parent: anim,
            curve: const Cubic(0.34, 1.56, 0.64, 1),
            reverseCurve: Curves.easeIn,
          ),
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  static String _fmt(double p) {
    final s = p.toStringAsFixed(0);
    final buf = StringBuffer();
    int c = 0;
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
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: t.textMuted,
            ),
          ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: active ? t.primary : t.surfaceAlt,
                    borderRadius: BorderRadius.circular(t.badgeRadius),
                    border: Border.all(
                      color: active ? t.primary : t.border,
                      width: 1.5,
                    ),
                  ),
                  child: Text.rich(
                    TextSpan(
                      text: item.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : t.text,
                      ),
                      children: item.price > 0
                          ? [
                              TextSpan(
                                text: ' +\$${_fmt(item.price)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: active
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : t.textMuted,
                                ),
                              ),
                            ]
                          : null,
                    ),
                  ),
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
    final t = widget.theme;
    final p = widget.product;
    final info = widget.info;
    final imgSrc = p.imageUrl;
    final hasImg = imgSrc != null && imgSrc.isNotEmpty;
    final displayP = _displayPrice;
    final origP = _originalPrice;
    final priceCol = t.primary;
    final hasPhone = info?.hasPhone == true;
    final likes = context.watch<LikesContext>();
    final productLiked =
        widget.menuSlug != null && likes.productLiked(widget.product.id);

    final visibleGrupos = _visibleGrupos;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      builder: (ctx, ctrl) => Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            // ── Imagen 200px con overlays ─────────────────────────────
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasImg
                      ? GestureDetector(
                          onTap: () => _openImageViewer(imgSrc),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ProductImage(
                                url: imgSrc,
                                logoUrl: widget.info?.logoUrl,
                                alignment: p.imageAlignment,
                                fit: BoxFit.cover,
                                backgroundColor: t.surfaceAlt,
                                foregroundColor: t.textMuted,
                              ),
                              // Zoom hint — indica que la imagen es tappable
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.40),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          color: t.surfaceAlt,
                          child: Icon(
                            Icons.restaurant_menu_outlined,
                            size: 48,
                            color: t.primary.withValues(alpha: 0.3),
                          ),
                        ),

                  // Gradiente negro 55% → transparent — pointer-events-none igual que React
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
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
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.52),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Tags — top-left (máx 2)
                  if (p.tags.isNotEmpty)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: p.tags
                            .take(2)
                            .map(
                              (tag) => Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: t.primary,
                                  borderRadius: BorderRadius.circular(
                                    t.badgeRadius,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                  // Precio badge — bottom-right (dinámico)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (origP != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2, right: 4),
                            child: Text(
                              '\$${_fmt(origP)}',
                              style: const TextStyle(
                                color: Color(0xA6FFFFFF),
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Color(0xA6FFFFFF),
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: priceCol,
                            borderRadius: BorderRadius.circular(t.badgeRadius),
                          ),
                          child: Text(
                            displayP > 0 ? '\$${_fmt(displayP)}' : '—',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
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
                              fontSize: 21,
                              color: t.text,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (_avgRating > 0) ...[
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 13,
                                  color: Color(0xFFFFD700),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _avgRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: t.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    // ── Descripción ────────────────────────────────────
                    if (p.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        p.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: t.textMuted,
                          height: 1.6,
                        ),
                      ),
                    ],

                    // ── Componentes (ingredientes informativos) — chips ─
                    if (p.components.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'INGREDIENTES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: t.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: p.components
                            .map(
                              (comp) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: t.surfaceAlt,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: t.border),
                                ),
                                child: Text(
                                  comp,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: t.textMuted,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],

                    // ── Tamaños / Personalización / Adiciones ──────────
                    // React: hasVariants = sizes > 0 || ingredients > 0 || extras > 0
                    if (_hasVariants) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: t.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: t.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tamaños disponibles — single-select
                            if (p.sizes.isNotEmpty)
                              _variantSelector(
                                t: t,
                                title: 'Tamaños disponibles',
                                items: p.sizes
                                    .map(
                                      (s) => (
                                        id: s.id,
                                        label: s.label,
                                        price: s.price,
                                      ),
                                    )
                                    .toList(),
                                multi: false,
                                isSelected: (id) => id == _selectedSizeId,
                                onSelect: (id) => setState(() {
                                  _selectedSizeId = (_selectedSizeId == id)
                                      ? null
                                      : id;
                                }),
                              ),

                            // Personalización — multi-select
                            if (p.ingredients.isNotEmpty)
                              _variantSelector(
                                t: t,
                                title: 'Personalización',
                                items: p.ingredients
                                    .map(
                                      (i) => (
                                        id: i.id,
                                        label: i.label,
                                        price: i.price,
                                      ),
                                    )
                                    .toList(),
                                multi: true,
                                isSelected: _selIngredients.contains,
                                onSelect: (id) =>
                                    _toggleMulti(id, _selIngredients),
                              ),

                            // Adiciones — multi-select
                            if (p.extras.isNotEmpty)
                              _variantSelector(
                                t: t,
                                title: 'Adiciones',
                                items: p.extras
                                    .map(
                                      (e) => (
                                        id: e.id,
                                        label: e.label,
                                        price: e.price,
                                      ),
                                    )
                                    .toList(),
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
                              Text(
                                g.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: t.textMuted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: g.items.map((item) {
                                  final sel =
                                      _selGrupos[g.id]?.contains(item.name) ==
                                      true;
                                  return GestureDetector(
                                    onTap: () =>
                                        _toggleGrupoItem(g.id, item.name),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 120,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sel ? t.primary : t.surfaceAlt,
                                        borderRadius: BorderRadius.circular(99),
                                        border: Border.all(
                                          color: sel ? t.primary : t.border,
                                        ),
                                      ),
                                      child: Text(
                                        item.price > 0
                                            ? '${item.name} +\$${_fmt(item.price)}'
                                            : item.name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: sel
                                              ? Colors.white
                                              : t.textMuted,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    if (!widget.staffMode && widget.menuSlug != null) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: productLiked
                                ? const Color(0xFFFDF2F8)
                                : t.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: productLiked
                                  ? const Color(0xFFEC4899)
                                  : t.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                productLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 17,
                                color: productLiked
                                    ? const Color(0xFFEC4899)
                                    : t.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                productLiked
                                    ? 'Te encanta este plato'
                                    : 'Me encanta este plato',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: productLiked
                                      ? const Color(0xFFBE185D)
                                      : t.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // el personal deja una nota para cocina (igual que React)
                    if (_tomaOrden) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Nota para cocina (opcional)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.textMuted),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notaCocina,
                        maxLength: 250,
                        minLines: 2,
                        maxLines: 3,
                        style: TextStyle(fontSize: 13, color: t.text),
                        decoration: InputDecoration(
                          hintText: 'Ej: sin tomate, salsa aparte, poco picante…',
                          hintStyle: TextStyle(fontSize: 13, color: t.textMuted),
                          counterText: '',
                          filled: true,
                          fillColor: t.surfaceAlt,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: t.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: t.border),
                          ),
                        ),
                      ),
                    ],

                    // ── Acción: carrito / orden, o contacto (igual que React:
                    //    ya no hay botón "Pedir por WhatsApp") ───────────────
                    const SizedBox(height: 24),
                    if (_pedidosActivos || _tomaOrden)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _tomaOrden ? _agregarALaOrden : _agregarAlCarrito,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: t.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                t.badgeRadius.clamp(0, 16),
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.shopping_cart_outlined, size: 17),
                          label: Text(
                            _tomaOrden ? 'Agregar a la orden' : 'Agregar al carrito',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      )
                    else if (hasPhone)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: t.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(
                            t.badgeRadius.clamp(0, 16),
                          ),
                          border: Border.all(
                            color: t.primary.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 14, color: t.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: 'Contáctanos: ',
                                  style: TextStyle(fontSize: 13, color: t.textMuted),
                                  children: [
                                    TextSpan(
                                      text: info!.phone!,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: t.text,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
  final Color surfaceColor;
  final Color textColor;

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
                        maxWidth: size.width * 0.88,
                        maxHeight: size.height * 0.72,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(cardRadius),
                        child: Image.network(
                          imgSrc,
                          fit: BoxFit.contain,
                          errorBuilder: (_, err, stack) => Container(
                            width: size.width * 0.88,
                            height: size.height * 0.40,
                            color: const Color(0xFF1E293B),
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white38,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Botón cerrar — top-right fuera de la imagen (equiv. -top-3 -right-3)
                    Positioned(
                      top: -12,
                      right: -12,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 8),
                            ],
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
