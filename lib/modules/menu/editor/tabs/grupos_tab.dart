import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/app_colors.dart';
import '../models/editor_menu_model.dart';
import '../shared/save_bar.dart';

// Equivalente a sanitizeLabel en React/format.js — usado en nombres de grupo e ítems.
// Máx 50 chars, solo letras (con acentos), dígitos, espacios, guiones y /.
class _LabelFormatter extends TextInputFormatter {
  const _LabelFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue newVal) {
    var text = newVal.text.replaceAll(RegExp(r'[^\p{L}0-9\s\-/]', unicode: true), '');
    if (text.isNotEmpty) text = text[0].toUpperCase() + text.substring(1);
    if (text.length > 50) text = text.substring(0, 50);
    return newVal.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// Equivalente a src/modules/menu/editor/GruposTab.jsx en React
// CRUD de grupos informativos con sus ítems, toggle activo y delete modal.

class GruposTab extends StatefulWidget {
  const GruposTab({
    super.key,
    required this.draft,
    required this.onSave,
    required this.saving,
  });

  final EditorDraft draft;
  final Future<void> Function(Map<String, dynamic> patch) onSave;
  final bool saving;

  @override
  State<GruposTab> createState() => _GruposTabState();
}

class _GruposTabState extends State<GruposTab> {
  late List<EditorGrupo> _grupos;
  bool _dirty = false;
  String? _editingId;
  final Map<String, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    _grupos = widget.draft.grupos.map((g) => EditorGrupo(
          id:       g.id,
          name:     g.name,
          isActive: g.isActive,
          items:    g.items.map((i) => EditorGrupoItem(id: i.id, name: i.name, isActive: i.isActive)).toList(),
        )).toList();
  }

  void _mutate(List<EditorGrupo> next) {
    setState(() { _grupos = next; _dirty = true; });
  }

  Future<void> _handleSave() async {
    await widget.onSave({'grupos': _grupos.map((g) => g.toJson()).toList()});
    setState(() => _dirty = false);
  }

  void _addGrupo() {
    final g = EditorGrupo.empty();
    setState(() {
      _grupos = [..._grupos, g];
      _dirty = true;
      _editingId = g.id;
      _expanded[g.id] = true;
    });
  }

  void _updateGrupo(String id, {String? name, bool? isActive}) {
    _mutate(_grupos.map((g) {
      if (g.id != id) return g;
      if (name     != null) g.name     = name;
      if (isActive != null) g.isActive = isActive;
      return g;
    }).toList());
  }

  void _updateItems(String groupId, List<EditorGrupoItem> items) {
    _mutate(_grupos.map((g) {
      if (g.id != groupId) return g;
      g.items = items;
      return g;
    }).toList());
  }

  void _confirmDelete(EditorGrupo g) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar grupo', style: TextStyle(fontSize: 16)),
        content: Text(
          '¿Eliminar el grupo "${g.name.isEmpty ? 'Sin nombre' : g.name}"? Los productos que lo usan dejarán de mostrarlo.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (_editingId == g.id) setState(() => _editingId = null);
              _mutate(_grupos.where((x) => x.id != g.id).toList());
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Grupos informativos',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                        SizedBox(height: 3),
                        Text(
                          'Crea grupos reutilizables y asígnalos a varios productos.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _addGrupo,
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Nuevo grupo', style: TextStyle(fontSize: 13)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.kBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Empty state
              if (_grupos.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline, size: 36, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 12),
                      const Text('Sin grupos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text(
                        'Crea un grupo para reutilizarlo en varios productos. Ej: Sabores disponibles, Salsas incluidas.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _addGrupo,
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Crear primer grupo'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.kBlue),
                      ),
                    ],
                  ),
                ),

              // Lista de grupos
              ..._grupos.map((g) {
                final isEditing  = _editingId == g.id;
                final isExpanded = _expanded[g.id] ?? false;

                return _GrupoCard(
                  key: ValueKey(g.id),
                  grupo: g,
                  isEditing: isEditing,
                  isExpanded: isExpanded,
                  onToggleExpand: () => setState(() => _expanded[g.id] = !isExpanded),
                  onToggleEdit: () {
                    setState(() {
                      _editingId = isEditing ? null : g.id;
                      if (!isEditing) _expanded[g.id] = true;
                    });
                  },
                  onNameChange: (v) => _updateGrupo(g.id, name: v),
                  onActiveChange: (v) => _updateGrupo(g.id, isActive: v),
                  onItemsChange: (items) => _updateItems(g.id, items),
                  onDelete: () => _confirmDelete(g),
                );
              }),
            ],
          ),
        ),
        SaveBar(dirty: _dirty, saving: widget.saving, onSave: _handleSave),
      ],
    );
  }
}

