import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../services/geography_service.dart';
import '../../../../services/image_upload_service.dart';
import '../../../../services/live_editor_service.dart';
import '../../../../shared/app_colors.dart';
import '../live/editor_models.dart';

// Equivalente a src/modules/menu/editor/MenuInfoPage.jsx en React: toda la información del menú en una sola
// pantalla (identidad y enlace, contacto, ubicación, redes, galería y horario). Lo más común también se edita en el
// propio menú (FormInformacion); el horario y el enlace solo aquí.
class InfoMenuForm extends StatefulWidget {
  const InfoMenuForm({super.key, required this.menu, required this.onChanged, this.enfocarHorario = false});

  final LiveMenu menu;
  final Future<void> Function() onChanged;

  /// Abre la pantalla en el horario (como ?paso=4 en React, desde "Completa tu menú" o el menú de edición).
  final bool enfocarHorario;

  @override
  State<InfoMenuForm> createState() => _InfoMenuFormState();
}

class _InfoMenuFormState extends State<InfoMenuForm> {
  final _horarioKey = GlobalKey();
  late final TextEditingController _name;
  late final TextEditingController _slogan;
  late final TextEditingController _slug;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _email;
  late final TextEditingController _instagram;
  late final TextEditingController _facebook;
  late final TextEditingController _tiktok;
  late final TextEditingController _website;
  late final TextEditingController _address;

  String? _municipioCodigo;
  bool _pedidos = false;
  late List<String> _galeria;
  late Map<String, dynamic> _horario;

  final _picker = ImagePicker();
  bool _busy = false;
  bool _checkingSlug = false;
  bool? _slugAvailable;
  Timer? _slugDebounce;

