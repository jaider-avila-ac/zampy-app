import 'package:flutter/material.dart';
import '../services/geography_service.dart';
import 'app_colors.dart';

// Equivalente a LocationCascadeInput.jsx en React:
// 3 dropdowns en cascada (País → Dpto → Ciudad) + campo dirección.
// Usa los mismos endpoints: /api/v1/public/geografia/...

class LocationValue {
  final String? paisIso2;
  final String? paisNombre;
  final String? div1Iso2;
  final String? div1Nombre;
  final String? div2Nombre;
  final String? address;

  const LocationValue({
    this.paisIso2,
    this.paisNombre,
    this.div1Iso2,
    this.div1Nombre,
    this.div2Nombre,
    this.address,
  });

  LocationValue copyWith({
    String? paisIso2,
    String? paisNombre,
    String? div1Iso2,
    String? div1Nombre,
    String? div2Nombre,
    String? address,
    bool clearDiv1 = false,
    bool clearDiv2 = false,
  }) =>
      LocationValue(
        paisIso2:   paisIso2   ?? this.paisIso2,
        paisNombre: paisNombre ?? this.paisNombre,
        div1Iso2:   clearDiv1 ? null : (div1Iso2   ?? this.div1Iso2),
        div1Nombre: clearDiv1 ? ''   : (div1Nombre ?? this.div1Nombre),
        div2Nombre: (clearDiv1 || clearDiv2) ? '' : (div2Nombre ?? this.div2Nombre),
        address:    address    ?? this.address,
      );
}

class LocationCascadeWidget extends StatefulWidget {
  const LocationCascadeWidget({
    super.key,
    required this.value,
    required this.onChange,
  });

  final LocationValue value;
  final ValueChanged<LocationValue> onChange;

  @override
  State<LocationCascadeWidget> createState() => _LocationCascadeWidgetState();
}

class _LocationCascadeWidgetState extends State<LocationCascadeWidget> {
  List<GeoCountry> _paises   = [];
  List<GeoState>   _estados  = [];
  List<String>     _ciudades = [];

  bool _loadingPaises   = false;
  bool _loadingEstados  = false;
  bool _loadingCiudades = false;

  @override
  void initState() {
    super.initState();
    _loadPaises();
    if (widget.value.paisIso2 != null) _loadEstados(widget.value.paisIso2!);
    if (widget.value.paisIso2 != null && widget.value.div1Iso2 != null) {
      _loadCiudades(widget.value.paisIso2!, widget.value.div1Iso2!);
    }
  }

  @override
  void didUpdateWidget(LocationCascadeWidget old) {
    super.didUpdateWidget(old);
    if (old.value.paisIso2 != widget.value.paisIso2) {
      setState(() { _estados = []; _ciudades = []; });
      if (widget.value.paisIso2 != null) _loadEstados(widget.value.paisIso2!);
    }
    if (old.value.div1Iso2 != widget.value.div1Iso2) {
      setState(() => _ciudades = []);
      if (widget.value.paisIso2 != null && widget.value.div1Iso2 != null) {
        _loadCiudades(widget.value.paisIso2!, widget.value.div1Iso2!);
      }
    }
  }

  Future<void> _loadPaises() async {
    setState(() => _loadingPaises = true);
    try {
      final list = await GeographyService.getPaises();
      if (mounted) setState(() => _paises = list);
    } catch (_) {}
    if (mounted) setState(() => _loadingPaises = false);
  }

  Future<void> _loadEstados(String iso) async {
    setState(() => _loadingEstados = true);
    try {
      final list = await GeographyService.getEstados(iso);
      if (mounted) setState(() => _estados = list);
    } catch (_) {}
    if (mounted) setState(() => _loadingEstados = false);
  }

  Future<void> _loadCiudades(String pais, String estado) async {
    setState(() => _loadingCiudades = true);
    try {
      final list = await GeographyService.getCiudades(pais, estado);
      if (mounted) setState(() => _ciudades = list);
    } catch (_) {}
    if (mounted) setState(() => _loadingCiudades = false);
  }

  void _onPaisSelected(GeoCountry pais) {
    widget.onChange(
      widget.value.copyWith(
        paisIso2:   pais.isoCode,
        paisNombre: pais.nombre,
        clearDiv1:  true,
      ),
    );
  }

  void _onEstadoSelected(GeoState estado) {
    widget.onChange(
      widget.value.copyWith(
        div1Iso2:   estado.codigo,
        div1Nombre: estado.nombre,
        clearDiv2:  true,
      ),
    );
  }

  void _onCiudadSelected(String ciudad) {
    widget.onChange(widget.value.copyWith(div2Nombre: ciudad));
  }

