import 'package:flutter/material.dart';

import '../../../../../services/live_editor_service.dart';
import '../../../../../shared/app_colors.dart';
import '../editor_models.dart';

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
                  onPressed: () =>
                      setModal(() => items.add(_ItemRow(name: '', price: '0'))),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Agregar opción'),
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
