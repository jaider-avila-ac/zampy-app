import 'package:flutter/material.dart';

import '../../../../../services/live_editor_service.dart';
import '../../../../../shared/app_colors.dart';
import '../editor_models.dart';

const _maxOpcionesGrupo = 30; // tope por grupo (coincide con el backend)

class GroupsLiveTab extends StatefulWidget {
  const GroupsLiveTab({super.key, required this.menu, required this.onChanged});

  final LiveMenu menu;
  final Future<void> Function() onChanged;

  @override
  State<GroupsLiveTab> createState() => _GroupsLiveTabState();
}

class _GroupsLiveTabState extends State<GroupsLiveTab> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.kRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openForm([LiveGroup? group]) async {
    final name = TextEditingController(text: group?.name ?? '');
    var active = group?.isActive ?? true;
    var modo = group?.seleccionModo ?? 'ninguno';
    final maxCtrl = TextEditingController(text: (group?.seleccionMax ?? 2).toString());
    final items = [
      for (final i in (group?.items ?? []))
        _ItemRow(
          name: i['name'] as String? ?? '',
          price: ((i['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(0),
        ),
    ];
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group == null ? 'Nuevo grupo' : 'Editar grupo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activo', style: TextStyle(fontSize: 13)),
                  value: active,
                  onChanged: (v) => setModal(() => active = v),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Límite de selección',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Text(
                  'Cuántas opciones puede elegir el cliente.',
                  style: TextStyle(fontSize: 11, color: AppColors.kTextMuted),
                ),
                for (final o in const [
                  ['ninguno', 'Sin límite', 'Elige las que quiera.'],
                  ['fijo', 'Número fijo', 'Elige hasta N opciones.'],
                  ['segun_tamano', 'Según el tamaño', 'El número lo da el tamaño/variante elegido.'],
                ])
                  _OpcionLimite(
                    activo: modo == o[0],
                    titulo: o[1],
                    detalle: o[2],
                    onTap: () => setModal(() => modo = o[0]),
                  ),
                if (modo == 'fijo')
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
                    child: Row(
                      children: [
                        const Text('Elige hasta ', style: TextStyle(fontSize: 13)),
                        SizedBox(
                          width: 56,
                          child: TextField(
                            controller: maxCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(isDense: true),
                          ),
                        ),
                        const Text(' opciones', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'Opciones',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: items[i].name,
                            decoration: const InputDecoration(
                              hintText: 'Opción',
                              isDense: true,
                            ),
                            onChanged: (v) => items[i].name = v,
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 70,
                          child: TextFormField(
                            initialValue: items[i].price,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Precio',
                              isDense: true,
                            ),
                            onChanged: (v) => items[i].price = v,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setModal(() => items.removeAt(i)),
                          icon: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                TextButton.icon(
                  onPressed: items.length >= _maxOpcionesGrupo
                      ? null
                      : () => setModal(
                            () => items.add(_ItemRow(name: '', price: '0')),
                          ),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Agregar opción'),
                ),
                // El aviso solo aparece al acercarse al tope
                if (_maxOpcionesGrupo - items.length <= 2)
                  Text(
                    items.length >= _maxOpcionesGrupo
                        ? 'Llegaste al máximo ($_maxOpcionesGrupo opciones).'
                        : 'Puedes agregar ${_maxOpcionesGrupo - items.length} más.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.kTextMuted,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (name.text.trim().isEmpty) return;
                        Navigator.pop(ctx, true);
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved != true) return;
    final body = {
      'name': name.text.trim(),
      'isActive': active,
      'order': group?.order ?? widget.menu.groups.length,
      'seleccionModo': modo,
      'seleccionMax': modo == 'fijo'
          ? (int.tryParse(maxCtrl.text) ?? 1).clamp(1, 30)
          : null,
      'items': [
        for (final i in items)
          if (i.name.trim().isNotEmpty)
            {
              'name': i.name.trim(),
              'isActive': true,
              'price': double.tryParse(i.price) ?? 0,
            },
      ],
    };
    await _run(() async {
      if (group == null) {
        await LiveEditorService.createGroup(widget.menu.codigo, body);
      } else {
        await LiveEditorService.updateGroup(
          widget.menu.codigo,
          group.codigo,
          body,
        );
      }
    });
  }

  Future<void> _delete(LiveGroup group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: Text('¿Eliminar "${group.name}"?'),
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
    if (ok == true) {
      await _run(
        () => LiveEditorService.deleteGroup(widget.menu.codigo, group.codigo),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.menu.groups;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Text(
                '${groups.length} grupos',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.kTextMuted,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy ? null : () => _openForm(),
                icon: const Icon(Icons.add, size: 15),
                label: const Text('Nuevo'),
              ),
            ],
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? const Center(child: Text('Sin grupos de opciones.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                  itemCount: groups.length,
                  itemBuilder: (_, i) {
                    final g = groups[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.kCardBorder),
                      ),
                      child: ListTile(
                        onTap: _busy ? null : () => _openForm(g),
                        title: Text(
                          g.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${g.items.length} opciones · ${g.isActive ? 'Activo' : 'Inactivo'}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: IconButton(
                          onPressed: _busy ? null : () => _delete(g),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.kRed,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ItemRow {
  _ItemRow({required this.name, required this.price});
  String name;
  String price;
}

class _OpcionLimite extends StatelessWidget {
  const _OpcionLimite({
    required this.activo,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });
  final bool activo;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: activo ? color : const Color(0xFFE2E8F0), width: activo ? 1.5 : 1),
          borderRadius: BorderRadius.circular(10),
          color: activo ? color.withValues(alpha: 0.06) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(activo ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 18, color: activo ? color : const Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: activo ? color : null)),
                  Text(detalle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
