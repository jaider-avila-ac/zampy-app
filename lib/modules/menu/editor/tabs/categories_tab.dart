import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/category_icons.dart';
import '../../../../shared/app_colors.dart';
import '../models/editor_menu_model.dart';
import '../shared/save_bar.dart';

// Equivalente a la sanitización del nombre de categoría en React:
// replace(/[^a-zA-Z0-9áéíóúÁÉÍÓÚüÜñÑ ]/g, '')
// Usamos \p{L} con unicode para cubrir todos los caracteres de letras.
class _CategoryNameFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue newVal) {
    var text = newVal.text.replaceAll(RegExp(r'[^\p{L}0-9\s]', unicode: true), '');
    if (text.length > 40) text = text.substring(0, 40);
    return newVal.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// Equivalente a src/modules/menu/editor/CategoriesTab.jsx en React
// CRUD de categorías con selector de ícono, visibilidad y reordenamiento.

class CategoriesTab extends StatefulWidget {
  const CategoriesTab({
    super.key,
    required this.draft,
    required this.onSave,
    required this.saving,
    required this.subscription,
  });

  final EditorDraft draft;
  final Future<void> Function(Map<String, dynamic> patch) onSave;
  final bool saving;
  final EditorSubscription subscription;

  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  late List<EditorCategory> _cats;
  bool _dirty      = false;
  bool _reordering = false;

  @override
  void initState() {
    super.initState();
    _cats = List.from(widget.draft.categories);
  }

  void _mutate(List<EditorCategory> next) {
    setState(() { _cats = next; _dirty = true; });
  }

  Future<void> _handleSave() async {
    await widget.onSave({'categories': _cats.map((c) => c.toJson()).toList()});
    setState(() { _dirty = false; _reordering = false; });
  }

  void _toggleVisible(String id) {
    _mutate(_cats.map((c) {
      if (c.id == id) c.isVisible = !c.isVisible;
      return c;
    }).toList());
  }

  void _move(String id, int dir) {
    final idx  = _cats.indexWhere((c) => c.id == id);
    final nIdx = idx + dir;
    if (nIdx < 0 || nIdx >= _cats.length) return;
    final arr = List<EditorCategory>.from(_cats);
    final tmp = arr[idx]; arr[idx] = arr[nIdx]; arr[nIdx] = tmp;
    for (int i = 0; i < arr.length; i++) { arr[i].order = i; }
    _mutate(arr);
  }

  void _openCreate() {
    _showCatModal(context, null);
  }

  void _openEdit(EditorCategory cat) {
    _showCatModal(context, cat);
  }