  Future<void> _openPickerSheet<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) labelOf,
    required void Function(T) onSelected,
    T? selected,
  }) async {
    final result = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PickerSheet<T>(
        title: title,
        items: items,
        labelOf: labelOf,
        selected: selected,
      ),
    );
    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.value;
    final hasPais   = v.paisIso2 != null && v.paisIso2!.isNotEmpty;
    final hasEstado = v.div1Iso2 != null && v.div1Iso2!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── País ─────────────────────────────────────────────────────────────
        _DropLabel('País'),
        _DropField(
          value:    v.paisNombre ?? '',
          hint:     _loadingPaises ? 'Cargando países…' : 'Seleccionar país…',
          enabled:  !_loadingPaises && _paises.isNotEmpty,
          loading:  _loadingPaises,
          onTap:    () => _openPickerSheet<GeoCountry>(
            context:    context,
            title:      'Seleccionar país',
            items:      _paises,
            labelOf:    (p) => p.nombre,
            onSelected: _onPaisSelected,
            selected:   hasPais ? _paises.cast<GeoCountry?>().firstWhere(
                (p) => p?.isoCode == v.paisIso2, orElse: () => null) : null,
          ),
        ),
        const SizedBox(height: 10),

        // ── Departamento + Ciudad ─────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DropLabel('Departamento / Estado'),
                  _DropField(
                    value:   v.div1Nombre ?? '',
                    hint:    _loadingEstados  ? 'Cargando…'
                             : hasPais        ? 'Seleccionar…'
                                              : 'Primero elige el país',
                    enabled: hasPais && !_loadingEstados && _estados.isNotEmpty,
                    loading: _loadingEstados,
                    onTap:   () => _openPickerSheet<GeoState>(
                      context:    context,
                      title:      'Seleccionar departamento',
                      items:      _estados,
                      labelOf:    (s) => s.nombre,
                      onSelected: _onEstadoSelected,
                      selected:   hasEstado ? _estados.cast<GeoState?>().firstWhere(
                          (s) => s?.codigo == v.div1Iso2, orElse: () => null) : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DropLabel('Ciudad / Municipio *'),
                  _ciudades.isNotEmpty
                      ? _DropField(
                          value:   v.div2Nombre ?? '',
                          hint:    _loadingCiudades ? 'Cargando…' : 'Seleccionar…',
                          enabled: hasEstado && !_loadingCiudades,
                          loading: _loadingCiudades,
                          onTap:   () => _openPickerSheet<String>(
                            context:    context,
                            title:      'Seleccionar ciudad',
                            items:      _ciudades,
                            labelOf:    (c) => c,
                            onSelected: _onCiudadSelected,
                            selected:   v.div2Nombre,
                          ),
                        )
                      : TextField(
                          controller: TextEditingController(text: v.div2Nombre ?? '')
                            ..selection = TextSelection.collapsed(
                                offset: (v.div2Nombre ?? '').length),
                          enabled:  hasEstado && !_loadingCiudades,
                          onChanged: (s) =>
                              widget.onChange(widget.value.copyWith(div2Nombre: s)),
                          decoration: _textDeco(
                            hint: _loadingCiudades
                                ? 'Cargando…'
                                : hasEstado
                                    ? 'Escribe la ciudad…'
                                    : 'Primero elige el dept.',
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Dirección ─────────────────────────────────────────────────────────
        _DropLabel('Dirección (calle, número, barrio) *'),
        TextField(
          controller: TextEditingController(text: v.address ?? '')
            ..selection =
                TextSelection.collapsed(offset: (v.address ?? '').length),
          onChanged: (s) =>
              widget.onChange(widget.value.copyWith(address: s)),
          decoration: _textDeco(
            hint: 'Ej: Calle 45 #12-30, Barrio Centro',
            prefixIcon: const Icon(Icons.location_on_outlined,
                size: 14, color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }

  InputDecoration _textDeco({String? hint, Widget? prefixIcon}) => InputDecoration(
        hintText:        hint,
        prefixIcon:      prefixIcon,
        isDense:         true,
        contentPadding:  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border:          OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder:   OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder:   OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kBlue, width: 1.5),
        ),
        disabledBorder:  OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        filled:          true,
        fillColor:       const Color(0xFFFAFAFA),
      );
}

class _DropLabel extends StatelessWidget {
  const _DropLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      );
}

class _DropField extends StatelessWidget {
  const _DropField({
    required this.value,
    required this.hint,
    required this.enabled,
    required this.onTap,
    this.loading = false,
  });
  final String     value;
  final String     hint;
  final bool       enabled;
  final bool       loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFFAFAFA) : const Color(0xFFF1F5F9),
          border: Border.all(
            color: hasValue ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: loading
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5))
                  : Text(
                      hasValue ? value : hint,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasValue
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF94A3B8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: enabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hoja de búsqueda / selección ───────────────────────────────────────────────
class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    required this.labelOf,
    this.selected,
  });
  final String         title;
  final List<T>        items;
  final String Function(T) labelOf;
  final T?             selected;

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  late List<T> _filtered;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _ctrl.addListener(() {
      final q = _ctrl.text.toLowerCase();
      setState(() => _filtered = q.isEmpty
          ? widget.items
          : widget.items
              .where((i) => widget.labelOf(i).toLowerCase().contains(q))
              .toList());
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final mq         = MediaQuery.of(context);
    final keyboardH  = mq.viewInsets.bottom;
    final safeBottom = mq.padding.bottom;
    // Altura fija del sheet — no cambia cuando aparece el teclado.
    // El teclado se absorbe con un SizedBox en la parte inferior.
    const sheetH = 480.0;

    return SizedBox(
      height: sheetH,
      child: Column(
        children: [
          // Indicador de arrastre
          const SizedBox(height: 8),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A))),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: const Color(0xFF94A3B8),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar…',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          // Lista — ocupa el espacio restante entre el campo y el teclado
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text('Sin resultados',
                        style: TextStyle(color: Color(0xFF94A3B8))),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final item  = _filtered[i];
                      final label = widget.labelOf(item);
                      final isSel = widget.selected != null &&
                          widget.labelOf(widget.selected as T) == label;
                      return ListTile(
                        dense: true,
                        title: Text(label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                              color: isSel ? AppColors.kBlue : const Color(0xFF0F172A),
                            )),
                        trailing: isSel
                            ? const Icon(Icons.check, size: 16, color: AppColors.kBlue)
                            : null,
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
          ),
          // Empuja el contenido encima del teclado sin cambiar la altura del sheet
          SizedBox(height: keyboardH > 0 ? keyboardH : safeBottom + 8),
        ],
      ),
    );
  }
}
