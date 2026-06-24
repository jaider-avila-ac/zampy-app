import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/app_colors.dart';
import '../models/editor_menu_model.dart';
import '../shared/save_bar.dart';

// Equivalente a src/modules/menu/editor/ProductsTab.jsx en React
// Listado de productos con búsqueda, filtro por categoría y reordenamiento.

class ProductsTab extends StatefulWidget {
  const ProductsTab({
    super.key,
    required this.draft,
    required this.onSave,
    required this.saving,
    required this.menuId,
    required this.subscription,
    required this.onGoToCategories,
  });

  final EditorDraft draft;
  final Future<void> Function(Map<String, dynamic> patch) onSave;
  final bool saving;
  final int menuId;
  final EditorSubscription subscription;
  final VoidCallback onGoToCategories;

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  late List<EditorProduct> _products;
  bool _dirty      = false;
  bool _reordering = false;
  String _search   = '';
  String _filterCat = 'all';

  @override
  void initState() {
    super.initState();
    _products = List.from(widget.draft.products);
  }

  void _mutate(List<EditorProduct> next) {
    setState(() { _products = next; _dirty = true; });
  }

  Future<void> _handleSave() async {
    await widget.onSave({'products': _products.map((p) => p.toJson()).toList()});
    setState(() { _dirty = false; _reordering = false; });
  }

  void _toggleVisible(String id) {
    _mutate(_products.map((p) {
      if (p.id == id) return p.copyWith(isVisible: !p.isVisible);
      return p;
    }).toList());
  }

  void _toggleFeatured(String id) {
    _mutate(_products.map((p) {
      if (p.id == id) return p.copyWith(isFeatured: !p.isFeatured);
      return p;
    }).toList());
  }

