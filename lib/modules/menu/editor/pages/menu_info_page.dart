import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../services/menu_editor_service.dart';
import '../../../../services/themes_catalog_service.dart';
import '../../../../shared/app_colors.dart';
import '../../../../shared/location_cascade_widget.dart';
import '../../../../shared/logo_crop_dialog.dart';
import '../../../../shared/schedule_widget.dart';
import '../models/editor_menu_model.dart';

// Equivalente a src/modules/menu/editor/MenuInfoPage.jsx en React
// Wizard de 5 pasos para editar la información del menú.

// ── Categorías de restaurante (mismas que StepCategory.jsx en React) ───────────
const List<(int id, String name, IconData icon)> kRestaurantCategories = [
  (1,  'Comida Rápida',    Icons.bolt),
  (2,  'Pizzería',         Icons.local_pizza),
  (3,  'Heladería',        Icons.icecream),
  (4,  'Rest. Casual',     Icons.restaurant),
  (5,  'Fine Dining',      Icons.star),
  (6,  'Café / Cafetería', Icons.local_cafe),
  (7,  'Panadería',        Icons.bakery_dining),
  (8,  'Bar / Gastrobar',  Icons.wine_bar),
  (9,  'Sushi / Japonés',  Icons.set_meal),
  (10, 'Mariscos',         Icons.water),
  (11, 'Italiano',         Icons.restaurant_menu),
  (12, 'Mexicano',         Icons.local_fire_department),
  (13, 'Chino / Asiático', Icons.rice_bowl),
  (14, 'Árabe / Med.',     Icons.energy_savings_leaf),
  (15, 'Peruano',          Icons.lunch_dining),
  (16, 'Vegano / Veg.',    Icons.eco),
  (17, 'Asadero / BBQ',    Icons.outdoor_grill),
  (18, 'Colombiano',       Icons.favorite),
  (19, 'Comida de Mar',    Icons.anchor),
  (20, 'Fusión',           Icons.public),
  (21, 'Saludable',        Icons.apple),
  (22, 'Wok / Noodles',    Icons.rice_bowl),
  (23, 'Crepería',         Icons.cookie),
  (24, 'Juice Bar',        Icons.water_drop),
  (25, 'Food Truck',       Icons.local_shipping),
];

// ── Helpers para slug ──────────────────────────────────────────────────────────
String _slugify(String text) {
  var s = text.toLowerCase();
  // transliterate comunes
  const accents = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
    'ü': 'u', 'ñ': 'n', 'ä': 'a', 'ö': 'o',
  };
  for (final e in accents.entries) {
    s = s.replaceAll(e.key, e.value);
  }
  s = s.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
  s = s.trim();
  s = s.replaceAll(RegExp(r'\s+'), '-');
  s = s.replaceAll(RegExp(r'-+'), '-');
  if (s.length > 60) s = s.substring(0, 60);
  return s;
}

String? _slugError(String slug) {
  if (slug.isEmpty)                           return 'Requerido';
  if (slug.length < 3)                        return 'Mínimo 3 caracteres';
  if (slug.length > 60)                       return 'Máximo 60 caracteres';
  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(slug)) return 'Solo letras minúsculas, números y guiones';
  if (slug.startsWith('-') || slug.endsWith('-')) return 'No puede empezar ni terminar con guión';
  if (slug.contains('--'))                    return 'Sin guiones consecutivos';
  return null;
}

// ── Datos del formulario (mutable, pasado por referencia a cada step) ─────────
class _InfoData {
  int?    restaurantCategoryId;
  String  name;
  String  slug;
  String  slogan;
  String? bannerUrl;
  String? logoUrl;
  String? phone;
  String? whatsapp;
  String? paisIso2;
  String? paisNombre;
  String? div1Iso2;
  String? div1Nombre;
  String? div2Nombre;
  String? address;
  String? schedule;
  String? instagram;
  String? facebook;
  String? tiktok;
  String? website;
  dynamic skinId;
  dynamic paletteId;

