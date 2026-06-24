import 'package:flutter/material.dart';
import 'app_colors.dart';

// Equivalente a ScheduleInput.jsx en React:
// 3 combos (Días | Abre | Cierra) → genera string "Lun – Vie: 11:00 AM – 10:00 PM"

const _kDays = [
  (value: 'lun-vie', label: 'Lunes – Viernes',  short: 'Lun – Vie'),
  (value: 'lun-sab', label: 'Lunes – Sábado',   short: 'Lun – Sáb'),
  (value: 'lun-dom', label: 'Lunes – Domingo',  short: 'Lun – Dom'),
  (value: 'mar-dom', label: 'Martes – Domingo', short: 'Mar – Dom'),
  (value: 'mie-dom', label: 'Miércoles – Dom.', short: 'Mié – Dom'),
  (value: 'sab-dom', label: 'Fines de semana',  short: 'Sáb – Dom'),
  (value: 'sabados', label: 'Solo Sábados',      short: 'Sábados'),
  (value: 'domingos',label: 'Solo Domingos',     short: 'Domingos'),
];

List<({String value, String label})> _buildTimes() {
  final slots = <({String value, String label})>[];
  String pad(int n) => n.toString().padLeft(2, '0');
  String fmt(int h, int m) {
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : h > 12 ? h - 12 : h;
    return '$h12:${pad(m)} $period';
  }
  for (var h = 6; h < 24; h++) {
    for (final m in [0, 30]) {
      slots.add((value: '${pad(h)}:${pad(m)}', label: fmt(h, m)));
    }
  }
  for (var h = 0; h < 4; h++) {
    for (final m in [0, 30]) {
      final lbl = h == 0 ? '12:${pad(m)} AM' : '$h:${pad(m)} AM';
      slots.add((value: '${pad(h + 24)}:${pad(m)}', label: lbl));
    }
  }
  return slots;
}

final _kTimes = _buildTimes();

String _buildString(String days, String open, String close) {
  if (days.isEmpty || open.isEmpty || close.isEmpty) return '';
  final dayOpt  = _kDays.cast<({String value, String label, String short})?>()
      .firstWhere((d) => d?.value == days, orElse: () => null);
  final openLbl  = _kTimes.cast<({String value, String label})?>()
      .firstWhere((t) => t?.value == open,  orElse: () => null)?.label ?? open;
  final closeLbl = _kTimes.cast<({String value, String label})?>()
      .firstWhere((t) => t?.value == close, orElse: () => null)?.label ?? close;
  return '${dayOpt?.short ?? days}: $openLbl – $closeLbl';
}

String _parseDays(String? str) {
  if (str == null || str.isEmpty) return 'lun-dom';
  final s = str.toLowerCase();
  if (s.contains('lun') && s.contains('vie')) return 'lun-vie';
  if (s.contains('lun') && s.contains('sáb')) return 'lun-sab';
  if (s.contains('lun') && s.contains('dom')) return 'lun-dom';
  if (s.contains('mar') && s.contains('dom')) return 'mar-dom';
  if (s.contains('mié') && s.contains('dom')) return 'mie-dom';
  if (s.contains('sáb') && s.contains('dom')) return 'sab-dom';
  return 'lun-dom';
}

class ScheduleWidget extends StatefulWidget {
  const ScheduleWidget({
    super.key,
    required this.value,
    required this.onChange,
  });
  final String? value;
  final ValueChanged<String> onChange;

  @override
  State<ScheduleWidget> createState() => _ScheduleWidgetState();
}

class _ScheduleWidgetState extends State<ScheduleWidget> {
  late String _days;
  late String _open;
  late String _close;

  @override
  void initState() {
    super.initState();
    _days  = _parseDays(widget.value);
    _open  = '11:00';
    _close = '22:00';
    // Emite el valor inicial para que el padre tenga el string formateado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChange(_buildString(_days, _open, _close));
    });
  }

  void _set(String days, String open, String close) {
    setState(() { _days = days; _open = open; _close = close; });
    widget.onChange(_buildString(days, open, close));
  }

  @override
  Widget build(BuildContext context) {
    final preview = _buildString(_days, _open, _close);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 3 combos ──────────────────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Días (ocupa más espacio)
            Expanded(
              flex: 5,
              child: _ComboField(
                label: 'Días',
                value: _days,
                items: _kDays
                    .map((d) => (value: d.value, label: d.label))
                    .toList(),
                onChanged: (v) => _set(v, _open, _close),
              ),
            ),
            const SizedBox(width: 8),
            // Abre
            Expanded(
              flex: 3,
              child: _ComboField(
                label: 'Abre',
                value: _open,
                items: _kTimes,
                onChanged: (v) => _set(_days, v, _close),
              ),
            ),
            const SizedBox(width: 8),
            // Cierra
            Expanded(
              flex: 3,
              child: _ComboField(
                label: 'Cierra',
                value: _close,
                items: _kTimes,
                onChanged: (v) => _set(_days, _open, v),
              ),
            ),
          ],
        ),
        // ── Preview ───────────────────────────────────────────────────────────
        if (preview.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 12, color: AppColors.kBlue),
                const SizedBox(width: 4),
                Text(preview,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kBlue)),
              ],
            ),
          ),
      ],
    );
  }
}

class _ComboField extends StatelessWidget {
  const _ComboField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<({String value, String label})> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          isDense: true,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.kBlue, width: 1.5),
            ),
          ),
          style: const TextStyle(
              fontSize: 12, color: Color(0xFF0F172A)),
          items: items
              .map((t) => DropdownMenuItem(
                    value: t.value,
                    child: Text(t.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12)),
                  ))
              .toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ],
    );
  }
}