// ── Tarjeta de un grupo ────────────────────────────────────────────────────────
class _GrupoCard extends StatelessWidget {
  const _GrupoCard({
    super.key,
    required this.grupo,
    required this.isEditing,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onToggleEdit,
    required this.onNameChange,
    required this.onActiveChange,
    required this.onItemsChange,
    required this.onDelete,
  });

  final EditorGrupo grupo;
  final bool isEditing;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleEdit;
  final ValueChanged<String> onNameChange;
  final ValueChanged<bool> onActiveChange;
  final ValueChanged<List<EditorGrupoItem>> onItemsChange;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isEditing ? const Color(0xFFA5B4FC) : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isEditing
            ? [const BoxShadow(color: Color(0x14818CF8), blurRadius: 8, offset: Offset(0, 2))]
            : null,
      ),
      child: Opacity(
        opacity: grupo.isActive ? 1 : 0.65,
        child: Column(
          children: [
            // Header de la tarjeta
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onToggleExpand,
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18, color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isEditing)
                          TextField(
                            autofocus: true,
                            controller: TextEditingController(text: grupo.name)
                              ..selection = TextSelection.collapsed(offset: grupo.name.length),
                            onChanged: onNameChange,
                            maxLength: 50,
                            inputFormatters: [const _LabelFormatter()],
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                              hintText: 'Ej: Sabores disponibles',
                              border: UnderlineInputBorder(),
                              counterText: '',
                            ),
                          )
                        else
                          Text(
                            grupo.name.isEmpty ? 'Sin nombre' : grupo.name,
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: grupo.name.isEmpty
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF0F172A),
                              fontStyle: grupo.name.isEmpty ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          '${grupo.items.length} elemento${grupo.items.length != 1 ? 's' : ''}'
                          '${!grupo.isActive ? ' · Inactivo' : ''}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botones
                  InkWell(
                    onTap: onToggleEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        isEditing ? Icons.check_circle_outline : Icons.edit_outlined,
                        size: 16,
                        color: isEditing ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.delete_outline, size: 16, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),

            // Cuerpo expandido
            if (isExpanded)
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ItemsEditor(items: grupo.items, onChange: onItemsChange),
                    const SizedBox(height: 14),
                    // Toggle activo
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Grupo activo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              Text('Los grupos inactivos no se muestran en el menú',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                        Switch(
                          value: grupo.isActive,
                          onChanged: onActiveChange,
                          activeThumbColor: AppColors.kBlue,
                          activeTrackColor: const Color(0xFFC7D2FE),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Editor de ítems de un grupo ────────────────────────────────────────────────
class _ItemsEditor extends StatelessWidget {
  const _ItemsEditor({required this.items, required this.onChange});
  final List<EditorGrupoItem> items;
  final ValueChanged<List<EditorGrupoItem>> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Text('Elementos del grupo',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    final updated = [...items, EditorGrupoItem.empty()];
                    onChange(updated);
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 13, color: AppColors.kBlue),
                      SizedBox(width: 3),
                      Text('Agregar',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kBlue)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Sin elementos — presiona Agregar para añadir opciones',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
            )
          else
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: item.name)
                              ..selection = TextSelection.collapsed(offset: item.name.length),
                            onChanged: (v) {
                              final updated = List<EditorGrupoItem>.from(items);
                              updated[i] = EditorGrupoItem(id: item.id, name: v, isActive: item.isActive);
                              onChange(updated);
                            },
                            maxLength: 50,
                            inputFormatters: [const _LabelFormatter()],
                            decoration: InputDecoration(
                              hintText: 'Ej: Vainilla',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              counterText: '',
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              decoration: item.isActive ? TextDecoration.none : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: item.isActive,
                          onChanged: (v) {
                            final updated = List<EditorGrupoItem>.from(items);
                            updated[i] = EditorGrupoItem(id: item.id, name: item.name, isActive: v);
                            onChange(updated);
                          },
                          activeThumbColor: AppColors.kBlue,
                          activeTrackColor: const Color(0xFFC7D2FE),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        GestureDetector(
                          onTap: () {
                            final updated = List<EditorGrupoItem>.from(items)..removeAt(i);
                            onChange(updated);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.delete_outline, size: 16, color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
