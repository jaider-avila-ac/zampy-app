import 'package:flutter/material.dart';

import '../../../../../services/live_editor_service.dart';
import '../../../../../shared/app_colors.dart';
import '../editor_models.dart';

class CategoriesLiveTab extends StatefulWidget {
  const CategoriesLiveTab({
    super.key,
    required this.menu,
    required this.onChanged,
  });

  final LiveMenu menu;
  final Future<void> Function() onChanged;

  @override
  State<CategoriesLiveTab> createState() => _CategoriesLiveTabState();
}

class _CategoriesLiveTabState extends State<CategoriesLiveTab> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.kRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openForm([LiveCategory? category]) async {
    final name = TextEditingController(text: category?.name ?? '');
    var icon = category?.icon ?? 'utensils';
    var type = category?.tipoContenido ?? 'con_imagenes';
    var visible = category?.isVisible ?? true;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category == null ? 'Nueva categoría' : 'Editar categoría',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  autofocus: true,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ícono',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final entry in _icons.entries)
                      ChoiceChip(
                        label: Icon(entry.value, size: 17),
                        selected: icon == entry.key,
                        onSelected: (_) => setModal(() => icon = entry.key),
                      ),
                  ],
                ),
                if (category == null) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de contenido',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'con_imagenes',
                        child: Text('Con imágenes'),
                      ),
                      DropdownMenuItem(
                        value: 'sin_imagenes',
                        child: Text('Sin imágenes'),
                      ),
                    ],
                    onChanged: (v) => setModal(() => type = v ?? type),
                  ),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visible', style: TextStyle(fontSize: 13)),
                  value: visible,
                  onChanged: (v) => setModal(() => visible = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (name.text.trim().isEmpty) return;
                        Navigator.pop(ctx, true);
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (created != true || !mounted) {
      name.dispose();
      return;
    }
    final body = {
      'name': name.text.trim(),
      'icon': icon,
      if (category == null) 'tipoContenido': type,
      'order': category?.order ?? widget.menu.categories.length,
      'isVisible': visible,
    };
    name.dispose();
    await _run(() async {
      if (category == null) {
        await LiveEditorService.createCategory(widget.menu.codigo, body);
      } else {
        await LiveEditorService.updateCategory(
          widget.menu.codigo,
          category.codigo,
          body,
        );
      }
    });
  }

  Future<void> _delete(LiveCategory category) async {
    final count = widget.menu.products
        .where((p) => p.categoryId == category.codigo)
        .length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          count > 0
              ? 'La categoría tiene $count producto(s). Elimínalos o muévelos antes de borrarla.'
              : '¿Eliminar "${category.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          if (count == 0)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.kRed),
              child: const Text('Eliminar'),
            ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(
      () =>
          LiveEditorService.deleteCategory(widget.menu.codigo, category.codigo),
    );
  }

  Future<void> _move(LiveCategory category, int dir) async {
    final list = [...widget.menu.categories];
    final index = list.indexWhere((c) => c.codigo == category.codigo);
    final next = index + dir;
    if (next < 0 || next >= list.length) return;
    final item = list.removeAt(index);
    list.insert(next, item);
    await _run(
      () => LiveEditorService.orderCategories(
        widget.menu.codigo,
        list.map((c) => c.codigo).toList(),
      ),
    );
  }

  Future<void> _toggle(LiveCategory category) async {
    await _run(
      () => LiveEditorService.updateCategory(
        widget.menu.codigo,
        category.codigo,
        {
          'name': category.name,
          'icon': category.icon,
          'order': category.order,
          'isVisible': !category.isVisible,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = widget.menu.categories;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Text(
                '${cats.length} categorías',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.kTextMuted,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy ? null : () => _openForm(),
                icon: const Icon(Icons.add, size: 15),
                label: const Text('Nueva'),
              ),
            ],
          ),
        ),
        Expanded(
          child: cats.isEmpty
              ? const Center(child: Text('Sin categorías.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                  itemCount: cats.length,
                  itemBuilder: (_, i) {
                    final c = cats[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.kCardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _icons[c.icon] ?? Icons.restaurant_menu,
                            color: AppColors.kBlue,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${c.tipoContenido == 'sin_imagenes' ? 'Sin imágenes' : 'Con imágenes'} · ${c.isVisible ? 'Visible' : 'Oculta'}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.kTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _busy ? null : () => _move(c, -1),
                            icon: const Icon(Icons.arrow_upward, size: 16),
                          ),
                          IconButton(
                            onPressed: _busy ? null : () => _move(c, 1),
                            icon: const Icon(Icons.arrow_downward, size: 16),
                          ),
                          IconButton(
                            onPressed: _busy ? null : () => _toggle(c),
                            icon: Icon(
                              c.isVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                            ),
                          ),
                          IconButton(
                            onPressed: _busy ? null : () => _openForm(c),
                            icon: const Icon(Icons.edit_outlined, size: 17),
                          ),
                          IconButton(
                            onPressed: _busy ? null : () => _delete(c),
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 17,
                              color: AppColors.kRed,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

const _icons = <String, IconData>{
  'utensils': Icons.restaurant_menu,
  'burger': Icons.lunch_dining,
  'pizza': Icons.local_pizza,
  'coffee': Icons.local_cafe,
  'drink': Icons.local_drink,
  'dessert': Icons.cake,
  'salad': Icons.grass,
  'fish': Icons.set_meal,
  'flame': Icons.local_fire_department,
  'star': Icons.star_outline,
};
