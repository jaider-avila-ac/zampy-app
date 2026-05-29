import 'package:flutter/material.dart';
import '../menu_publico_service.dart';
import '../models/menu_publico_model.dart';

/// Equivalente a ProductModal.jsx — bottom sheet con imagen (precio dinámico),
/// variantes, calificación de estrellas y contacto.
class ProductModal extends StatefulWidget {
  const ProductModal({
    super.key,
    required this.product,
    required this.theme,
    required this.grupos,
    this.menuSlug,
    this.business,
    this.isPublished = false,
  });

  final Producto product;
  final MenuPublicoTheme theme;
  final List<GrupoInfo> grupos;
  final String? menuSlug;
  final BusinessInfo? business;
  final bool isPublished;

  @override
  State<ProductModal> createState() => _ProductModalState();
}

class _ProductModalState extends State<ProductModal> {
  // ── Estado de variantes ────────────────────────────────────────────────────
  String? _selectedSize;
  final _selectedIngredients = <String>{};
  final _selectedExtras      = <String>{};

  // ── Estado de calificación ─────────────────────────────────────────────────
  int    _myRating   = 0;
  double _avgRating  = 0;
  bool   _submitting = false;
  bool   _ratedToast = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    // Cuando hay promo, no pre-seleccionar talla para que se vea el precio promo
    _selectedSize = (p.sizes.isNotEmpty && !p.hasPromo)
        ? p.sizes.first.id
        : null;
    _avgRating = p.rating ?? 0;
    _loadMyRating();
  }

  Future<void> _loadMyRating() async {
    final slug = widget.menuSlug;
    final pid  = widget.product.id;
    if (slug == null || pid.isEmpty) return;
    final stars = await MenuPublicoService.getMyRating(slug, pid);
    if (mounted && stars != null) setState(() => _myRating = stars);
  }

  // ── Precio ─────────────────────────────────────────────────────────────────

  bool get _promoOn => widget.product.hasPromo;

  /// Precio mostrado en el badge (varía con talla / extras / personalización).
  /// Cuando hay promo y no hay talla elegida → base = promoPrice.
  double get _displayPrice {
    final p = widget.product;
    double base;
    if (_promoOn && _selectedSize == null) {
      base = p.promoPrice!;
    } else if (_selectedSize != null) {
      base = p.sizes
          .firstWhere((s) => s.id == _selectedSize,
              orElse: () => p.sizes.first)
          .price;
    } else {
      base = p.price;
    }
    final ingExtra = _selectedIngredients.fold<double>(
        0,
        (acc, id) =>
            acc +
            (p.ingredients.where((i) => i.id == id).firstOrNull?.price ?? 0));
    final extExtra = _selectedExtras.fold<double>(
        0,
        (acc, id) =>
            acc +
            (p.extras.where((e) => e.id == id).firstOrNull?.price ?? 0));
    return base + ingExtra + extExtra;
  }

  /// Precio original con tachado — SIEMPRE visible cuando hay promo.
  double? get _originalPrice => _promoOn ? widget.product.price : null;

  void _toggleMulti(String id, Set<String> set) {
    setState(() {
      if (set.contains(id)) {
        set.remove(id);
      } else {
        set.add(id);
      }
    });
  }

  // ── Calificación ───────────────────────────────────────────────────────────
  Future<void> _handleRate(int stars) async {
    final slug = widget.menuSlug;
    if (_submitting || slug == null) return;
    setState(() => _submitting = true);
    // rateProduct devuelve null si no está autenticado o hay error de red
    final promedio =
        await MenuPublicoService.rateProduct(slug, widget.product.id, stars);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (promedio != null) {
      setState(() {
        _myRating   = stars;
        _avgRating  = promedio;
        _ratedToast = true;
      });
      Future.delayed(const Duration(seconds: 2),
          () { if (mounted) setState(() => _ratedToast = false); });
    } else {
      _showSnack('Inicia sesión para calificar');
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(msg)));

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final p  = widget.product;
    final th = widget.theme;

    return Container(
      decoration: BoxDecoration(
        color: th.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: th.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Imagen con precio dinámico superpuesto
          _buildImage(p, th),

          // Contenido scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameRow(p, th),

                  if (p.description != null && p.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      p.description!,
                      style: TextStyle(
                          fontSize: 13, color: th.textMuted, height: 1.5),
                    ),
                  ],

                  // Componentes
                  if (p.components.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _sectionLabel('Ingredientes', th),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: p.components
                          .map((c) => _Chip(label: c, theme: th))
                          .toList(),
                    ),
                  ],

                  // Grupos informativos
                  ..._buildGrupos(p, th),

                  // Variantes
                  if (p.sizes.isNotEmpty ||
                      p.ingredients.isNotEmpty ||
                      p.extras.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: th.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: th.border),
                      ),
                      child: Column(
                        children: [
                          if (p.sizes.isNotEmpty)
                            _VariantSection(
                              title: 'Tamaños disponibles',
                              items: p.sizes,
                              selectedId: _selectedSize,
                              multi: false,
                              selectedIds: const {},
                              theme: th,
                              onSelect: (id) =>
                                  setState(() => _selectedSize = id),
                              onToggle: (_, __) {},
                            ),
                          if (p.ingredients.isNotEmpty)
                            _VariantSection(
                              title: 'Personalización',
                              items: p.ingredients,
                              selectedId: null,
                              multi: true,
                              selectedIds: _selectedIngredients,
                              theme: th,
                              onSelect: (_) {},
                              onToggle: (id, _) =>
                                  _toggleMulti(id, _selectedIngredients),
                            ),
                          if (p.extras.isNotEmpty)
                            _VariantSection(
                              title: 'Adiciones',
                              items: p.extras,
                              selectedId: null,
                              multi: true,
                              selectedIds: _selectedExtras,
                              theme: th,
                              onSelect: (_) {},
                              onToggle: (id, _) =>
                                  _toggleMulti(id, _selectedExtras),
                            ),
                        ],
                      ),
                    ),
                  ],

                  // Calificación
                  const SizedBox(height: 14),
                  _buildRatingSection(th),

                  // Contacto
                  _buildContact(th),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Imagen ─────────────────────────────────────────────────────────────────
  Widget _buildImage(Producto p, MenuPublicoTheme th) {
    final src = p.image ?? '';

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: src.isNotEmpty
                ? Image.network(
                    src,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Container(color: th.surfaceAlt),
                  )
                : Container(color: th.surfaceAlt),
          ),
        ),

        // Gradiente inferior
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0x8C000000), Colors.transparent],
              ),
            ),
          ),
        ),

        // Botón cerrar
        Positioned(
          top: 10, right: 10,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.52),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 18, color: Colors.white),
            ),
          ),
        ),

        // Tags (top-left, columna)
        if (p.tags.isNotEmpty)
          Positioned(
            top: 10, left: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: p.tags
                  .take(2)
                  .map((t) => Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: th.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(t,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ))
                  .toList(),
            ),
          ),

        // Precio (bottom-right): tachado arriba + badge abajo
        Positioned(
          bottom: 10, right: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Precio original con tachado — SIEMPRE cuando hay promo
              if (_originalPrice != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    '\$${MenuPublicoTheme.fmtPrice(_originalPrice!)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.white.withValues(alpha: 0.75),
                      decorationThickness: 2,
                    ),
                  ),
                ),

              // Badge de precio dinámico
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _promoOn
                      ? const Color(0xFF22C55E)
                      : th.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _displayPrice > 0
                      ? '\$${MenuPublicoTheme.fmtPrice(_displayPrice)}'
                      : '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Nombre + rating promedio ───────────────────────────────────────────────
  Widget _buildNameRow(Producto p, MenuPublicoTheme th) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            p.name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: th.text,
              height: 1.2,
            ),
          ),
        ),
        if (_avgRating > 0) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    size: 14, color: Color(0xFFFFD700)),
                const SizedBox(width: 2),
                Text(
                  _avgRating.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: th.text),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Calificación de estrellas ──────────────────────────────────────────────
  Widget _buildRatingSection(MenuPublicoTheme th) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: th.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: th.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 13, color: th.textMuted),
                const SizedBox(width: 6),
                Text(
                  _myRating > 0 ? 'Tu calificación' : 'Califica este plato',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: th.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = i < _myRating;
                  return GestureDetector(
                    onTap: _submitting ? null : () => _handleRate(i + 1),
                    child: Opacity(
                      opacity: _submitting ? 0.5 : 1.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 22,
                          color:
                              filled ? const Color(0xFFFFD700) : th.border,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              if (_ratedToast)
                Positioned(
                  bottom: 28,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Text(
                      '¡Gracias por calificar!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Contacto ──────────────────────────────────────────────────────────────
  Widget _buildContact(MenuPublicoTheme th) {
    final b = widget.business;
    final phone =
        b?.whatsapp?.isNotEmpty == true ? b!.whatsapp! : (b?.phone ?? '');
    if (phone.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: th.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: th.primary.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Icon(Icons.phone_outlined, size: 14, color: th.primary),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: th.textMuted),
                  children: [
                    const TextSpan(text: 'Contáctanos: '),
                    TextSpan(
                      text: phone,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: th.text),
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

  // ── Grupos informativos ────────────────────────────────────────────────────
  List<Widget> _buildGrupos(Producto p, MenuPublicoTheme th) {
    if (p.grupoIds.isEmpty) return [];
    final visibles = p.grupoIds
        .map((id) => widget.grupos
            .where((g) => g.id == id && g.isActive)
            .firstOrNull)
        .whereType<GrupoInfo>()
        .toList();
    if (visibles.isEmpty) return [];
    return [
      const SizedBox(height: 14),
      ...visibles.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel(g.name, th),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: g.items
                      .map((item) => _Chip(label: item, theme: th))
                      .toList(),
                ),
              ],
            ),
          )),
    ];
  }

  Widget _sectionLabel(String label, MenuPublicoTheme th) => Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: th.textMuted,
          letterSpacing: 1.1,
        ),
      );
}

// ── Variant Section ───────────────────────────────────────────────────────────

class _VariantSection extends StatelessWidget {
  const _VariantSection({
    required this.title,
    required this.items,
    required this.selectedId,
    required this.multi,
    required this.selectedIds,
    required this.theme,
    required this.onSelect,
    required this.onToggle,
  });

  final String title;
  final List<ProductoVariante> items;
  final String? selectedId;
  final bool multi;
  final Set<String> selectedIds;
  final MenuPublicoTheme theme;
  final ValueChanged<String> onSelect;
  final void Function(String, bool) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.textMuted),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.map((item) {
              final isActive = multi
                  ? selectedIds.contains(item.id)
                  : selectedId == item.id;
              return GestureDetector(
                onTap: () {
                  if (multi) {
                    onToggle(item.id, !isActive);
                  } else {
                    onSelect(item.id);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? theme.primary : theme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? theme.primary : theme.border,
                    ),
                  ),
                  child: Text(
                    item.price > 0
                        ? '${item.label} (+\$${MenuPublicoTheme.fmtPrice(item.price)})'
                        : item.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white : theme.text,
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
}

// ── Chip ─────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.theme});
  final String label;
  final MenuPublicoTheme theme;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.border),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 11, color: theme.textMuted)),
      );
}
