import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../components/layout/sidebar.dart';
import '../../../services/image_upload_service.dart';
import '../../../services/menu_editor_service.dart';
import '../../../services/mis_menus_service.dart';
import '../../../services/public_api_service.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/app_header.dart';
import '../../../shared/logo_crop_dialog.dart';
import 'models/create_menu_models.dart';

// Equivalente a src/modules/menu/create/pages/CreateMenuPage.jsx en React:
// crear es rápido (categoría, nombre, link, logo y portada). El resto se
// completa después desde el hub/editor.

class CreateMenuPage extends StatefulWidget {
  const CreateMenuPage({super.key});

  @override
  State<CreateMenuPage> createState() => _CreateMenuPageState();
}

class _CreateMenuPageState extends State<CreateMenuPage> {
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();

  final _picker = ImagePicker();
  File? _logo;
  File? _banner;

  String? _categoryCode;
  List<CategoriaRestaurante> _categories = const [];
  bool _loadingCategories = true;
  String? _categoriesError;

  bool _slugManual = false;
  bool _checkingSlug = false;
  bool? _slugAvailable;
  Timer? _slugDebounce;

  bool _saving = false;
  String? _savingStatus;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _slugDebounce?.cancel();
    _nameController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoriesError = null;
    });
    try {
      final list = await PublicApiService.listarCategorias();
      if (!mounted) return;
      setState(() {
        _categories = list;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoriesError = e.toString().replaceFirst('Exception: ', '');
        _loadingCategories = false;
      });
    }
  }

  bool get _ready {
    return !_saving &&
        _categoryCode != null &&
        _nameController.text.trim().isNotEmpty &&
        slugError(_slugController.text) == null &&
        _slugAvailable != false;
  }

  void _onNameChanged(String value) {
    setState(() {});
    if (_slugManual) return;
    final next = slugify(value);
    _slugController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _scheduleSlugCheck(next);
    setState(() {});
  }

  void _onSlugChanged(String value) {
    _slugManual = true;
    final clean = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '');
    if (clean != value) {
      _slugController.value = TextEditingValue(
        text: clean,
        selection: TextSelection.collapsed(offset: clean.length),
      );
    }
    setState(() {});
    _scheduleSlugCheck(clean);
  }

  void _scheduleSlugCheck(String slug) {
    _slugDebounce?.cancel();
    if (slug.isEmpty || slugError(slug) != null) {
      if (mounted) {
        setState(() {
          _slugAvailable = null;
          _checkingSlug = false;
        });
      }
      return;
    }
    setState(() => _checkingSlug = true);
    _slugDebounce = Timer(const Duration(milliseconds: 500), () async {
      final ok = await MenuEditorService.checkSlugCode(slug);
      if (!mounted || _slugController.text != slug) return;
      setState(() {
        _slugAvailable = ok;
        _checkingSlug = false;
      });
    });
  }

  String get _slugHint {
    final slug = _slugController.text;
    if (slug.isEmpty) {
      return 'Se genera automáticamente desde el nombre. Puedes cambiarlo.';
    }
    final err = slugError(slug);
    if (err != null) return err;
    if (_checkingSlug) return 'Verificando disponibilidad…';
    if (_slugAvailable == false) {
      return 'Este link ya está publicado por otro negocio. Elige otro.';
    }
    return 'zammpy.com/menu/$slug';
  }

  Color get _slugColor {
    if (_slugController.text.isEmpty) return AppColors.kTextMuted;
    if (slugError(_slugController.text) != null || _slugAvailable == false) {
      return AppColors.kRed;
    }
    if (_slugAvailable == true) return AppColors.kBlue;
    return AppColors.kTextMuted;
  }

  Future<void> _pickLogo() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;
    final cropped = await showLogoCropDialog(context, File(picked.path));
    if (cropped == null || !mounted) return;
    final error = ImageUploadService.validate(cropped);
    if (error != null) return _error(error);
    setState(() => _logo = cropped);
  }

  Future<void> _pickBanner() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final file = File(picked.path);
    final error = ImageUploadService.validate(file);
    if (error != null) return _error(error);
    setState(() => _banner = file);
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.kRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _warning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB45309),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _create() async {
    if (!_ready) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _savingStatus = 'Creando menú…';
    });

    Map<String, dynamic> created;
    try {
      created = await MenuEditorService.create(
        CrearMenuDraft(
          restaurantCategoryCode: _categoryCode!,
          name: _nameController.text,
          slug: _slugController.text,
        ).toJson(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _savingStatus = null;
      });
      _error(
        'No se pudo crear el menú: ${e.toString().replaceFirst('Exception: ', '')}',
      );
      return;
    }

    final codigo = (created['codigo'] ?? created['id'] ?? '').toString();
    if (codigo.isEmpty) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _savingStatus = null;
      });
      _error('El menú se creó, pero no se recibió su código.');
      return;
    }

    var imageFailed = false;

    if (_logo != null) {
      if (mounted) setState(() => _savingStatus = 'Subiendo logo…');
      String? logoUrl;
      try {
        logoUrl = await ImageUploadService.upload(_logo!, 'menus/$codigo/logo');
        await MenuEditorService.seccion(codigo, 'logo', {'logoUrl': logoUrl});
      } catch (_) {
        imageFailed = true;
        if (logoUrl != null) await ImageUploadService.delete(logoUrl);
      }
    }

    if (_banner != null) {
      if (mounted) setState(() => _savingStatus = 'Subiendo portada…');
      String? bannerUrl;
      try {
        bannerUrl = await ImageUploadService.upload(
          _banner!,
          'menus/$codigo/banner',
        );
        await MenuEditorService.seccion(codigo, 'portada', {
          'bannerUrl': bannerUrl,
        });
      } catch (_) {
        imageFailed = true;
        if (bannerUrl != null) await ImageUploadService.delete(bannerUrl);
      }
    }

    MisMenusService.invalidate();
    if (!mounted) return;

    if (imageFailed) {
      _warning(
        'Menú creado. No se pudieron subir todas las imágenes; '
        'puedes agregarlas desde el menú.',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Menú creado! Completa lo que falta desde el menú.'),
          backgroundColor: AppColors.kBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    context.go('/menus/$codigo');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) {
        if (GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
        } else {
          context.go('/menus');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.kBgPage,
        drawer: const AppSidebar(),
        appBar: const AppHeader(
          title: 'Crear nuevo menú',
          subtitle: 'Solo lo básico; lo demás lo completas después',
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  _Card(
                    title: 'Tu negocio',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('Nombre del negocio *'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          autofocus: true,
                          maxLength: 35,
                          textCapitalization: TextCapitalization.words,
                          onChanged: _onNameChanged,
                          decoration: _inputDeco(
                            hint: 'Ej: Pizzería La Napolitana',
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _Label('Link de tu menú'),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 14,
                                ),
                                color: const Color(0xFFF8FAFC),
                                child: const Text(
                                  'zammpy.com/menu/',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.kTextMuted,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _slugController,
                                  maxLength: 50,
                                  onChanged: _onSlugChanged,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'mi-pizzeria',
                                    counterText: '',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 14,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: _slugColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: _slugColor),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (_checkingSlug) ...[
                              const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                            Expanded(
                              child: Text(
                                _slugHint,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _slugColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Card(
                    title: 'Tipo de negocio *',
                    subtitle:
                        'Elige la categoría que mejor describa tu restaurante. '
                        'Esto ayuda a otros usuarios a descubrirte.',
                    child: _buildCategories(),
                  ),
                  const SizedBox(height: 14),
                  _Card(
                    title: 'Logo y portada',
                    subtitle: 'Opcional — puedes agregarlas después.',
                    child: Column(
                      children: [
                        _ImagePicker(
                          label: 'Logo',
                          hint: 'Se recorta en 1:1. PNG o JPG.',
                          file: _logo,
                          isLogo: true,
                          onPick: _pickLogo,
                          onClear: () => setState(() => _logo = null),
                        ),
                        const Divider(height: 22),
                        _ImagePicker(
                          label: 'Foto de portada',
                          hint: 'Recomendado 1200×400 px.',
                          file: _banner,
                          isLogo: false,
                          onPick: _pickBanner,
                          onClear: () => setState(() => _banner = null),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                MediaQuery.of(context).padding.bottom + 10,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.kCardBorder)),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : () => context.go('/menus'),
                    child: const Text('Cancelar'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _ready ? _create : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.kBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    child: _saving
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_savingStatus ?? 'Creando…'),
                            ],
                          )
                        : const Text('Crear menú'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    if (_loadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator(color: AppColors.kBlue)),
      );
    }
    if (_categoriesError != null) {
      return Column(
        children: [
          Text(
            'No se pudieron cargar las categorías.\n$_categoriesError',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _loadCategories,
            icon: const Icon(Icons.refresh, size: 15),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }
    if (_categories.isEmpty) {
      return const Text(
        'No hay categorías disponibles.',
        style: TextStyle(fontSize: 12, color: AppColors.kTextMuted),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 125,
        mainAxisExtent: 82,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final selected = cat.codigo == _categoryCode;
        return GestureDetector(
          onTap: () => setState(() => _categoryCode = cat.codigo),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFEEF2FF) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.kBlue : AppColors.kCardBorder,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _categoryIcon(cat.icono),
                  size: 21,
                  color: selected ? AppColors.kBlue : AppColors.kTextMuted,
                ),
                const SizedBox(height: 4),
                Text(
                  cat.nombre,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.kBlue
                        : AppColors.kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.kTextPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.kTextMuted,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xFF374151),
    ),
  );
}

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.label,
    required this.hint,
    required this.file,
    required this.isLogo,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final String hint;
  final File? file;
  final bool isLogo;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasImage = file != null;
    final preview = ClipRRect(
      borderRadius: BorderRadius.circular(isLogo ? 14 : 10),
      child: hasImage
          ? Image.file(file!, fit: BoxFit.cover)
          : Container(
              color: const Color(0xFFF8FAFC),
              child: const Center(
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Color(0xFFCBD5E1),
                  size: 24,
                ),
              ),
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const Spacer(),
            Text(
              hint,
              style: const TextStyle(fontSize: 10, color: AppColors.kTextMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(width: isLogo ? 76 : 132, height: 76, child: preview),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.photo_library_outlined, size: 13),
                    label: Text(
                      hasImage ? 'Cambiar' : 'Elegir',
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kTextSecondary,
                      side: const BorderSide(color: AppColors.kCardBorder),
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                  if (hasImage)
                    TextButton(
                      onPressed: onClear,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.kRed,
                        minimumSize: const Size(0, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: const Text(
                        'Quitar',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

InputDecoration _inputDeco({String? hint}) => InputDecoration(
  hintText: hint,
  counterText: '',
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.kBlue),
  ),
);

IconData _categoryIcon(String icono) => switch (icono) {
  'zap' => Icons.bolt,
  'beef' => Icons.kebab_dining,
  'pizza' => Icons.local_pizza,
  'ice-cream' => Icons.icecream,
  'coffee' => Icons.local_cafe,
  'fish' => Icons.set_meal,
  'waves' => Icons.waves,
  'flame' || 'pepper' => Icons.local_fire_department,
  'cake' => Icons.cake,
  'leaf' => Icons.eco,
  'wine' => Icons.wine_bar,
  'moon' => Icons.nightlight_outlined,
  'wand' => Icons.auto_fix_high,
  'chef-hat' => Icons.restaurant,
  'star' => Icons.star_outline,
  'flag' => Icons.flag_outlined,
  'circle' => Icons.circle_outlined,
  'candy' => Icons.cake_outlined,
  'cup-soda' => Icons.local_drink_outlined,
  'salad' => Icons.grass,
  'bird' => Icons.set_meal_outlined,
  'sunrise' => Icons.wb_sunny_outlined,
  'sandwich' => Icons.lunch_dining,
  _ => Icons.restaurant_menu,
};