  _InfoData({
    this.restaurantCategoryId,
    this.name       = '',
    this.slug       = '',
    this.slogan     = '',
    this.bannerUrl,
    this.logoUrl,
    this.phone,
    this.whatsapp,
    this.paisIso2,
    this.paisNombre,
    this.div1Iso2,
    this.div1Nombre,
    this.div2Nombre,
    this.address,
    this.schedule,
    this.instagram,
    this.facebook,
    this.tiktok,
    this.website,
    this.skinId,
    this.paletteId,
  });
}

// ── Constantes de pasos ────────────────────────────────────────────────────────
const _kSteps = [
  (id: 'category', label: 'Categoría', desc: '¿Qué tipo de restaurante o negocio es?'),
  (id: 'identity', label: 'Identidad', desc: 'Nombre y apariencia de tu negocio'),
  (id: 'contact',  label: 'Contacto',  desc: 'Cómo te encuentran tus clientes'),
  (id: 'social',   label: 'Redes',     desc: 'Tus redes sociales (opcionales)'),
  (id: 'design',   label: 'Diseño',    desc: 'El look de tu menú digital'),
];

class MenuInfoPage extends StatefulWidget {
  const MenuInfoPage({super.key, required this.menuId});
  final int menuId;

  @override
  State<MenuInfoPage> createState() => _MenuInfoPageState();
}

class _MenuInfoPageState extends State<MenuInfoPage> {
  bool _loading  = true;
  bool _saving   = false;
  int  _step     = 0;
  bool _slugManualEdit = false;

  _InfoData _data = _InfoData();

  // Imágenes locales
  File? _localBanner;
  File? _localLogo;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final j    = await MenuEditorService.getById(widget.menuId);
      final menu = EditorMenu.fromJson(j);
      final info = menu.draft.info;
      final des  = menu.draft.design;
      if (!mounted) return;
      setState(() {
        _data = _InfoData(
          restaurantCategoryId: menu.restaurantCategoryId,
          name:       info.name,
          slug:       menu.slug,
          slogan:     info.slogan,
          bannerUrl:  info.bannerUrl,
          logoUrl:    info.logoUrl,
          phone:      info.phone,
          whatsapp:   info.whatsapp,
          paisIso2:   info.paisIso2,
          paisNombre: info.paisNombre,
          div1Iso2:   info.div1Iso2,
          div1Nombre: info.div1Nombre,
          div2Nombre: info.div2Nombre,
          address:    info.address,
          schedule:   info.schedule,
          instagram:  info.instagram,
          facebook:   info.facebook,
          tiktok:     info.tiktok,
          website:    info.website,
          skinId:     des.skinId,
          paletteId:  des.paletteId,
        );
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _patch(void Function(_InfoData) mutate) => setState(() => mutate(_data));

  void _onNameChange(String name) {
    setState(() {
      _data.name = name;
      if (!_slugManualEdit) _data.slug = _slugify(name);
    });
  }

  void _onSlugChange(String value) {
    _slugManualEdit = true;
    setState(() => _data.slug = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), ''));
  }

  bool get _canAdvance {
    if (_step == 0) return _data.restaurantCategoryId != null;
    if (_step == 1) return _data.name.trim().isNotEmpty && _slugError(_data.slug) == null;
    return true;
  }