  void _showCatModal(BuildContext ctx, EditorCategory? editing) {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    String icon          = editing?.icon ?? 'burger';
    String tipoContenido = editing?.tipoContenido ?? 'con_imagenes';
    final isEditing = editing != null;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      isEditing ? 'Editar categoría' : 'Nueva categoría',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Nombre
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  maxLength: 40,
                  inputFormatters: [_CategoryNameFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Nombre *',
                    hintText: 'Ej: Panadería y pasteles',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Selector de ícono
                const Text('Ícono', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: GridView.count(
                    crossAxisCount: 6,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    children: kCategoryIconList.map((entry) {
                      final (value, label, iconData) = entry;
                      final selected = icon == value;
                      return GestureDetector(
                        onTap: () => setModal(() => icon = value),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selected ? AppColors.kBlue : const Color(0xFFE2E8F0),
                              width: selected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: selected ? const Color(0xFFEEF2FF) : Colors.white,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(iconData, size: 18,
                                  color: selected ? AppColors.kBlue : const Color(0xFF64748B)),
                              const SizedBox(height: 3),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: selected ? AppColors.kBlue : const Color(0xFF64748B),
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Tipo de contenido (solo al crear)
                if (!isEditing) ...[
                  const Text('Tipo de categoría',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        for (final opt in [
                          ('con_imagenes', 'Con imágenes'),
                          ('sin_imagenes', 'Sin imágenes'),
                        ]) ...[
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModal(() => tipoContenido = opt.$1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: tipoContenido == opt.$1
                                      ? const Color(0xFF0F172A)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  opt.$2,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: tipoContenido == opt.$1
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (tipoContenido == 'sin_imagenes') ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Solo modo lista/texto. No permite imágenes.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ] else ...[
                  // Edición: mostrar tipo como badge locked
                  Row(
                    children: [
                      const Text('Tipo: ',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          editing.tipoContenido == 'sin_imagenes'
                              ? 'Sin imágenes' : 'Con imágenes',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.lock_outline, size: 13, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ],
                const SizedBox(height: 20),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          Navigator.pop(ctx);
                          if (isEditing) {
                            editing.name = name;
                            editing.icon = icon;
                            _mutate(List.from(_cats));
                          } else {
                            final newCat = EditorCategory(
                              id:            'local_${DateTime.now().microsecondsSinceEpoch}',
                              name:          name,
                              icon:          icon,
                              tipoContenido: tipoContenido,
                              order:         _cats.length,
                            );
                            final updated = [..._cats, newCat];
                            // Guardar inmediatamente al crear (como React)
                            widget.onSave({'categories': updated.map((c) => c.toJson()).toList()});
                            setState(() { _cats = updated; });
                          }
                        },
                        style: FilledButton.styleFrom(backgroundColor: AppColors.kBlue),
                        child: Text(isEditing ? 'Guardar' : 'Crear'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(EditorCategory cat) {
    final nProds = widget.draft.productsInCategory(cat.id);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar categoría', style: TextStyle(fontSize: 16)),
        content: nProds > 0
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'La categoría "${cat.name}" tiene $nProds producto(s). Elimina primero sus productos.',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              )
            : Text('¿Eliminar la categoría "${cat.name}"? No se puede deshacer.',
                style: const TextStyle(fontSize: 14)),
        actions: nProds > 0
            ? [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendido'),
                ),
              ]
            : [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _mutate(_cats.where((c) => c.id != cat.id).toList());
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
    final atLimit = widget.subscription.categoryLimitReached(_cats.length);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header con contador y botones
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          widget.subscription.limiteCategorias != null
                              ? '${_cats.length}/${widget.subscription.limiteCategorias} categorías'
                              : '${_cats.length} categorías',
                          style: TextStyle(
                            fontSize: 13,
                            color: atLimit ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                            fontWeight: atLimit ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                        if (atLimit) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline, size: 9, color: Color(0xFFDC2626)),
                                SizedBox(width: 3),
                                Text('Límite', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_cats.length > 1)
                    TextButton.icon(
                      onPressed: () => setState(() => _reordering = !_reordering),
                      icon: Icon(_reordering ? Icons.check : Icons.swap_vert, size: 14),
                      label: Text(_reordering ? 'Ordenando…' : 'Reordenar', style: const TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: _reordering ? AppColors.kBlue : const Color(0xFF64748B),
                        backgroundColor: _reordering ? const Color(0xFFEEF2FF) : Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  const SizedBox(width: 6),
                  FilledButton.icon(
                    onPressed: atLimit ? null : _openCreate,
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Nueva', style: TextStyle(fontSize: 13)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.kBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Hint reordenamiento
              if (_reordering)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Usa las flechas para reordenar. Presiona Guardar cambios cuando termines.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4338CA)),
                  ),
                ),

              // Empty state
              if (_cats.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.category_outlined, size: 36, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 12),
                      const Text('Sin categorías', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text('Crea categorías para organizar tu menú.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _openCreate,
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Crear primera categoría'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.kBlue),
                      ),
                    ],
                  ),
                ),

              // Lista de categorías
              ...List.generate(_cats.length, (idx) {
                final cat = _cats[idx];
                final icon = categoryIcon(cat.icon);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _reordering ? const Color(0xFFF5F7FF) : Colors.white,
                    border: Border.all(
                      color: _reordering
                          ? const Color(0xFFC7D2FE)
                          : const Color(0xFFE2E8F0),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Opacity(
                    opacity: cat.isVisible ? 1 : 0.55,
                    child: Row(
                      children: [
                        Icon(icon, size: 16, color: AppColors.kBlue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  cat.name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (cat.tipoContenido == 'sin_imagenes') ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: const Text('Sin imágenes',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_reordering) ...[
                          _ArrowBtn(
                            icon: Icons.arrow_upward,
                            enabled: idx > 0,
                            onTap: () => _move(cat.id, -1),
                          ),
                          _ArrowBtn(
                            icon: Icons.arrow_downward,
                            enabled: idx < _cats.length - 1,
                            onTap: () => _move(cat.id, 1),
                          ),
                        ] else ...[
                          _IconBtn(
                            icon: cat.isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            onTap: () => _toggleVisible(cat.id),
                          ),
                          _IconBtn(
                            icon: Icons.edit_outlined,
                            onTap: () => _openEdit(cat),
                          ),
                          _IconBtn(
                            icon: Icons.delete_outline,
                            danger: true,
                            onTap: () => _confirmDelete(cat),
                          ),
                        ],
                      ],
                    ),
                  ),
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

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, this.danger = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon, size: 16,
            color: danger ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
          ),
        ),
      );
}

class _ArrowBtn extends StatelessWidget {
  const _ArrowBtn({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(
            icon, size: 16,
            color: enabled ? AppColors.kBlue : const Color(0xFFCBD5E1),
          ),
        ),
      );
}
