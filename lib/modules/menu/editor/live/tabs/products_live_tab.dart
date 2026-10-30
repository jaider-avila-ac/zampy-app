import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../services/live_editor_service.dart';
import '../../../../../shared/app_colors.dart';
import '../editor_models.dart';

class ProductsLiveTab extends StatefulWidget {
  const ProductsLiveTab({
    super.key,
    required this.menu,
    required this.onChanged,
  });

  final LiveMenu menu;
  final Future<void> Function() onChanged;

  @override
  State<ProductsLiveTab> createState() => _ProductsLiveTabState();
}

class _ProductsLiveTabState extends State<ProductsLiveTab> {
  String _search = '';
  String _category = 'all';
  bool _busy = false;

  Future<void> _toggle(LiveProduct p, String field) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (field == 'explorar') {
        await LiveEditorService.productExplore(
          widget.menu.codigo,
          p.codigo,
          !p.enExplorar,
        );
      } else {
        await LiveEditorService.updateProductBasic(
          widget.menu.codigo,
          p.codigo,
          {
            'name': p.name,
            'description': p.description,
            'price': p.price,
            'categoryId': p.categoryId,
            'imageUrl': p.imageUrl ?? '',
            'imagePosition': p.imagePosition,
            'isVisible': field == 'visible' ? !p.isVisible : p.isVisible,
            'isFeatured': field == 'featured' ? !p.isFeatured : p.isFeatured,
          },
        );
      }
      await widget.onChanged();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(LiveProduct p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${p.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.kRed),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await LiveEditorService.deleteProduct(widget.menu.codigo, p.codigo);
      await widget.onChanged();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.kRed : AppColors.kGreen,
      ),
    );
  }

  List<LiveProduct> get _filtered {
    var list = widget.menu.products;
    if (_category != 'all') {
      list = list.where((p) => p.categoryId == _category).toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  String _catName(String id) =>
      widget.menu.categories
          .where((c) => c.codigo == id)
          .map((c) => c.name)
          .firstOrNull ??
      '—';

  @override
  Widget build(BuildContext context) {
    if (widget.menu.categories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Crea una categoría antes de agregar productos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.kTextMuted),
          ),
        ),
      );
    }
    final items = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        hintText: 'Buscar producto…',
                        prefixIcon: Icon(Icons.search, size: 17),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            await context.push(
                              '/menus/${widget.menu.codigo}/products/new',
                            );
                            await widget.onChanged();
                          },
                    icon: const Icon(Icons.add, size: 15),
                    label: const Text('Nuevo'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Todas'),
                      selected: _category == 'all',
                      onSelected: (_) => setState(() => _category = 'all'),
                    ),
                    for (final c in widget.menu.categories)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          label: Text(c.name),
                          selected: _category == c.codigo,
                          onSelected: (_) =>
                              setState(() => _category = c.codigo),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Sin productos.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final p = items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.kCardBorder),
                      ),
                      child: ListTile(
                        onTap: _busy
                            ? null
                            : () async {
                                await context.push(
                                  '/menus/${widget.menu.codigo}/products/${p.codigo}',
                                );
                                await widget.onChanged();
                              },
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.kSkeleton,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                              ? Image.network(p.imageUrl!, fit: BoxFit.cover)
                              : const Icon(
                                  Icons.fastfood_outlined,
                                  color: AppColors.kTextMuted,
                                ),
                        ),
                        title: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${_catName(p.categoryId)} · \$${p.price.toStringAsFixed(0)}'
                          '${p.isFeatured ? ' · Destacado' : ''}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: PopupMenuButton<String>(
                          enabled: !_busy,
                          onSelected: (v) {
                            switch (v) {
                              case 'visible':
                                _toggle(p, 'visible');
                              case 'featured':
                                _toggle(p, 'featured');
                              case 'explorar':
                                _toggle(p, 'explorar');
                              case 'delete':
                                _delete(p);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'visible',
                              child: Text(
                                p.isVisible
                                    ? 'Ocultar del menú'
                                    : 'Mostrar en el menú',
                              ),
                            ),
                            PopupMenuItem(
                              value: 'featured',
                              child: Text(
                                p.isFeatured ? 'Quitar destacado' : 'Destacar',
                              ),
                            ),
                            PopupMenuItem(
                              value: 'explorar',
                              child: Text(
                                p.enExplorar
                                    ? 'Quitar de Explorar'
                                    : 'Mostrar en Explorar',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Eliminar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
