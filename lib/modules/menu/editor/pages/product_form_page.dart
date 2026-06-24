import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/category_icons.dart';
import '../../../../services/menu_editor_service.dart';
import '../../../../shared/app_colors.dart';
import '../../../../components/layout/sidebar.dart';
import '../models/editor_menu_model.dart';

// Equivalente a src/modules/menu/editor/ProductFormPage.jsx en React
// Crear / editar un producto. Si es nuevo → paso 1: seleccionar categoría.

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({
    super.key,
    required this.menuId,
    this.productId,
  });

  final int menuId;
  final String? productId;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  bool _loading = true;
  bool _saving  = false;

  EditorMenu? _menu;
  EditorProduct? _product;

  // Si es nuevo y aún no eligió categoría
  bool _showCatStep = false;

  // Imagen local seleccionada (antes de subir)
  File? _localImage;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  bool get _isCreate => widget.productId == null;

  Future<void> _loadMenu() async {
    try {
      final data = await MenuEditorService.getById(widget.menuId);
      final menu = EditorMenu.fromJson(data);
      if (!mounted) return;
      setState(() {
        _menu = menu;
        if (_isCreate) {
          _product = EditorProduct.empty('');
          _showCatStep = true;
        } else {
          _product = menu.draft.products
              .where((p) => p.id == widget.productId)
              .cast<EditorProduct?>()
              .firstOrNull;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool get _canSave =>
      (_product?.name.trim().isNotEmpty ?? false) &&
      (_product?.price ?? 0) > 0 &&
      (_product?.categoryId.isNotEmpty ?? false);

  Future<void> _handleSave() async {
    if (!_canSave || _menu == null || _product == null) return;
    setState(() => _saving = true);

    try {
      String imageUrl = _product!.imageUrl ?? '';

      // Si hay imagen local, subirla al backend
      if (_localImage != null) {
        final url = await MenuEditorService.uploadImage(
            widget.menuId, _localImage!, 'producto');
        if (url != null) imageUrl = url;
      }

      final saved = _product!.copyWith(imageUrl: imageUrl);

      final List<EditorProduct> updated;
      if (_isCreate) {
        updated = [..._menu!.draft.products, saved];
      } else {
        updated = _menu!.draft.products
            .map((p) => p.id == saved.id ? saved : p)
            .toList();
      }

      await MenuEditorService.updateDraft(
          widget.menuId, {'products': updated.map((p) => p.toJson()).toList()});

      if (!mounted) return;
      _showSnack(_isCreate ? 'Producto creado' : 'Cambios guardados');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack('No se pudo guardar: ${e.toString().replaceFirst('Exception: ', '')}',
          error: true);
      setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() {
      _localImage = File(picked.path);
      _product = _product!.copyWith(imageUrl: picked.path);
    });
  }

  void _set(EditorProduct Function(EditorProduct) updater) {
    if (_product == null) return;
    setState(() => _product = updater(_product!));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_menu == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudo cargar el menú.', style: TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              TextButton(onPressed: () => context.pop(), child: const Text('Volver')),
            ],
          ),
        ),
      );
    }

    // Sin categorías — bloqueo total al crear
    if (_isCreate && _menu!.draft.categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.pop()),
          title: const Text('Nuevo producto'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_outlined, size: 48, color: Color(0xFFF59E0B)),
                const SizedBox(height: 16),
                const Text('Necesitas al menos una categoría',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text(
                  'Los productos deben pertenecer a una categoría. Crea una antes de agregar productos.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)), textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.pop(),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.kBlue),
                  child: const Text('Ir a Categorías'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Paso 1: seleccionar categoría (solo al crear)
    if (_isCreate && _showCatStep) {
      return _CategoryStepPage(
        categories: _menu!.draft.categories,
        onSelect: (catId) {
          setState(() {
            _product = _product!.copyWith(categoryId: catId);
            _showCatStep = false;
          });
        },
        onBack: () => context.pop(),
      );
    }

    // Producto no encontrado (edición)
    if (!_isCreate && _product == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Producto no encontrado.', style: TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              TextButton(onPressed: () => context.pop(), child: const Text('Volver')),
            ],
          ),
        ),
      );
    }

    final p = _product!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppSidebar(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: () => context.pop()),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isCreate ? 'Nuevo producto' : 'Editar: ${p.name}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            Text(
              _menu!.draft.info.name,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          Builder(builder: (ctx) {
            final hasDrawer = Scaffold.maybeOf(ctx)?.hasDrawer ?? false;
            if (!hasDrawer) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.menu, size: 22),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: (_canSave && !_saving) ? _handleSave : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.kBlue,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isCreate ? 'Crear' : 'Guardar',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Imagen ─────────────────────────────────────────────────────
            _FormSection(
              title: 'Imagen del producto',
              child: _ImageField(
                imageUrl: _localImage != null ? null : p.imageUrl,
                localFile: _localImage,
                onPick: _pickImage,
                onClear: () => setState(() { _localImage = null; _product = p.copyWith(imageUrl: ''); }),
              ),
            ),

            // ── Visibilidad ────────────────────────────────────────────────
            _FormSection(
              title: 'Visibilidad',
              child: Column(
                children: [
                  _ToggleRow(
                    label: 'Visible en el menú',
                    hint: 'Si está oculto, los clientes no lo ven',
                    value: p.isVisible,
                    onChanged: (v) => _set((x) => x.copyWith(isVisible: v)),
                  ),
                  const SizedBox(height: 10),
                  _ToggleRow(
                    label: 'Destacado',
                    hint: "Aparece en la fila 'Más Populares'",
                    value: p.isFeatured,
                    onChanged: (v) => _set((x) => x.copyWith(isFeatured: v)),
                  ),
                ],
              ),
            ),

            // ── Información básica ─────────────────────────────────────────
            _FormSection(
              title: 'Información básica',
              child: Column(
                children: [
                  _LabeledField(
                    label: 'Nombre del plato *',
                    child: TextField(
                      controller: TextEditingController(text: p.name)
                        ..selection = TextSelection.collapsed(offset: p.name.length),
                      onChanged: (v) => _set((x) => x.copyWith(name: v)),
                      maxLength: 50,
                      decoration: _inputDeco(hint: 'Ej: Hamburguesa Classic Smash'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    label: 'Descripción',
                    child: TextField(
                      controller: TextEditingController(text: p.description)
                        ..selection = TextSelection.collapsed(offset: p.description.length),
                      onChanged: (v) => _set((x) => x.copyWith(description: v)),
                      maxLength: 200,
                      maxLines: 3,
                      decoration: _inputDeco(hint: 'Describe el plato de forma apetitosa…'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    label: 'Precio base *',
                    child: TextField(
                      controller: TextEditingController(
                          text: p.price > 0 ? p.price.toInt().toString() : '')
                        ..selection = TextSelection.collapsed(
                            offset: p.price > 0 ? p.price.toInt().toString().length : 0),
                      onChanged: (v) {
                        final raw = v.replaceAll(RegExp(r'[^0-9]'), '');
                        _set((x) => x.copyWith(price: raw.isEmpty ? 0 : double.parse(raw)));
                      },
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDeco(hint: '18000'),
                    ),
                  ),
                  if (!_isCreate) ...[
                    const SizedBox(height: 12),
                    _LabeledField(
                      label: 'Categoría *',
                      child: DropdownButtonFormField<String>(
                        initialValue: p.categoryId.isNotEmpty ? p.categoryId : null,
                        decoration: _inputDeco(),
                        items: _menu!.draft.categories.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name, style: const TextStyle(fontSize: 13)),
                            )).toList(),
                        onChanged: (v) { if (v != null) _set((x) => x.copyWith(categoryId: v)); },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Promoción ──────────────────────────────────────────────────
            _FormSection(
              title: 'Promoción',
              child: Column(
                children: [
                  _ToggleRow(
                    label: 'Activar promoción',
                    hint: 'El precio promocional reemplaza al precio base',
                    value: p.promoActive,
                    onChanged: (v) => _set((x) => x.copyWith(promoActive: v)),
                  ),
                  if (p.promoActive) ...[
                    const SizedBox(height: 12),
                    _LabeledField(
                      label: 'Precio promocional',
                      child: TextField(
                        controller: TextEditingController(
                            text: p.promoPrice != null ? p.promoPrice!.toInt().toString() : '')
                          ..selection = TextSelection.collapsed(
                              offset: p.promoPrice != null ? p.promoPrice!.toInt().toString().length : 0),
                        onChanged: (v) {
                          final raw = v.replaceAll(RegExp(r'[^0-9]'), '');
                          _set((x) => x.copyWith(promoPrice: raw.isEmpty ? null : double.parse(raw)));
                        },
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _inputDeco(hint: '12000', hint2: 'Debe ser menor al precio base'),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Variantes / tamaños ────────────────────────────────────────
            _VariantSection(
              title: 'Variantes / Tamaños',
              subtitle: 'Ej: 1/4 libra \$18.000, 1/2 libra \$22.000',
              items: p.sizes,
              onChange: (list) => _set((x) => x.copyWith(sizes: list)),
            ),

            // ── Personalización ────────────────────────────────────────────
            _VariantSection(
              title: 'Personalización',
              subtitle: 'Modificaciones. Ej: Sin cebolla \$0, Extra queso \$1.500',
              items: p.ingredients,
              onChange: (list) => _set((x) => x.copyWith(ingredients: list)),
              allowNegative: true,
            ),

            // ── Adiciones ─────────────────────────────────────────────────
            _VariantSection(
              title: 'Adiciones',
              subtitle: 'Extras. Ej: Papas fritas \$3.500, Bebida \$4.000',
              items: p.extras,
              onChange: (list) => _set((x) => x.copyWith(extras: list)),
            ),

            // ── Grupos informativos ────────────────────────────────────────
            if (_menu!.draft.grupos.isNotEmpty)
              _FormSection(
                title: 'Grupos informativos',
                child: Column(
                  children: _menu!.draft.grupos
                      .where((g) => g.isActive)
                      .map((g) {
                        final checked = p.grupoIds.contains(g.id);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (v) {
                            final updated = checked
                                ? p.grupoIds.where((id) => id != g.id).toList()
                                : [...p.grupoIds, g.id];
                            _set((x) => x.copyWith(grupoIds: updated));
                          },
                          title: Text(g.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: g.items.isNotEmpty
                              ? Text(
                                  g.items.take(4).map((i) => i.name).join(' · '),
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                )
                              : null,
                          activeColor: AppColors.kBlue,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        );
                      })
                      .toList(),
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco({String? hint, String? hint2}) => InputDecoration(
        hintText: hint,
        helperText: hint2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        counterText: '',
      );
}

// ── Paso 1: Seleccionar categoría ─────────────────────────────────────────────
class _CategoryStepPage extends StatelessWidget {
  const _CategoryStepPage({
    required this.categories,
    required this.onSelect,
    required this.onBack,
  });

  final List<EditorCategory> categories;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: onBack),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Nuevo producto', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Text('Paso 1 — Selecciona una categoría',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿En qué categoría irá este producto?',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: categories.map((cat) => GestureDetector(
                  onTap: () => onSelect(cat.id),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(categoryIcon(cat.icon), size: 22, color: AppColors.kBlue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(cat.name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                  overflow: TextOverflow.ellipsis),
                              if (cat.tipoContenido == 'sin_imagenes')
                                const Text('Sin imágenes',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────────
class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            const Divider(height: 14, color: Color(0xFFF1F5F9)),
            child,
          ],
        ),
      );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 6),
          child,
        ],
      );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.hint, required this.value, required this.onChanged});
  final String label;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(hint, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.kBlue,
            activeTrackColor: const Color(0xFFC7D2FE),
          ),
        ],
      );
}

class _ImageField extends StatelessWidget {
  const _ImageField({this.imageUrl, this.localFile, required this.onPick, required this.onClear});
  final String? imageUrl;
  final File? localFile;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasImage = localFile != null || (imageUrl != null && imageUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: localFile != null
                    ? Image.file(localFile!, height: 140, width: double.infinity, fit: BoxFit.cover)
                    : Image.network(imageUrl!, height: 140, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => Container(
                          height: 140, color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.broken_image_outlined, color: Color(0xFFCBD5E1)),
                        )),
              ),
              Positioned(
                top: 6, right: 6,
                child: GestureDetector(
                  onTap: onClear,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: onPick,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 32, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 6),
                  Text('Seleccionar imagen', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.photo_library_outlined, size: 14),
          label: Text(hasImage ? 'Cambiar imagen' : 'Elegir de galería',
              style: const TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

// ── Formatters de variantes ───────────────────────────────────────────────────

// Equivalente a sanitizeLabel en React/format.js:
// quita chars que no sean letras (incluye acentos), dígitos, espacios, guiones o /
// y capitaliza la primera letra. Máx 35 chars.
class _LabelFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue newVal) {
    var text = newVal.text.replaceAll(RegExp(r'[^\p{L}0-9\s\-/]', unicode: true), '');
    if (text.length > 35) text = text.substring(0, 35);
    if (text.isNotEmpty) text = text[0].toUpperCase() + text.substring(1);
    return newVal.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// Equivalente al PriceInput allowNegative=true de React (Personalización):
// solo dígitos y guión, guión únicamente al inicio, máx 7 dígitos.
class _SignedIntFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue newVal) {
    var text = newVal.text.replaceAll(RegExp(r'[^0-9\-]'), '');
    final hasMinus = text.startsWith('-');
    final digits   = text.replaceAll('-', '');
    text = (hasMinus ? '-' : '') + digits;
    final maxLen = 7 + (hasMinus ? 1 : 0);
    if (text.length > maxLen) text = text.substring(0, maxLen);
    return newVal.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ── Sección de variantes (sizes / ingredients / extras) ───────────────────────
class _VariantSection extends StatelessWidget {
  const _VariantSection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.onChange,
    this.allowNegative = false,
  });

  final String title;
  final String subtitle;
  final List<EditorVariant> items;
  final ValueChanged<List<EditorVariant>> onChange;
  final bool allowNegative;

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 10),
          ...List.generate(items.length, (i) {
            final item = items[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: TextEditingController(text: item.label)
                        ..selection = TextSelection.collapsed(offset: item.label.length),
                      inputFormatters: [_LabelFormatter()],
                      onChanged: (v) {
                        final updated = List<EditorVariant>.from(items);
                        updated[i] = EditorVariant(id: item.id, label: v, price: item.price);
                        onChange(updated);
                      },
                      decoration: InputDecoration(
                        hintText: 'Nombre',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: TextEditingController(
                          text: item.price != 0 ? item.price.toInt().toString() : '')
                        ..selection = TextSelection.collapsed(
                            offset: item.price != 0 ? item.price.toInt().toString().length : 0),
                      inputFormatters: allowNegative
                          ? [_SignedIntFormatter()]
                          : [FilteringTextInputFormatter.digitsOnly,
                             LengthLimitingTextInputFormatter(6)],
                      onChanged: (v) {
                        final price = v.isEmpty ? 0.0 : (int.tryParse(v) ?? 0).toDouble();
                        final updated = List<EditorVariant>.from(items);
                        updated[i] = EditorVariant(id: item.id, label: item.label, price: price);
                        onChange(updated);
                      },
                      keyboardType: allowNegative
                          ? const TextInputType.numberWithOptions(signed: true)
                          : TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '\$0',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final updated = List<EditorVariant>.from(items)..removeAt(i);
                      onChange(updated);
                    },
                    icon: const Icon(Icons.delete_outline, size: 15, color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => onChange([...items, EditorVariant.empty()]),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Agregar', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.kBlue,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }
}
