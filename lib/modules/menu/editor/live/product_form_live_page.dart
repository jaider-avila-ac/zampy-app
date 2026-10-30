import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../services/image_upload_service.dart';
import '../../../../../services/live_editor_service.dart';
import '../../../../../shared/app_colors.dart';
import '../../../../../shared/app_header.dart';
import 'editor_models.dart';

class LiveProductFormPage extends StatefulWidget {
  const LiveProductFormPage({
    super.key,
    required this.codigo,
    this.productCode,
  });

  final String codigo;
  final String? productCode;

  @override
  State<LiveProductFormPage> createState() => _LiveProductFormPageState();
}

class _LiveProductFormPageState extends State<LiveProductFormPage> {
  LiveMenu? _menu;
  LiveProduct? _product;
  bool _loading = true;
  bool _busy = false;

  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _promoPrice = TextEditingController();
  final _promoEnds = TextEditingController();
  final _imageCtrl = TextEditingController();
  String? _categoryId;
  bool _visible = true;
  bool _featured = false;
  bool _promo = false;
  List<String> _grupoIds = [];

  List<_VariantRow> _sizes = [];
  List<_VariantRow> _ingredients = [];
  List<_VariantRow> _extras = [];

  bool get _isNew => widget.productCode == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _desc,
      _price,
      _promoPrice,
      _promoEnds,
      _imageCtrl,
    ]) {
      c.dispose();
    }
    _disposeRows(_sizes);
    _disposeRows(_ingredients);
    _disposeRows(_extras);
    super.dispose();
  }

  void _disposeRows(List<_VariantRow> rows) {
    for (final r in rows) {
      r.label.dispose();
      r.price.dispose();
    }
  }

  Future<void> _load() async {
    try {
      final menu = await LiveEditorService.load(widget.codigo);
      LiveProduct? product;
      if (!_isNew) {
        product = menu.products
            .where((p) => p.codigo == widget.productCode)
            .firstOrNull;
      }
      if (!mounted) return;
      setState(() {
        _menu = menu;
        _product = product;
        _categoryId =
            product?.categoryId ??
            (menu.categories.isNotEmpty ? menu.categories.first.codigo : null);
        _visible = product?.isVisible ?? true;
        _featured = product?.isFeatured ?? false;
        _promo = product?.promoActive ?? false;
        _grupoIds = [...(product?.grupoIds ?? [])];
        _name.text = product?.name ?? '';
        _desc.text = product?.description ?? '';
        _price.text = (product?.price ?? 0).toStringAsFixed(0);
        _promoPrice.text = product?.promoPrice?.toStringAsFixed(0) ?? '';
        _promoEnds.text = product?.promoEndsAt ?? '';
        _imageCtrl.text = product?.imageUrl ?? '';
        _sizes = _rows(product?.sizes ?? [], price: true);
        _ingredients = _rows(product?.ingredients ?? [], removable: true);
        _extras = _rows(product?.extras ?? [], price: true);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  List<_VariantRow> _rows(
    List<Map<String, dynamic>> raw, {
    bool price = false,
    bool removable = false,
  }) {
    return raw.map((e) {
      final row = _VariantRow(
        label: TextEditingController(text: e['label'] as String? ?? ''),
        price: TextEditingController(
          text: price
              ? ((e['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)
              : '',
        ),
        removable: removable ? e['removable'] == true : false,
      );
      return row;
    }).toList();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.kRed : AppColors.kGreen,
      ),
    );
  }

  Future<void> _saveBasic() async {
    if (_busy) return;
    if (_name.text.trim().isEmpty || _categoryId == null) {
      _snack('Nombre y categorÃ­a son obligatorios.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final body = {
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'price': double.tryParse(_price.text) ?? 0,
        'categoryId': _categoryId,
        'imageUrl': _imageCtrl.text.trim(),
        'isVisible': _visible,
        'isFeatured': _featured,
      };
      if (_isNew) {
        final created = await LiveEditorService.createProduct(
          widget.codigo,
          body,
        );
        await LiveEditorService.updateProductPart(
          widget.codigo,
          created.codigo,
          'grupos',
          _grupoIds,
        );
        if (mounted) {
          Navigator.of(context).pop();
          _snack('Producto creado.');
        }
      } else {
        await LiveEditorService.updateProductBasic(
          widget.codigo,
          widget.productCode!,
          body,
        );
        _snack('Producto guardado.');
      }
      await _load();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uploadImage() async {
    if (_isNew) {
      _snack('Guarda el producto antes de subir la imagen.', error: true);
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final error = ImageUploadService.validate(File(picked.path));
    if (error != null) return _snack(error, error: true);
    setState(() => _busy = true);
    try {
      final url = await LiveEditorService.upload(
        widget.codigo,
        'productos',
        File(picked.path),
      );
      _imageCtrl.text = url;
      await LiveEditorService.updateProductBasic(
        widget.codigo,
        widget.productCode!,
        {
          'name': _name.text.trim(),
          'description': _desc.text.trim(),
          'price': double.tryParse(_price.text) ?? 0,
          'categoryId': _categoryId,
          'imageUrl': url,
          'imagePosition': _product?.imagePosition,
          'isVisible': _visible,
          'isFeatured': _featured,
        },
      );
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _savePart(
    String part,
    List<_VariantRow> rows, {
    bool price = false,
  }) async {
    if (_isNew) {
      _snack('Guarda el producto primero.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final body = [
        for (final r in rows)
          if (r.label.text.trim().isNotEmpty)
            {
              'label': r.label.text.trim(),
              if (price) 'price': double.tryParse(r.price.text) ?? 0,
              if (part == 'ingredientes') 'removable': r.removable,
            },
      ];
      await LiveEditorService.updateProductPart(
        widget.codigo,
        widget.productCode!,
        part,
        body,
      );
      _snack('Guardado.');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _savePromo() async {
    if (_isNew) {
      _snack('Guarda el producto primero.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await LiveEditorService.updateProductPart(
        widget.codigo,
        widget.productCode!,
        'promocion',
        {
          'activa': _promo,
          'precio': double.tryParse(_promoPrice.text),
          'vence': _promoEnds.text.trim().isEmpty
              ? null
              : _promoEnds.text.trim(),
        },
      );
      _snack('PromociÃ³n guardada.');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveGroups() async {
    if (_isNew) return;
    setState(() => _busy = true);
    try {
      await LiveEditorService.updateProductPart(
        widget.codigo,
        widget.productCode!,
        'grupos',
        _grupoIds,
      );
      _snack('Grupos guardados.');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (_isNew) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('Â¿Eliminar "${_name.text}"?'),
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
    try {
      await LiveEditorService.deleteProduct(widget.codigo, widget.productCode!);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final menu = _menu;
    if (menu == null) {
      return const Scaffold(body: Center(child: Text('No se pudo cargar.')));
    }
    return Scaffold(
      backgroundColor: AppColors.kBgPage,
      appBar: AppHeader(
        title: _isNew ? 'Nuevo producto' : (_product?.name ?? 'Producto'),
        actions: [
          if (!_isNew)
            IconButton(
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline, color: AppColors.kRed),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          _Box(
            title: 'Datos bÃ¡sicos',
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'DescripciÃ³n'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Precio *'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'CategorÃ­a *'),
                  items: menu.categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.codigo,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visible', style: TextStyle(fontSize: 13)),
                  value: _visible,
                  onChanged: (v) => setState(() => _visible = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Destacado',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: _featured,
                  onChanged: (v) => setState(() => _featured = v),
                ),
                _ImageRow(
                  url: _imageCtrl.text,
                  busy: _busy,
                  onPick: _uploadImage,
                ),
                _SaveButton(busy: _busy, onTap: _saveBasic),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _VariantsBox(
            title: 'TamaÃ±os',
            rows: _sizes,
            price: true,
            onAdd: () => setState(
              () => _sizes.add(
                _VariantRow(
                  label: TextEditingController(),
                  price: TextEditingController(),
                ),
              ),
            ),
            onRemove: (i) => setState(() => _sizes.removeAt(i)),
            onSave: () => _savePart('tamanos', _sizes, price: true),
            busy: _busy,
          ),
          const SizedBox(height: 12),
          _VariantsBox(
            title: 'Ingredientes',
            rows: _ingredients,
            removable: true,
            onToggleRemovable: (i, v) =>
                setState(() => _ingredients[i].removable = v),
            onAdd: () => setState(
              () => _ingredients.add(
                _VariantRow(
                  label: TextEditingController(),
                  price: TextEditingController(),
                  removable: true,
                ),
              ),
            ),
            onRemove: (i) => setState(() => _ingredients.removeAt(i)),
            onSave: () => _savePart('ingredientes', _ingredients),
            busy: _busy,
          ),
          const SizedBox(height: 12),
          _VariantsBox(
            title: 'Adiciones',
            rows: _extras,
            price: true,
            onAdd: () => setState(
              () => _extras.add(
                _VariantRow(
                  label: TextEditingController(),
                  price: TextEditingController(),
                ),
              ),
            ),
            onRemove: (i) => setState(() => _extras.removeAt(i)),
            onSave: () => _savePart('adiciones', _extras, price: true),
            busy: _busy,
          ),
          const SizedBox(height: 12),
          _Box(
            title: 'Grupos de opciones',
            child: Column(
              children: [
                if (menu.groups.isEmpty)
                  const Text(
                    'No hay grupos creados.',
                    style: TextStyle(fontSize: 12, color: AppColors.kTextMuted),
                  )
                else
                  for (final g in menu.groups)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(g.name, style: const TextStyle(fontSize: 13)),
                      value: _grupoIds.contains(g.codigo),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _grupoIds.add(g.codigo);
                        } else {
                          _grupoIds.remove(g.codigo);
                        }
                      }),
                    ),
                _SaveButton(busy: _busy, onTap: _saveGroups),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Box(
            title: 'PromociÃ³n',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'PromociÃ³n activa',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: _promo,
                  onChanged: (v) => setState(() => _promo = v),
                ),
                if (_promo) ...[
                  TextField(
                    controller: _promoPrice,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio promocional',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _promoEnds,
                    decoration: const InputDecoration(
                      labelText: 'Vence (AAAA-MM-DD)',
                    ),
                  ),
                ],
                _SaveButton(busy: _busy, onTap: _savePromo),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantRow {
  _VariantRow({
    required this.label,
    required this.price,
    this.removable = false,
  });
  final TextEditingController label;
  final TextEditingController price;
  bool removable;
}

class _Box extends StatelessWidget {
  const _Box({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.kCardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _VariantsBox extends StatelessWidget {
  const _VariantsBox({
    required this.title,
    required this.rows,
    required this.onAdd,
    required this.onRemove,
    required this.onSave,
    required this.busy,
    this.price = false,
    this.removable = false,
    this.onToggleRemovable,
  });
  final String title;
  final List<_VariantRow> rows;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final VoidCallback onSave;
  final bool busy;
  final bool price;
  final bool removable;
  final void Function(int index, bool value)? onToggleRemovable;

  @override
  Widget build(BuildContext context) => _Box(
    title: title,
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: rows[i].label,
                    decoration: const InputDecoration(
                      hintText: 'Nombre',
                      isDense: true,
                    ),
                  ),
                ),
                if (price) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: rows[i].price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Precio',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
                if (removable)
                  Checkbox(
                    value: rows[i].removable,
                    onChanged: (v) => onToggleRemovable?.call(i, v == true),
                  ),
                IconButton(
                  onPressed: () => onRemove(i),
                  icon: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          ),
        Row(
          children: [
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Agregar'),
            ),
            const Spacer(),
            _SaveButton(busy: busy, onTap: onSave),
          ],
        ),
      ],
    ),
  );
}

class _ImageRow extends StatelessWidget {
  const _ImageRow({
    required this.url,
    required this.busy,
    required this.onPick,
  });
  final String url;
  final bool busy;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.kSkeleton,
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.hardEdge,
        child: url.isEmpty
            ? const Icon(Icons.fastfood_outlined)
            : Image.network(url, fit: BoxFit.cover),
      ),
      const SizedBox(width: 10),
      OutlinedButton(
        onPressed: busy ? null : onPick,
        child: Text(url.isEmpty ? 'Subir imagen' : 'Cambiar imagen'),
      ),
    ],
  );
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: FilledButton(
      onPressed: busy ? null : onTap,
      child: Text(busy ? 'â€¦' : 'Guardar'),
    ),
  );
}