  List<GeoPais> _paises = const [];
  List<GeoDivision> _divisiones = const [];
  List<GeoMunicipio> _municipios = const [];
  String? _pais;
  String? _division;
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.enfocarHorario) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _horarioKey.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
      });
    }
    final i = widget.menu.info;
    _name = TextEditingController(text: i.name);
    _slogan = TextEditingController(text: i.slogan);
    _slug = TextEditingController(text: widget.menu.slug);
    _phone = TextEditingController(text: i.phone ?? '');
    _whatsapp = TextEditingController(text: i.whatsapp ?? '');
    _email = TextEditingController(text: i.email ?? '');
    _instagram = TextEditingController(text: i.instagram ?? '');
    _facebook = TextEditingController(text: i.facebook ?? '');
    _tiktok = TextEditingController(text: i.tiktok ?? '');
    _website = TextEditingController(text: i.website ?? '');
    _address = TextEditingController(text: i.address ?? '');
    _municipioCodigo = i.municipioCodigo;
    _pedidos = i.pedidosActivos;
    _galeria = [...i.galeria];
    _horario = _copySchedule(widget.menu.horario);
    _loadPaises();
  }

  @override
  void dispose() {
    _slugDebounce?.cancel();
    for (final c in [
      _name,
      _slogan,
      _slug,
      _phone,
      _whatsapp,
      _email,
      _instagram,
      _facebook,
      _tiktok,
      _website,
      _address,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _copySchedule(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) {
      return {
        for (final d in ['lun', 'mar', 'mie', 'jue', 'vie', 'sab', 'dom'])
          d: {'abierto': false, 'veinticuatro': false, 'rangos': []},
      };
    }
    return {
      for (final d in ['lun', 'mar', 'mie', 'jue', 'vie', 'sab', 'dom'])
        d: raw[d] is Map
            ? {
                'abierto': raw[d]['abierto'] == true,
                'veinticuatro': raw[d]['veinticuatro'] == true,
                'rangos': [
                  for (final r in (raw[d]['rangos'] as List? ?? []))
                    if (r is Map) {'desde': r['desde'], 'hasta': r['hasta']},
                ],
              }
            : {'abierto': false, 'veinticuatro': false, 'rangos': []},
    };
  }

  Future<void> _loadPaises() async {
    try {
      final list = await GeographyService.getPaisesCatalogo();
      if (mounted) setState(() => _paises = list);
    } catch (_) {}
  }

  Future<void> _pickCountry(String? code) async {
    if (code == null) return;
    setState(() {
      _pais = code;
      _division = null;
      _divisiones = const [];
      _municipios = const [];
      _municipioCodigo = null;
    });
    try {
      final list = await GeographyService.getDivisiones(code);
      if (mounted) setState(() => _divisiones = list);
    } catch (_) {}
  }

  Future<void> _pickDivision(String? code) async {
    if (code == null) return;
    setState(() {
      _division = code;
      _municipios = const [];
      _municipioCodigo = null;
    });
    setState(() => _loadingLocation = true);
    try {
      final list = await GeographyService.buscarMunicipios(code, limite: 200);
      if (mounted) setState(() => _municipios = list);
    } catch (_) {}
    if (mounted) setState(() => _loadingLocation = false);
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.kRed : AppColors.kGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _save(String section, Map<String, dynamic> body) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await LiveEditorService.saveSection(widget.menu.codigo, section, body);
      await widget.onChanged();
      if (mounted) _snack('Guardado.');
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _checkSlug(String value) {
    _slugDebounce?.cancel();
    if (value.isEmpty || value.length < 3) {
      setState(() => _slugAvailable = null);
      return;
    }
    setState(() => _checkingSlug = true);
    _slugDebounce = Timer(const Duration(milliseconds: 500), () async {
      final ok = await LiveEditorService.checkSlug(
        value,
        excludeCodigo: widget.menu.codigo,
      );
      if (!mounted || _slug.text != value) return;
      setState(() {
        _slugAvailable = ok;
        _checkingSlug = false;
      });
    });
  }

  Future<void> _upload(String tipo, File file) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final url = await LiveEditorService.upload(
        widget.menu.codigo,
        tipo,
        file,
      );
      final section = tipo == 'logo' ? 'logo' : 'portada';
      final body = tipo == 'logo' ? {'logoUrl': url} : {'bannerUrl': url};
      await LiveEditorService.saveSection(widget.menu.codigo, section, body);
      await widget.onChanged();
      if (mounted) _snack('Imagen actualizada.');
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickImage(String tipo) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: tipo == 'logo' ? 90 : 85,
    );
    if (picked == null || !mounted) return;
    final file = File(picked.path);
    final error = ImageUploadService.validate(file);
    if (error != null) return _snack(error, error: true);
    await _upload(tipo, file);
  }

  Future<void> _addGallery() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      final urls = <String>[];
      for (final x in picked.take(6)) {
        final file = File(x.path);
        if (ImageUploadService.validate(file) != null) continue;
        urls.add(
          await LiveEditorService.upload(widget.menu.codigo, 'galeria', file),
        );
      }
      if (urls.isEmpty) throw Exception('No se pudo subir ninguna imagen.');
      _galeria = [..._galeria, ...urls];
      await LiveEditorService.saveSection(widget.menu.codigo, 'galeria', {
        'galeria': _galeria,
      });
      await widget.onChanged();
      if (mounted) _snack('Galería actualizada.');
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeGallery(String url) async {
    final next = _galeria.where((e) => e != url).toList();
    setState(() => _galeria = next);
    try {
      await LiveEditorService.saveSection(widget.menu.codigo, 'galeria', {
        'galeria': next,
      });
      await widget.onChanged();
    } catch (e) {
      if (mounted) {
        setState(() => _galeria = [..._galeria, url]);
        _snack('No se pudo quitar la imagen.', error: true);
      }
    }
  }

  Future<void> _saveSchedule() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await LiveEditorService.saveHorario(widget.menu.codigo, _horario);
      await widget.onChanged();
      if (mounted) _snack('Horario guardado.');
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        _Card(
          title: 'Identidad',
          child: Column(
            children: [
              _Input(label: 'Nombre', controller: _name, max: 50),
              _Input(label: 'Slogan', controller: _slogan, max: 100),
              _Input(
                label: 'Link',
                controller: _slug,
                max: 100,
                prefix: 'zammpy.com/menu/',
                onChanged: (v) {
                  final clean = v.toLowerCase().replaceAll(
                    RegExp(r'[^a-z0-9-]'),
                    '',
                  );
                  if (clean != v) {
                    _slug.value = TextEditingValue(
                      text: clean,
                      selection: TextSelection.collapsed(offset: clean.length),
                    );
                  }
                  _checkSlug(clean);
                },
              ),
              if (_checkingSlug)
                const Text(
                  'Verificando slug…',
                  style: TextStyle(fontSize: 11, color: AppColors.kTextMuted),
                ),
              if (_slugAvailable == false)
                const Text(
                  'Ese link ya está publicado por otro negocio.',
                  style: TextStyle(fontSize: 11, color: AppColors.kRed),
                ),
              if (_slugAvailable == true)
                const Text(
                  'Link disponible.',
                  style: TextStyle(fontSize: 11, color: AppColors.kGreen),
                ),
              _SaveButton(
                busy: _busy,
                onTap: () => _save('identidad', {
                  'name': _name.text.trim(),
                  'slogan': _slogan.text.trim(),
                  'slug': _slug.text.trim(),
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'Logo y portada',
          child: Column(
            children: [
              _ImageSlot(
                label: 'Logo',
                url: widget.menu.info.logoUrl,
                isLogo: true,
                busy: _busy,
                onTap: () => _pickImage('logo'),
              ),
              const Divider(height: 20),
              _ImageSlot(
                label: 'Portada',
                url: widget.menu.info.bannerUrl,
                isLogo: false,
                busy: _busy,
                onTap: () => _pickImage('banner'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'Contacto',
          child: Column(
            children: [
              _Input(label: 'Teléfono', controller: _phone, max: 30),
              _Input(label: 'WhatsApp', controller: _whatsapp, max: 30),
              _Input(label: 'Correo', controller: _email, max: 320),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Pedidos activos',
                  style: TextStyle(fontSize: 13),
                ),
                value: _pedidos,
                onChanged: (v) => setState(() => _pedidos = v),
              ),
              _SaveButton(
                busy: _busy,
                onTap: () => _save('contacto', {
                  'phone': _phone.text.trim(),
                  'whatsapp': _whatsapp.text.trim(),
                  'email': _email.text.trim(),
                  'pedidosActivos': _pedidos,
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'Ubicación',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.menu.info.municipioCodigo != null)
                Text(
                  'Municipio actual: ${widget.menu.info.municipioCodigo}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.kTextMuted,
                  ),
                ),
              DropdownButtonFormField<String>(
                initialValue: _pais,
                decoration: const InputDecoration(labelText: 'País'),
                items: _paises
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.codigo,
                        child: Text(p.nombre),
                      ),
                    )
                    .toList(),
                onChanged: _pickCountry,
              ),
              DropdownButtonFormField<String>(
                initialValue: _division,
                decoration: const InputDecoration(
                  labelText: 'Departamento / Estado',
                ),
                items: _divisiones
                    .map(
                      (d) => DropdownMenuItem(
                        value: d.codigo,
                        child: Text(d.nombre),
                      ),
                    )
                    .toList(),
                onChanged: _pickDivision,
              ),
              DropdownButtonFormField<String>(
                initialValue:
                    _municipios.any((m) => m.codigo == _municipioCodigo)
                    ? _municipioCodigo
                    : null,
                decoration: InputDecoration(
                  labelText: _loadingLocation
                      ? 'Cargando municipios…'
                      : 'Municipio',
                ),
                items: _municipios
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.codigo,
                        child: Text(m.nombre),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _municipioCodigo = v),
              ),
              const SizedBox(height: 8),
              _Input(label: 'Dirección', controller: _address, max: 255),
              _SaveButton(
                busy: _busy,
                onTap: () {
                  if (_municipioCodigo == null) {
                    _snack('Selecciona un municipio.', error: true);
                    return;
                  }
                  _save('ubicacion', {
                    'municipioCodigo': _municipioCodigo,
                    'address': _address.text.trim(),
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'Redes sociales',
          child: Column(
            children: [
              _Input(label: 'Instagram', controller: _instagram, max: 100),
              _Input(label: 'Facebook', controller: _facebook, max: 100),
              _Input(label: 'TikTok', controller: _tiktok, max: 100),
              _Input(label: 'Sitio web', controller: _website, max: 255),
              _SaveButton(
                busy: _busy,
                onTap: () => _save('redes', {
                  'instagram': _instagram.text.trim(),
                  'facebook': _facebook.text.trim(),
                  'tiktok': _tiktok.text.trim(),
                  'website': _website.text.trim(),
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          title: 'Galería',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_galeria.isEmpty)
                const Text(
                  'Sin fotos.',
                  style: TextStyle(fontSize: 12, color: AppColors.kTextMuted),
                ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _galeria.length,
                itemBuilder: (_, i) => Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(_galeria[i], fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: GestureDetector(
                        onTap: () => _removeGallery(_galeria[i]),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : _addGallery,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 15),
                label: const Text('Agregar fotos'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          key: _horarioKey,
          title: 'Horario de atención',
          child: Column(
            children: [
              for (final entry in _horario.entries)
                _DaySchedule(
                  day: entry.key,
                  data: Map<String, dynamic>.from(entry.value as Map),
                  onChanged: (next) =>
                      setState(() => _horario[entry.key] = next),
                ),
              _SaveButton(busy: _busy, onTap: _saveSchedule),
            ],
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.title, required this.child});
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _Input extends StatelessWidget {
  const _Input({
    required this.label,
    required this.controller,
    required this.max,
    this.prefix,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final int max;
  final String? prefix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: controller,
      maxLength: max,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        counterText: '',
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
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
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.kBlue,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      child: busy
          ? const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.white,
              ),
            )
          : const Text('Guardar', style: TextStyle(fontSize: 12)),
    ),
  );
}

class _ImageSlot extends StatelessWidget {
  const _ImageSlot({
    required this.label,
    required this.url,
    required this.isLogo,
    required this.busy,
    required this.onTap,
  });
  final String label;
  final String? url;
  final bool isLogo;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      GestureDetector(
        onTap: busy ? null : onTap,
        child: Container(
          width: isLogo ? 64 : 120,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.kCardBorder),
          ),
          clipBehavior: Clip.hardEdge,
          child: url == null || url!.isEmpty
              ? const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.kTextMuted,
                )
              : Image.network(url!, fit: BoxFit.cover),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      const Spacer(),
      TextButton(
        onPressed: busy ? null : onTap,
        child: Text(url == null ? 'Subir' : 'Cambiar'),
      ),
    ],
  );
}

class _DaySchedule extends StatelessWidget {
  const _DaySchedule({
    required this.day,
    required this.data,
    required this.onChanged,
  });
  final String day;
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onChanged;

  static const _labels = {
    'lun': 'Lunes',
    'mar': 'Martes',
    'mie': 'Miércoles',
    'jue': 'Jueves',
    'vie': 'Viernes',
    'sab': 'Sábado',
    'dom': 'Domingo',
  };

  Future<void> _pickTime(BuildContext context, int index, bool from) async {
    final rangos = [
      for (final r in (data['rangos'] as List? ?? []))
        Map<String, dynamic>.from(r as Map),
    ];
    while (rangos.length <= index) {
      rangos.add({'desde': '11:00', 'hasta': '22:00'});
    }
    final current =
        (rangos[index][from ? 'desde' : 'hasta'] as String? ?? '11:00');
    final parts = current.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 11,
        minute: int.tryParse(parts.last) ?? 0,
      ),
    );
    if (picked == null) return;
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    rangos[index][from ? 'desde' : 'hasta'] = '$hh:$mm';
    onChanged({...data, 'rangos': rangos});
  }

  @override
  Widget build(BuildContext context) {
    final abierto = data['abierto'] == true;
    final veinticuatro = data['veinticuatro'] == true;
    final rangos = (data['rangos'] as List? ?? []);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(
        _labels[day] ?? day,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        !abierto
            ? 'Cerrado'
            : veinticuatro
            ? '24 horas'
            : rangos.isEmpty
            ? 'Sin rangos'
            : 'Abierto',
        style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted),
      ),
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Abierto', style: TextStyle(fontSize: 12)),
          value: abierto,
          onChanged: (v) => onChanged({...data, 'abierto': v}),
        ),
        if (abierto)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('24 horas', style: TextStyle(fontSize: 12)),
            value: veinticuatro,
            onChanged: (v) =>
                onChanged({...data, 'veinticuatro': v, if (v) 'rangos': []}),
          ),
        if (abierto && !veinticuatro) ...[
          for (var i = 0; i < rangos.length; i++)
            Row(
              children: [
                TextButton(
                  onPressed: () => _pickTime(context, i, true),
                  child: Text((rangos[i] as Map)['desde'] ?? '11:00'),
                ),
                const Text('—'),
                TextButton(
                  onPressed: () => _pickTime(context, i, false),
                  child: Text((rangos[i] as Map)['hasta'] ?? '22:00'),
                ),
                IconButton(
                  onPressed: () {
                    final next = [
                      for (final r in rangos)
                        Map<String, dynamic>.from(r as Map),
                    ]..removeAt(i);
                    onChanged({...data, 'rangos': next});
                  },
                  icon: const Icon(Icons.delete_outline, size: 16),
                ),
              ],
            ),
          TextButton.icon(
            onPressed: () {
              final next = [
                for (final r in rangos) Map<String, dynamic>.from(r as Map),
                {'desde': '11:00', 'hasta': '22:00'},
              ];
              onChanged({...data, 'rangos': next});
            },
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Agregar rango'),
          ),
        ],
      ],
    );
  }
}