  Future<void> _handleSave() async {
    if (_data.name.trim().isEmpty) return;
    setState(() => _saving = true);

    try {
      String? bannerUrl = _data.bannerUrl;
      String? logoUrl   = _data.logoUrl;

      if (_localBanner != null) {
        final url = await MenuEditorService.uploadImage(widget.menuId, _localBanner!, 'banner');
        if (url != null) bannerUrl = url;
      }
      if (_localLogo != null) {
        final url = await MenuEditorService.uploadImage(widget.menuId, _localLogo!, 'logo');
        if (url != null) logoUrl = url;
      }

      await MenuEditorService.updateDraft(widget.menuId, {
        'restaurantCategoryId': _data.restaurantCategoryId,
        'info': {
          'name':       _data.name,
          'slogan':     _data.slogan,
          'bannerUrl':  bannerUrl  ?? '',
          'logoUrl':    logoUrl    ?? '',
          'phone':      _data.phone      ?? '',
          'whatsapp':   _data.whatsapp   ?? '',
          'paisIso2':   _data.paisIso2   ?? '',
          'paisNombre': _data.paisNombre ?? '',
          'div1Iso2':   _data.div1Iso2   ?? '',
          'div1Nombre': _data.div1Nombre ?? '',
          'div2Nombre': _data.div2Nombre ?? '',
          'address':    _data.address    ?? '',
          'schedule':   _data.schedule   ?? '',
          'instagram':  _data.instagram  ?? '',
          'facebook':   _data.facebook   ?? '',
          'tiktok':     _data.tiktok     ?? '',
          'website':    _data.website    ?? '',
        },
        'design': {
          'skinId':    _data.skinId,
          'paletteId': _data.paletteId,
        },
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cambios guardados'),
        backgroundColor: Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se pudo guardar: ${e.toString().replaceFirst('Exception: ', '')}'),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ));
      setState(() => _saving = false);
    }
  }

  void _goBack() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step--);
    }
  }

  void _goNext() {
    if (!_canAdvance) return;
    if (_step < _kSteps.length - 1) {
      setState(() => _step++);
    } else {
      _handleSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: _goBack),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Editar información',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Text(
              _kSteps[_step].desc,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Progress indicator ─────────────────────────────────────────────
          _ProgressBar(step: _step, total: _kSteps.length, steps: _kSteps,
              onTap: (i) { if (i < _step) setState(() => _step = i); }),
          // ── Contenido del paso ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: _buildStep(),
            ),
          ),
          // ── Barra inferior ─────────────────────────────────────────────────
          _BottomNav(
            step:       _step,
            total:      _kSteps.length,
            canAdvance: _canAdvance,
            saving:     _saving,
            onBack:     _goBack,
            onNext:     _goNext,
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _StepCategory(data: _data, patch: _patch);
      case 1:
        return _StepIdentity(
          data:           _data,
          patch:          _patch,
          onNameChange:   _onNameChange,
          onSlugChange:   _onSlugChange,
          excludeId:      widget.menuId,
          localBanner:    _localBanner,
          localLogo:      _localLogo,
          onPickBanner:   _pickBanner,
          onPickLogo:     _pickLogo,
          onClearBanner:  () => setState(() { _localBanner = null; _data.bannerUrl = ''; }),
          onClearLogo:    () => setState(() { _localLogo   = null; _data.logoUrl   = ''; }),
        );
      case 2:
        return _StepContact(data: _data, patch: _patch);
      case 3:
        return _StepSocial(data: _data, patch: _patch);
      case 4:
        return _StepDesign(data: _data, patch: _patch);
      default:
        return const SizedBox();
    }
  }

  Future<void> _pickBanner() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() { _localBanner = File(picked.path); _data.bannerUrl = picked.path; });
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null || !mounted) return;
    final cropped = await showLogoCropDialog(context, File(picked.path));
    if (cropped == null || !mounted) return;
    setState(() { _localLogo = cropped; _data.logoUrl = cropped.path; });
  }
}