  void _confirmDelete(EditorProduct p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar producto', style: TextStyle(fontSize: 16)),
        content: Text('¿Eliminar "${p.name}"? Esta acción no se puede deshacer.',
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _mutate(_products.where((x) => x.id != p.id).toList());
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _startReordering() {
    final cats = widget.draft.categories;
    setState(() {
      _search = '';
      _filterCat = cats.isNotEmpty ? cats.first.id : 'all';
      _reordering = true;
    });
  }

  List<EditorProduct> get _filtered {
    var list = _products;
    if (_filterCat != 'all') list = list.where((p) => p.categoryId == _filterCat).toList();
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _moveProduct(String id, int dir) {
    final filtered    = _filtered;
    final filteredIds = filtered.map((p) => p.id).toList();
    final fi          = filteredIds.indexOf(id);
    final ni          = fi + dir;
    if (ni < 0 || ni >= filteredIds.length) return;
    final idxA = _products.indexWhere((p) => p.id == filteredIds[fi]);
    final idxB = _products.indexWhere((p) => p.id == filteredIds[ni]);
    final arr  = List<EditorProduct>.from(_products);
    final tmp  = arr[idxA]; arr[idxA] = arr[idxB]; arr[idxB] = tmp;
    _mutate(arr);
  }

  String _catName(String id) =>
      widget.draft.categories.firstWhere((c) => c.id == id,
          orElse: () => EditorCategory(id: '', name: '—')).name;

  String _fmtPrice(double p) {
    if (p == p.truncateToDouble()) return p.toInt().toString();
    return p.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cats   = widget.draft.categories;
    final noCats = cats.isEmpty;
    final atLim  = widget.subscription.productLimitReached(_products.length);
    final filtered = _filtered;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Toolbar ────────────────────────────────────────────
                    Row(
                      children: [
                        if (!_reordering) ...[
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setState(() => _search = v),
                              decoration: InputDecoration(
                                hintText: 'Buscar producto…',
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                                suffixIcon: _search.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close, size: 14),
                                        onPressed: () => setState(() => _search = ''),
                                      )
                                    : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Filtro categoría
                        DropdownButton<String>(
                          value: _filterCat,
                          underline: const SizedBox(),
                          isDense: true,
                          items: [
                            if (!_reordering)
                              const DropdownMenuItem(
                                value: 'all',
                                child: Text('Todas', style: TextStyle(fontSize: 13)),
                              ),
                            ...cats.map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name, style: const TextStyle(fontSize: 13)),
                                )),
                          ],
                          onChanged: (v) { if (v != null) setState(() => _filterCat = v); },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Segunda fila: contador + botones de acción
                    Row(
                      children: [
                        Text(
                          widget.subscription.limiteProductos != null
                              ? '${_products.length}/${widget.subscription.limiteProductos} productos'
                              : '${_products.length} producto${_products.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: atLim ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                            fontWeight: atLim ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        if (!_reordering && _products.length > 1 && !noCats)
                          TextButton.icon(
                            onPressed: _startReordering,
                            icon: const Icon(Icons.swap_vert, size: 13),
                            label: const Text('Reordenar', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        if (_reordering)
                          TextButton.icon(
                            onPressed: () => setState(() { _reordering = false; _filterCat = 'all'; }),
                            icon: const Icon(Icons.swap_vert, size: 13),
                            label: const Text('Ordenando…', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: AppColors.kBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: (noCats || _reordering || atLim)
                              ? null
                              : () => context.push('/menus/${widget.menuId}/products/new'),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Nuevo', style: TextStyle(fontSize: 13)),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.kBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Hint reordenamiento
                    if (_reordering)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Usa las flechas para reordenar. Cambia la categoría para ordenar otras. Presiona Guardar cuando termines.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF4338CA)),
                        ),
                      ),

                    // Sin categorías
                    if (noCats)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.warning_amber_outlined, size: 28, color: Color(0xFFF59E0B)),
                            const SizedBox(height: 10),
                            const Text('Primero crea una categoría',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                            const SizedBox(height: 6),
                            const Text(
                              'Los productos necesitan una categoría. Ve a la pestaña Categorías y agrega al menos una.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            FilledButton(
                              onPressed: widget.onGoToCategories,
                              style: FilledButton.styleFrom(backgroundColor: AppColors.kBlue),
                              child: const Text('Ir a Categorías'),
                            ),
                          ],
                        ),
                      ),

                    // Empty state (con categorías pero sin productos)
                    if (!noCats && _products.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.fastfood_outlined, size: 36, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 12),
                            const Text('Sin productos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 4),
                            const Text('Agrega productos para construir tu menú.',
                                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => context.push('/menus/${widget.menuId}/products/new'),
                              icon: const Icon(Icons.add, size: 14),
                              label: const Text('Crear primer producto'),
                              style: FilledButton.styleFrom(backgroundColor: AppColors.kBlue),
                            ),
                          ],
                        ),
                      ),

                    // Lista de productos
                    ...List.generate(filtered.length, (idx) {
                      final p = filtered[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: _reordering
                                ? const Color(0xFFC7D2FE)
                                : const Color(0xFFE2E8F0),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Opacity(
                          opacity: p.isVisible ? 1 : 0.55,
                          child: Row(
                            children: [
                              // Imagen / placeholder
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                                    ? Image.network(p.imageUrl!,
                                        width: 40, height: 40, fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, st) => _NoImageBox())
                                    : _NoImageBox(),
                              ),
                              const SizedBox(width: 10),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          '${_catName(p.categoryId)} · \$${_fmtPrice(p.price)}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                        if (p.imageUrl == null || p.imageUrl!.isEmpty || p.price == 0)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 4),
                                            child: Icon(Icons.warning_amber_outlined, size: 11, color: Color(0xFFF59E0B)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Acciones
                              if (_reordering)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _ArrowBtn(
                                      icon: Icons.keyboard_arrow_up,
                                      enabled: idx > 0,
                                      onTap: () => _moveProduct(p.id, -1),
                                    ),
                                    _ArrowBtn(
                                      icon: Icons.keyboard_arrow_down,
                                      enabled: idx < filtered.length - 1,
                                      onTap: () => _moveProduct(p.id, 1),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (p.isFeatured)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 4),
                                        child: Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                      ),
                                    _IconBtn(
                                      icon: p.isFeatured ? Icons.star_rounded : Icons.star_border_rounded,
                                      color: p.isFeatured ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                                      onTap: () => _toggleFeatured(p.id),
                                    ),
                                    _IconBtn(
                                      icon: p.isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      onTap: () => _toggleVisible(p.id),
                                    ),
                                    _IconBtn(
                                      icon: Icons.edit_outlined,
                                      onTap: () => context.push('/menus/${widget.menuId}/products/${p.id}'),
                                    ),
                                    _IconBtn(
                                      icon: Icons.delete_outline,
                                      danger: true,
                                      onTap: () => _confirmDelete(p),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    }),

                    if (filtered.isEmpty && _products.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('Sin resultados para tu búsqueda.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            textAlign: TextAlign.center),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
        SaveBar(dirty: _dirty, saving: widget.saving, onSave: _handleSave),
      ],
    );
  }
}

class _NoImageBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 40, height: 40,
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.fastfood_outlined, size: 18, color: Color(0xFFCBD5E1)),
      );
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, this.danger = false, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
  final Color? color;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 15,
              color: color ?? (danger ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8))),
        ),
      );
}

class _ArrowBtn extends StatelessWidget {
  const _ArrowBtn({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: Icon(icon, size: 18,
              color: enabled ? AppColors.kBlue : const Color(0xFFE2E8F0)),
        ),
      );
}
