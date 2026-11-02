import 'dart:async';

import 'package:flutter/material.dart';

import '../services/geography_service.dart';
import 'app_colors.dart';

class LocationCascadeValue {
  final String? paisCodigo;
  final String? divisionCodigo;
  final String? divisionTipo;
  final String? municipioCodigo;
  final String municipio;
  final String address;

  const LocationCascadeValue({
    this.paisCodigo,
    this.divisionCodigo,
    this.divisionTipo,
    this.municipioCodigo,
    this.municipio = '',
    this.address = '',
  });

  bool get hasMunicipio =>
      municipioCodigo != null && municipioCodigo!.isNotEmpty;

  LocationCascadeValue copyWith({
    String? paisCodigo,
    String? divisionCodigo,
    String? divisionTipo,
    String? municipioCodigo,
    String? municipio,
    String? address,
    bool clearDivision = false,
    bool clearMunicipio = false,
  }) {
    return LocationCascadeValue(
      paisCodigo: paisCodigo ?? this.paisCodigo,
      divisionCodigo: clearDivision
          ? null
          : (divisionCodigo ?? this.divisionCodigo),
      divisionTipo: clearDivision ? null : (divisionTipo ?? this.divisionTipo),
      municipioCodigo: (clearDivision || clearMunicipio)
          ? null
          : (municipioCodigo ?? this.municipioCodigo),
      municipio: (clearDivision || clearMunicipio)
          ? ''
          : (municipio ?? this.municipio),
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toUbicacionJson() => {
    if (paisCodigo != null) 'paisCodigo': paisCodigo,
    if (divisionCodigo != null) 'divisionCodigo': divisionCodigo,
    if (divisionTipo != null) 'divisionTipo': divisionTipo,
    if (municipioCodigo != null) 'municipioCodigo': municipioCodigo,
    if (municipio.isNotEmpty) 'municipio': municipio,
    if (address.trim().isNotEmpty) 'address': address.trim(),
  };

  factory LocationCascadeValue.fromUbicacion(
    Map<String, dynamic>? u, {
    String address = '',
  }) {
    if (u == null) return LocationCascadeValue(address: address);
    return LocationCascadeValue(
      paisCodigo: u['paisCodigo']?.toString(),
      divisionCodigo: u['divisionCodigo']?.toString(),
      divisionTipo: u['divisionTipo']?.toString(),
      municipioCodigo: u['municipioCodigo']?.toString(),
      municipio: u['municipio']?.toString() ?? '',
      address: address,
    );
  }
}

class LocationCascadeInput extends StatefulWidget {
  const LocationCascadeInput({
    super.key,
    required this.value,
    required this.onChange,
    this.label,
    this.hint,
    this.mostrarDireccion = true,
  });

  final LocationCascadeValue value;
  final ValueChanged<LocationCascadeValue> onChange;
  final String? label;
  final String? hint;
  final bool mostrarDireccion;

  @override
  State<LocationCascadeInput> createState() => _LocationCascadeInputState();
}

class _LocationCascadeInputState extends State<LocationCascadeInput> {
  List<GeoPais> _paises = [];
  List<GeoDivision> _divisiones = [];
  bool _loadingPaises = true;
  bool _loadingDivisiones = false;

  late final TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _addressCtrl = TextEditingController(text: widget.value.address);
    _loadPaises();
    final pais = widget.value.paisCodigo;
    if (pais != null && pais.isNotEmpty) _loadDivisiones(pais);
  }

  @override
  void didUpdateWidget(covariant LocationCascadeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value.paisCodigo != widget.value.paisCodigo) {
      final pais = widget.value.paisCodigo;
      setState(() => _divisiones = []);
      if (pais != null && pais.isNotEmpty) _loadDivisiones(pais);
    }
    if (oldWidget.value.address != widget.value.address &&
        _addressCtrl.text != widget.value.address) {
      _addressCtrl.text = widget.value.address;
      _addressCtrl.selection = TextSelection.collapsed(
        offset: _addressCtrl.text.length,
      );
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPaises() async {
    try {
      final paises = await GeographyService.getPaisesCatalogo();
      if (!mounted) return;
      setState(() {
        _paises = paises;
        _loadingPaises = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPaises = false);
    }
  }

  Future<void> _loadDivisiones(String pais) async {
    setState(() => _loadingDivisiones = true);
    try {
      final divisiones = await GeographyService.getDivisiones(pais);
      if (!mounted) return;
      setState(() {
        _divisiones = divisiones;
        _loadingDivisiones = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _divisiones = [];
        _loadingDivisiones = false;
      });
    }
  }

  Future<void> _pickMunicipio() async {
    final division = widget.value.divisionCodigo;
    if (division == null || division.isEmpty) return;

    final selected = await showModalBottomSheet<GeoMunicipio>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MunicipioPicker(
        divisionCodigo: division,
        selectedCodigo: widget.value.municipioCodigo,
      ),
    );

    if (selected == null) return;
    widget.onChange(
      widget.value.copyWith(
        municipioCodigo: selected.codigo,
        municipio: selected.nombre,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final divisionLabel = etiquetaDivision(
      value.divisionTipo ??
          (_divisiones.isNotEmpty ? _divisiones.first.tipo : null),
    );
    final hasPais = value.paisCodigo != null && value.paisCodigo!.isNotEmpty;
    final hasDivision =
        value.divisionCodigo != null && value.divisionCodigo!.isNotEmpty;
    final selectedPais =
        hasPais && _paises.any((pais) => pais.codigo == value.paisCodigo)
        ? value.paisCodigo
        : null;
    final selectedDivision =
        hasDivision &&
            _divisiones.any(
              (division) => division.codigo == value.divisionCodigo,
            )
        ? value.divisionCodigo
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.kTextSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<String>(
          key: ValueKey('pais-${selectedPais ?? 'none'}-${_paises.length}'),
          initialValue: selectedPais,
          isExpanded: true,
          decoration: _decoration(
            hint: _loadingPaises ? 'Cargando países…' : 'Seleccionar país…',
          ),
          items: _paises
              .map(
                (p) => DropdownMenuItem(
                  value: p.codigo,
                  child: Text(
                    '${p.nombre}${p.indicativo.isNotEmpty ? ' (${p.indicativo})' : ''}',
                  ),
                ),
              )
              .toList(),
          onChanged: _loadingPaises
              ? null
              : (pais) {
                  if (pais == null) return;
                  widget.onChange(
                    value.copyWith(
                      paisCodigo: pais,
                      clearDivision: true,
                      clearMunicipio: true,
                    ),
                  );
                },
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey(
                  'division-${selectedDivision ?? 'none'}-${_divisiones.length}',
                ),
                initialValue: selectedDivision,
                isExpanded: true,
                decoration: _decoration(
                  hint: !hasPais
                      ? 'Primero elige el país'
                      : _loadingDivisiones
                      ? 'Cargando…'
                      : 'Seleccionar…',
                  label: divisionLabel,
                ),
                items: _divisiones
                    .map(
                      (d) => DropdownMenuItem(
                        value: d.codigo,
                        child: Text(d.nombre, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: !hasPais || _loadingDivisiones
                    ? null
                    : (codigo) {
                        if (codigo == null) return;
                        final division = _divisiones.firstWhere(
                          (d) => d.codigo == codigo,
                          orElse: () => _divisiones.first,
                        );
                        widget.onChange(
                          value.copyWith(
                            divisionCodigo: division.codigo,
                            divisionTipo: division.tipo,
                            clearMunicipio: true,
                          ),
                        );
                      },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: hasDivision ? _pickMunicipio : null,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _decoration(
                    hint: !hasDivision
                        ? 'Primero elige la división'
                        : 'Seleccionar…',
                    label: 'Municipio / Ciudad',
                    enabled: hasDivision,
                  ),
                  // Mismo aspecto que el dropdown de departamento: flecha abajo (sin lupa).
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          value.municipio.isNotEmpty ? value.municipio : '',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            color: value.municipio.isNotEmpty
                                ? AppColors.kTextPrimary
                                : AppColors.kTextMuted,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 24,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (value.municipio.isNotEmpty || hasDivision) ...[
          const SizedBox(height: 4),
          if (!value.hasMunicipio)
            const Text(
              'Elige el municipio de la lista.',
              style: TextStyle(fontSize: 11, color: Color(0xFFD97706)),
            ),
        ],
        if (widget.mostrarDireccion) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _addressCtrl,
            onChanged: (address) =>
                widget.onChange(widget.value.copyWith(address: address)),
            style: const TextStyle(fontSize: 13),
            decoration:
                _decoration(
                  hint: 'Ej: Calle 45 #12-30, Barrio Centro',
                  label: 'Dirección (calle, número, barrio)',
                ).copyWith(
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.kTextMuted,
                  ),
                ),
          ),
        ],
        if (widget.hint != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.hint!,
            style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted),
          ),
        ],
      ],
    );
  }

  InputDecoration _decoration({
    String? hint,
    String? label,
    bool enabled = true,
  }) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: enabled ? const Color(0xFFFAFAFA) : const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.kBlue, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }
}

class _MunicipioPicker extends StatefulWidget {
  const _MunicipioPicker({required this.divisionCodigo, this.selectedCodigo});

  final String divisionCodigo;
  final String? selectedCodigo;

  @override
  State<_MunicipioPicker> createState() => _MunicipioPickerState();
}

class _MunicipioPickerState extends State<_MunicipioPicker> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<GeoMunicipio> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await GeographyService.buscarMunicipios(
        widget.divisionCodigo,
        q: query.trim(),
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _loading = false;
        _error = 'No se pudieron cargar los municipios.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return SizedBox(
      height: mq.size.height * 0.72,
      child: Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Seleccionar municipio',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextPrimary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'Escribe para buscar…',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.kTextSecondary),
                      ),
                    )
                  : _items.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin resultados',
                        style: TextStyle(color: AppColors.kTextMuted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final m = _items[index];
                        final selected = m.codigo == widget.selectedCodigo;
                        return ListTile(
                          dense: true,
                          title: Text(
                            m.nombre,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: selected
                                  ? AppColors.kBlue
                                  : AppColors.kTextPrimary,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: AppColors.kBlue,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, m),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