// ── Progress bar ──────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.step,
    required this.total,
    required this.steps,
    required this.onTap,
  });

  final int step;
  final int total;
  final List<({String id, String label, String desc})> steps;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(total, (i) {
          final done     = i < step;
          final current  = i == step;
          final color    = done    ? const Color(0xFF16A34A)
                         : current ? AppColors.kBlue
                                   : const Color(0xFFCBD5E1);
          return Flexible(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done    ? const Color(0xFF16A34A)
                               : current ? const Color(0xFFEEF2FF)
                                         : Colors.white,
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Center(
                          child: done
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : Text('${i + 1}',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        steps[i].label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: current ? AppColors.kBlue
                               : done    ? const Color(0xFF16A34A)
                                         : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < total - 1)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 14),
                      color: done ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Bottom nav ─────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.step,
    required this.total,
    required this.canAdvance,
    required this.saving,
    required this.onBack,
    required this.onNext,
  });

  final int      step;
  final int      total;
  final bool     canAdvance;
  final bool     saving;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = step == total - 1;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (step > 0) ...[
                  const Icon(Icons.chevron_left, size: 16),
                  const SizedBox(width: 4),
                ],
                Text(step == 0 ? 'Cancelar' : 'Atrás'),
              ],
            ),
          ),
          const Spacer(),
          Text('Paso ${step + 1} de $total',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const Spacer(),
          FilledButton(
            onPressed: (canAdvance && !saving) ? onNext : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.kBlue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isLast ? 'Guardar' : 'Siguiente'),
                      const SizedBox(width: 4),
                      Icon(isLast ? Icons.check : Icons.chevron_right, size: 16),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Paso 0: Categoría de restaurante ─────────────────────────────────────────
class _StepCategory extends StatelessWidget {
  const _StepCategory({required this.data, required this.patch});
  final _InfoData data;
  final void Function(void Function(_InfoData)) patch;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Tipo de negocio',
      subtitle: 'Elige la categoría que mejor describa tu restaurante.',
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.9,
        children: kRestaurantCategories.map(((int id, String name, IconData icon) cat) {
          final selected = data.restaurantCategoryId == cat.$1;
          return GestureDetector(
            onTap: () => patch((d) => d.restaurantCategoryId = cat.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFEEF2FF) : Colors.white,
                border: Border.all(
                  color: selected ? AppColors.kBlue : const Color(0xFFE2E8F0),
                  width: selected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat.$3, size: 22,
                      color: selected ? AppColors.kBlue : const Color(0xFF94A3B8)),
                  const SizedBox(height: 4),
                  Text(cat.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: selected ? AppColors.kBlue : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Paso 1: Identidad ─────────────────────────────────────────────────────────
class _StepIdentity extends StatefulWidget {
  const _StepIdentity({
    required this.data,
    required this.patch,
    required this.onNameChange,
    required this.onSlugChange,
    required this.excludeId,
    required this.localBanner,
    required this.localLogo,
    required this.onPickBanner,
    required this.onPickLogo,
    required this.onClearBanner,
    required this.onClearLogo,
  });

  final _InfoData data;
  final void Function(void Function(_InfoData)) patch;
  final ValueChanged<String> onNameChange;
  final ValueChanged<String> onSlugChange;
  final int excludeId;
  final File? localBanner;
  final File? localLogo;
  final VoidCallback onPickBanner;
  final VoidCallback onPickLogo;
  final VoidCallback onClearBanner;
  final VoidCallback onClearLogo;

  @override
  State<_StepIdentity> createState() => _StepIdentityState();
}

class _StepIdentityState extends State<_StepIdentity> {
  bool?  _slugAvailable;
  bool   _checking = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scheduleSlugCheck(widget.data.slug);
  }

  @override
  void didUpdateWidget(_StepIdentity old) {
    super.didUpdateWidget(old);
    if (old.data.slug != widget.data.slug) {
      _scheduleSlugCheck(widget.data.slug);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleSlugCheck(String slug) {
    _debounce?.cancel();
    final err = _slugError(slug);
    if (err != null || slug.isEmpty) {
      setState(() { _slugAvailable = null; _checking = false; });
      return;
    }
    setState(() => _checking = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final ok = await MenuEditorService.checkSlug(slug, widget.excludeId);
        if (!mounted) return;
        setState(() { _slugAvailable = ok; _checking = false; });
      } catch (_) {
        if (!mounted) return;
        setState(() { _slugAvailable = null; _checking = false; });
      }
    });
  }

  String get _slugHint {
    final err = _slugError(widget.data.slug);
    if (err != null)          return err;
    if (_checking)            return 'Verificando disponibilidad…';
    if (_slugAvailable == false) return 'Este dominio ya está en uso. Elige otro.';
    if (_slugAvailable == true)  return 'zammpy.com/menu/${widget.data.slug}';
    return 'zammpy.com/menu/${widget.data.slug}';
  }

  Color get _slugColor {
    if (_slugError(widget.data.slug) != null) return const Color(0xFFDC2626);
    if (_slugAvailable == false)              return const Color(0xFFDC2626);
    if (_slugAvailable == true)               return const Color(0xFF16A34A);
    return const Color(0xFF94A3B8);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return Column(
      children: [
        // Nombre y slogan
        _SectionCard(
          title: 'Nombre y slogan',
          child: Column(
            children: [
              _Field(
                label: 'Nombre del negocio *',
                child: TextField(
                  controller: TextEditingController(text: d.name)
                    ..selection = TextSelection.collapsed(offset: d.name.length),
                  onChanged: widget.onNameChange,
                  maxLength: 35,
                  autofocus: true,
                  decoration: _deco(hint: 'Ej: Pizzería La Napolitana'),
                ),
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Slogan',
                child: TextField(
                  controller: TextEditingController(text: d.slogan)
                    ..selection = TextSelection.collapsed(offset: d.slogan.length),
                  onChanged: (v) => widget.patch((x) => x.slogan = v),
                  maxLength: 70,
                  decoration: _deco(hint: 'Ej: La pizza más auténtica de la ciudad'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Slug
        _SectionCard(
          title: 'URL de tu menú',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dirección web *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      color: const Color(0xFFF8FAFC),
                      child: const Text('zammpy.com/menu/',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ),
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: d.slug)
                          ..selection = TextSelection.collapsed(offset: d.slug.length),
                        onChanged: widget.onSlugChange,
                        maxLength: 60,
                        style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight:    Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                            borderSide: BorderSide(color: _slugColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight:    Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                            borderSide: BorderSide(color: _slugColor.withValues(alpha: 0.5)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          isDense: true,
                          counterText: '',
                          hintText: 'mi-pizzeria',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (_checking)
                    const SizedBox(width: 10, height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5)),
                  if (_checking) const SizedBox(width: 4),
                  Flexible(
                    child: Text(_slugHint,
                        style: TextStyle(fontSize: 11, color: _slugColor)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Imágenes
        _SectionCard(
          title: 'Imágenes',
          subtitle: 'Opcional — puedes agregarlas después.',
          child: Column(
            children: [
              _ImageUploadRow(
                label: 'Banner principal',
                hint: '1200×400px recomendado',
                localFile:  widget.localBanner,
                remoteUrl:  widget.localBanner == null ? d.bannerUrl : null,
                onPick:     widget.onPickBanner,
                onClear:    widget.onClearBanner,
                aspectRatio: 3,
              ),
              const SizedBox(height: 14),
              _ImageUploadRow(
                label: 'Logo del negocio',
                hint: 'Se recortará en 1:1. PNG o JPG.',
                localFile:  widget.localLogo,
                remoteUrl:  widget.localLogo == null ? d.logoUrl : null,
                onPick:     widget.onPickLogo,
                onClear:    widget.onClearLogo,
                isLogo:     true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _deco({String? hint}) => InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        counterText: '',
      );
}

// ── Paso 2: Contacto ──────────────────────────────────────────────────────────
class _StepContact extends StatelessWidget {
  const _StepContact({required this.data, required this.patch});
  final _InfoData data;
  final void Function(void Function(_InfoData)) patch;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(
          title: 'Teléfono y WhatsApp',
          child: Row(
            children: [
              Expanded(child: _PhoneField(
                label: 'Teléfono',
                value: data.phone ?? '',
                icon: Icons.phone_outlined,
                onChanged: (v) => patch((d) => d.phone = v),
              )),
              const SizedBox(width: 10),
              Expanded(child: _PhoneField(
                label: 'WhatsApp',
                value: data.whatsapp ?? '',
                icon: Icons.chat_bubble_outline,
                onChanged: (v) => patch((d) => d.whatsapp = v),
              )),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Ubicación *',
          subtitle: 'Selecciona país, departamento, municipio y dirección exacta.',
          child: LocationCascadeWidget(
            value: LocationValue(
              paisIso2:   data.paisIso2,
              paisNombre: data.paisNombre,
              div1Iso2:   data.div1Iso2,
              div1Nombre: data.div1Nombre,
              div2Nombre: data.div2Nombre,
              address:    data.address,
            ),
            onChange: (loc) => patch((d) {
              d.paisIso2   = loc.paisIso2;
              d.paisNombre = loc.paisNombre;
              d.div1Iso2   = loc.div1Iso2;
              d.div1Nombre = loc.div1Nombre;
              d.div2Nombre = loc.div2Nombre;
              d.address    = loc.address;
            }),
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Horario de atención',
          child: ScheduleWidget(
            value:    data.schedule,
            onChange: (v) => patch((d) => d.schedule = v),
          ),
        ),
      ],
    );
  }
}

// ── Paso 3: Redes sociales ────────────────────────────────────────────────────
class _StepSocial extends StatelessWidget {
  const _StepSocial({required this.data, required this.patch});
  final _InfoData data;
  final void Function(void Function(_InfoData)) patch;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Redes sociales y sitio web',
      subtitle: 'Todo opcional. Se muestran en el footer del menú.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _UrlField(
                label: 'Instagram',
                value: data.instagram ?? '',
                icon: Icons.camera_alt_outlined,
                hint: 'https://instagram.com/...',
                onChanged: (v) => patch((d) => d.instagram = v),
              )),
              const SizedBox(width: 10),
              Expanded(child: _UrlField(
                label: 'Facebook',
                value: data.facebook ?? '',
                icon: Icons.facebook_outlined,
                hint: 'https://facebook.com/...',
                onChanged: (v) => patch((d) => d.facebook = v),
              )),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _UrlField(
                label: 'TikTok',
                value: data.tiktok ?? '',
                icon: Icons.music_note_outlined,
                hint: 'https://tiktok.com/@...',
                onChanged: (v) => patch((d) => d.tiktok = v),
              )),
              const SizedBox(width: 10),
              Expanded(child: _UrlField(
                label: 'Sitio web',
                value: data.website ?? '',
                icon: Icons.language_outlined,
                hint: 'https://tu-negocio.com',
                onChanged: (v) => patch((d) => d.website = v),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Paso 4: Diseño ────────────────────────────────────────────────────────────
class _StepDesign extends StatefulWidget {
  const _StepDesign({required this.data, required this.patch});
  final _InfoData data;
  final void Function(void Function(_InfoData)) patch;

  @override
  State<_StepDesign> createState() => _StepDesignState();
}

class _StepDesignState extends State<_StepDesign> {
  List<CatalogSkin> _catalog = [];
  bool _loadingCatalog = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await ThemesCatalogService.load();
    if (!mounted) return;
    setState(() { _catalog = c; _loadingCatalog = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCatalog) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ));
    }

    if (_catalog.isEmpty) {
      return const _SectionCard(
        title: 'Estilo del menú',
        child: Text('No se pudieron cargar los estilos.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
      );
    }

    return _SectionCard(
      title: 'Estilo del menú',
      child: Column(
        children: _catalog.map((skin) {
          final isSelected = widget.data.skinId?.toString() == skin.id.toString()
              || (widget.data.skinId == null && skin.id == _catalog.first.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => widget.patch((d) {
                    d.skinId    = skin.id;
                    d.paletteId = skin.palettes.isNotEmpty ? skin.palettes.first.id : null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppColors.kBlue : const Color(0xFFE2E8F0),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(skin.label,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                        ),
                        Icon(
                          isSelected ? Icons.check_circle : Icons.expand_more,
                          size: 18,
                          color: isSelected ? AppColors.kBlue : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),

                // Paletas (solo si está seleccionada)
                if (isSelected && skin.palettes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                    child: GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.7,
                      children: skin.palettes.map((palette) {
                        final isPalActive = widget.data.paletteId?.toString() == palette.id.toString()
                            || (widget.data.paletteId == null && palette.id == skin.palettes.first.id);
                        return GestureDetector(
                          onTap: () => widget.patch((d) => d.paletteId = palette.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: isPalActive ? AppColors.kBlue : const Color(0xFFE2E8F0),
                                width: isPalActive ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _InfoColorBar(hexColors: palette.preview.take(4).toList()),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(child: Text(palette.name,
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                                        overflow: TextOverflow.ellipsis)),
                                    if (isPalActive) ...[
                                      const SizedBox(width: 3),
                                      const Icon(Icons.check, size: 9, color: AppColors.kBlue),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Widget section card ────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.subtitle});
  final String  title;
  final String? subtitle;
  final Widget  child;

  @override
  Widget build(BuildContext context) => Container(
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
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(subtitle!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}

// ── Campos auxiliares ──────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 6),
          ],
          child,
        ],
      );
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.label, required this.value, required this.icon, required this.onChanged});
  final String label;
  final String value;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => _Field(
        label: label,
        child: TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value.length),
          onChanged: (v) => onChanged(v.replaceAll(RegExp(r'[^\d+]'), '')),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
            LengthLimitingTextInputFormatter(15),
          ],
          decoration: InputDecoration(
            hintText: '+57 300 000 0000',
            prefixIcon: Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
}

class _UrlField extends StatelessWidget {
  const _UrlField({required this.label, required this.value, required this.icon, required this.hint, required this.onChanged});
  final String   label;
  final String   value;
  final IconData icon;
  final String   hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => _Field(
        label: label,
        child: TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value.length),
          onChanged: onChanged,
          keyboardType: TextInputType.url,
          inputFormatters: [LengthLimitingTextInputFormatter(150)],
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
}

// ── Imagen con picker (banner / logo) ─────────────────────────────────────────
class _ImageUploadRow extends StatelessWidget {
  const _ImageUploadRow({
    required this.label,
    required this.hint,
    required this.localFile,
    required this.remoteUrl,
    required this.onPick,
    required this.onClear,
    this.aspectRatio = 3,
    this.isLogo = false,
  });

  final String       label;
  final String       hint;
  final File?        localFile;
  final String?      remoteUrl;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final double       aspectRatio;
  final bool         isLogo;

  @override
  Widget build(BuildContext context) {
    final hasImage = localFile != null || (remoteUrl?.isNotEmpty ?? false);

    // ── Layout compacto para logo (igual que FileUpload crop="1:1" en React) ──
    if (isLogo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onPick,
                child: Stack(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        border: Border.all(
                          color: hasImage ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: hasImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: localFile != null
                                  ? Image.file(localFile!, fit: BoxFit.cover)
                                  : Image.network(remoteUrl!, fit: BoxFit.cover,
                                      errorBuilder: (ctx, e, s) => const Icon(
                                          Icons.broken_image_outlined,
                                          color: Color(0xFFCBD5E1))),
                            )
                          : const Icon(Icons.upload_outlined,
                              size: 22, color: Color(0xFF94A3B8)),
                    ),
                    if (hasImage)
                      Positioned(
                        top: 2, right: 2,
                        child: GestureDetector(
                          onTap: onClear,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 10, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasImage)
                      OutlinedButton(
                        onPressed: onPick,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cambiar',
                            style: TextStyle(fontSize: 11)),
                      )
                    else
                      const Text('Haz clic en el cuadro para elegir',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    Text(hint, style: const TextStyle(
                        fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    // ── Layout estándar para banner ───────────────────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const Spacer(),
            Text(hint, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          ],
        ),
        const SizedBox(height: 6),
        if (hasImage)
          Stack(
            children: [
              AspectRatio(
                aspectRatio: aspectRatio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: localFile != null
                      ? Image.file(localFile!, fit: BoxFit.cover)
                      : Image.network(remoteUrl!, fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Icons.broken_image_outlined,
                                color: Color(0xFFCBD5E1)),
                          )),
                ),
              ),
              Positioned(
                top: 6, right: 6,
                child: GestureDetector(
                  onTap: onClear,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: onPick,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 24,
                        color: Color(0xFFCBD5E1)),
                    SizedBox(height: 4),
                    Text('Seleccionar',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.photo_library_outlined, size: 12),
          label: Text(hasImage ? 'Cambiar' : 'Elegir de galería',
              style: const TextStyle(fontSize: 11)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

// Barra de colores para _StepDesign — idéntica a _ColorBar en design_tab.dart
class _InfoColorBar extends StatelessWidget {
  const _InfoColorBar({required this.hexColors});
  final List<String> hexColors;

  Color _parse(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
      if (h.length == 8) return Color(int.parse(h, radix: 16));
    } catch (_) {}
    return const Color(0xFFE2E8F0);
  }

  @override
  Widget build(BuildContext context) {
    if (hexColors.isEmpty) return const SizedBox(height: 14);
    final dartColors = hexColors.map(_parse).toList();
    final n = dartColors.length;
    final stops  = <double>[for (int i = 0; i < n; i++) ...[i / n, (i + 1) / n]];
    final colors = <Color>[for (final c in dartColors) ...[c, c]];
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 24,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, stops: stops),
        ),
      ),
    );
  }
}
