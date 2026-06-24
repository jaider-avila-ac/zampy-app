import 'package:flutter/material.dart';
import '../../../../services/menu_editor_service.dart';
import '../../../../shared/app_colors.dart';
import '../models/editor_menu_model.dart';

// Equivalente a src/modules/menu/editor/ColaboradoresTab.jsx en React
// Invitar, listar y remover colaboradores. Transferencia de menú.

class ColaboradoresTab extends StatefulWidget {
  const ColaboradoresTab({
    super.key,
    required this.menuId,
    required this.subscription,
    required this.transferible,
    required this.onTransferido,
  });

  final int menuId;
  final EditorSubscription subscription;
  final bool transferible;
  final VoidCallback onTransferido;

  @override
  State<ColaboradoresTab> createState() => _ColaboradoresTabState();
}

class _ColaboradoresTabState extends State<ColaboradoresTab> {
  List<Map<String, dynamic>> _colaboradores = [];
  bool _loading = true;

  // Invitar
  final _codigoCtrl = TextEditingController();
  bool _invitando = false;
  String _errorInvitar = '';

  // Remover
  int? _removiendo;

  // Transferir
  final _codigoTransferCtrl = TextEditingController();
  bool _transfiriendo = false;
  bool _confirmando   = false;
  String _errorTransfer = '';
  Map<String, dynamic>? _transferPendiente;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _codigoTransferCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await MenuEditorService.listarColaboradores(widget.menuId);
      if (!mounted) return;
      setState(() {
        _colaboradores = list.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _invitar() async {
    final codigo = _codigoCtrl.text.trim().toUpperCase();
    if (codigo.length < 6) return;
    setState(() { _invitando = true; _errorInvitar = ''; });
    try {
      final nuevo = await MenuEditorService.invitarColaborador(widget.menuId, codigo);
      if (!mounted) return;
      setState(() {
        _colaboradores = [..._colaboradores, nuevo];
        _codigoCtrl.clear();
        _invitando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorInvitar = e.toString().replaceFirst('Exception: ', ''); _invitando = false; });
    }
  }

  Future<void> _remover(int userId) async {
    setState(() => _removiendo = userId);
    try {
      await MenuEditorService.eliminarColaborador(widget.menuId, userId);
      if (!mounted) return;
      setState(() {
        _colaboradores = _colaboradores.where((c) => c['userId'] != userId).toList();
        _removiendo = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _removiendo = null);
    }
  }

  Future<void> _confirmarTransferencia() async {
    setState(() { _transfiriendo = true; _errorTransfer = ''; });
    try {
      final res = await MenuEditorService.transferirMenu(
          widget.menuId, _codigoTransferCtrl.text.trim().toUpperCase());
      if (!mounted) return;
      if (res['estado'] == 'PENDIENTE') {
        setState(() {
          _transferPendiente = res;
          _confirmando = false;
          _codigoTransferCtrl.clear();
          _transfiriendo = false;
        });
      } else {
        widget.onTransferido();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorTransfer = e.toString().replaceFirst('Exception: ', '');
        _confirmando = false;
        _transfiriendo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final atLim = widget.subscription.colaboradorLimitReached(_colaboradores.length);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // ── Invitar ─────────────────────────────────────────────────────────
        _Section(
          title: 'Invitar colaborador',
          trailing: widget.subscription.limiteColaboradores != null
              ? Text(
                  '${_colaboradores.length}/${widget.subscription.limiteColaboradores}',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: atLim ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                  ),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingresa el código de 6 caracteres de la persona que quieres agregar. Los colaboradores pueden editar categorías y productos, pero no pueden publicar ni eliminar el menú.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              if (atLim)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      Text(
                        'Alcanzaste el límite de ${widget.subscription.limiteColaboradores} colaboradores.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codigoCtrl,
                        maxLength: 6,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (v) {
                          final upper = v.toUpperCase();
                          if (upper != v) {
                            _codigoCtrl.value = TextEditingValue(
                              text: upper,
                              selection: TextSelection.collapsed(offset: upper.length),
                            );
                          }
                          setState(() => _errorInvitar = '');
                        },
                        decoration: InputDecoration(
                          hintText: 'ABCD12',
                          counterText: '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        style: const TextStyle(
                          fontFamily: 'monospace', letterSpacing: 4,
                          fontSize: 16, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: (_invitando || _codigoCtrl.text.trim().length < 6)
                          ? null
                          : _invitar,
                      icon: _invitando
                          ? const SizedBox(width: 13, height: 13,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.person_add_outlined, size: 15),
                      label: const Text('Invitar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.kBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              if (_errorInvitar.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(_errorInvitar, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Lista de colaboradores ──────────────────────────────────────────
        _Section(
          title: 'Colaboradores actuales',
          child: _loading
              ? Column(
                  children: List.generate(2, (i) => Container(
                    height: 56, margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  )),
                )
              : _colaboradores.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: const Center(
                        child: Text('No hay colaboradores en este menú.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: List.generate(_colaboradores.length, (i) {
                          final c = _colaboradores[i];
                          final userId = (c['userId'] as num?)?.toInt() ?? 0;
                          final nombre = [c['nombre'], c['apellido']]
                              .where((s) => s != null && (s as String).isNotEmpty)
                              .join(' ');
                          final avatar = c['avatar'] as String?;
                          final isRemoving = _removiendo == userId;

                          return Container(
                            decoration: BoxDecoration(
                              border: i > 0
                                  ? const Border(top: BorderSide(color: Color(0xFFF1F5F9)))
                                  : null,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                // Avatar
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFFEEF2FF),
                                  backgroundImage: avatar != null && avatar.isNotEmpty
                                      ? NetworkImage(avatar) : null,
                                  child: (avatar == null || avatar.isEmpty)
                                      ? Text(
                                          (c['nombre'] as String? ?? '?')[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: AppColors.kBlue, fontWeight: FontWeight.w700, fontSize: 14,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    nombre.isEmpty ? 'Sin nombre' : nombre,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                isRemoving
                                    ? const SizedBox(width: 14, height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2))
                                    : IconButton(
                                        onPressed: () => _remover(userId),
                                        icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFF94A3B8)),
                                        tooltip: 'Eliminar colaborador',
                                        style: IconButton.styleFrom(
                                          padding: const EdgeInsets.all(6),
                                          minimumSize: const Size(32, 32),
                                        ),
                                      ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
        ),
        const SizedBox(height: 24),

        // ── Transferir ──────────────────────────────────────────────────────
        Divider(color: const Color(0xFFE2E8F0)),
        const SizedBox(height: 16),
        Row(
          children: const [
            Icon(Icons.swap_horiz_outlined, size: 16, color: Color(0xFFF59E0B)),
            SizedBox(width: 6),
            Text('Transferir menú',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          ],
        ),
        const SizedBox(height: 10),

        if (!widget.transferible)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, size: 13, color: Color(0xFF94A3B8)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Este menú ya fue publicado y no puede transferirse.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          )
        else if (_transferPendiente != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              border: Border.all(color: const Color(0xFFFCD34D)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_outlined, size: 14, color: Color(0xFFF59E0B)),
                    SizedBox(width: 6),
                    Text('Solicitud enviada', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Se envió una notificación a ${[_transferPendiente!['destinoNombre'], _transferPendiente!['destinoApellido']].where((s) => s != null && (s as String).isNotEmpty).join(' ')}. Cuando acepte, pasará a ser el dueño.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transfiere la propiedad de este menú a otro usuario con su código. El destinatario deberá aceptar.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              if (!_confirmando)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codigoTransferCtrl,
                        maxLength: 6,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (v) {
                          final upper = v.toUpperCase();
                          if (upper != v) {
                            _codigoTransferCtrl.value = TextEditingValue(
                              text: upper,
                              selection: TextSelection.collapsed(offset: upper.length),
                            );
                          }
                          setState(() => _errorTransfer = '');
                        },
                        decoration: InputDecoration(
                          hintText: 'ABCD12',
                          counterText: '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        style: const TextStyle(
                          fontFamily: 'monospace', letterSpacing: 4,
                          fontSize: 16, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _codigoTransferCtrl.text.trim().length < 6
                          ? null
                          : () => setState(() => _confirmando = true),
                      icon: const Icon(Icons.swap_horiz_outlined, size: 15),
                      label: const Text('Transferir'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.warning_amber_outlined, size: 14, color: Color(0xFFF59E0B)),
                          SizedBox(width: 6),
                          Text('¿Enviar solicitud de transferencia?',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'El usuario con código ${_codigoTransferCtrl.text.toUpperCase()} recibirá una notificación. Si acepta, pasará a ser el dueño y tú quedarás como colaborador.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: _transfiriendo ? null : _confirmarTransferencia,
                            icon: _transfiriendo
                                ? const SizedBox(width: 12, height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.swap_horiz_outlined, size: 13),
                            label: const Text('Sí, enviar', style: TextStyle(fontSize: 12)),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _transfiriendo
                                ? null
                                : () => setState(() { _confirmando = false; _errorTransfer = ''; }),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (_errorTransfer.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(_errorTransfer,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const Spacer(),
              if (trailing case final w?) w,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      );
}
