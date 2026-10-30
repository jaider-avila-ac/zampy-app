import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../services/colaboracion_service.dart';
import '../../../../../shared/app_colors.dart';
import '../editor_models.dart';

// Equivalente a src/modules/menu/editor/ColaboradoresTab.jsx en React.
// Invitar (con rol), listar, cambiar rol, eliminar y transferir el menú. Solo dueño.

const _kRed = Color(0xFFDC2626);
const _kAmber = Color(0xFFF59E0B);
const _kAmberDark = Color(0xFF92400E);
const _kAmberBg = Color(0xFFFFFBEB);
const _kAmberBorder = Color(0xFFFCD34D);

String _rolLabel(String rol) => switch (rol) {
  'mesero' => 'Mesero',
  'repartidor' => 'Repartidor',
  _ => 'Editor',
};

String _rolAyuda(String rol) => switch (rol) {
  'mesero' => 'El mesero solo puede ver mesas y crear órdenes.',
  'repartidor' => 'El repartidor solo puede ver y gestionar sus entregas.',
  _ => 'El editor puede modificar categorías y productos.',
};

String _mensaje(Object e) => e.toString().replaceFirst('Exception: ', '');

String _nombre(Map<String, dynamic> m, String prefijo, String fallback) {
  final n = [
    m['${prefijo}Nombre'],
    m['${prefijo}Apellido'],
  ].where((s) => s is String && s.isNotEmpty).join(' ');
  return n.isEmpty ? fallback : n;
}

class CollaboratorsLiveTab extends StatefulWidget {
  const CollaboratorsLiveTab({
    super.key,
    required this.menu,
    required this.onTransferido,
    required this.onSnack,
  });

  final LiveMenu menu;
  final VoidCallback onTransferido;
  final void Function(String message, {bool error}) onSnack;

  @override
  State<CollaboratorsLiveTab> createState() => _CollaboratorsLiveTabState();
}

class _CollaboratorsLiveTabState extends State<CollaboratorsLiveTab> {
  List<Colaborador> _colaboradores = [];
  bool _loading = true;
  String? _errorCarga;

  final _codigoCtrl = TextEditingController();
  String _rolInvitar = 'editor';
  bool _invitando = false;
  String _error = '';
  Map<String, dynamic>? _invitacionEnviada;

  String? _removiendo;
  String? _cambiandoRol;

  final _codigoTransferCtrl = TextEditingController();
  bool _confirmando = false;
  bool _transfiriendo = false;
  String _errorTransfer = '';
  Map<String, dynamic>? _transferPendiente;

  String get _menuCodigo => widget.menu.codigo;
  int? get _limite => widget.menu.subscription.limiteColaboradores;
  bool get _enLimite => _limite != null && _colaboradores.length >= _limite!;

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
    setState(() {
      _loading = true;
      _errorCarga = null;
    });
    try {
      final list = await ColaboracionService.listar(_menuCodigo);
      if (!mounted) return;
      setState(() => _colaboradores = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorCarga = _mensaje(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _invitar() async {
    final codigo = _codigoCtrl.text.trim().toUpperCase();
    if (codigo.length < 6) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _invitando = true;
      _error = '';
      _invitacionEnviada = null;
    });
    try {
      // La invitación queda PENDIENTE: todavía no es colaborador, así que no se
      // agrega a la lista hasta que la acepte desde sus notificaciones.
      final res = await ColaboracionService.invitar(
        _menuCodigo,
        codigo,
        rol: _rolInvitar,
      );
      if (!mounted) return;
      setState(() {
        _invitacionEnviada = res;
        _codigoCtrl.clear();
        _rolInvitar = 'editor';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _mensaje(e));
    } finally {
      if (mounted) setState(() => _invitando = false);
    }
  }

  Future<void> _remover(Colaborador c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar colaborador'),
        content: Text(
          '¿Quitar a ${c.nombreCompleto.isEmpty ? 'este usuario' : c.nombreCompleto} de este menú? '
          'Perderá el acceso de inmediato.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _kRed),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _removiendo = c.codigo);
    try {
      await ColaboracionService.eliminar(_menuCodigo, c.codigo);
      if (!mounted) return;
      setState(
        () => _colaboradores = _colaboradores
            .where((x) => x.codigo != c.codigo)
            .toList(),
      );
    } catch (e) {
      widget.onSnack(_mensaje(e), error: true);
    } finally {
      if (mounted) setState(() => _removiendo = null);
    }
  }

  Future<void> _cambiarRol(Colaborador c, String rol) async {
    if (rol == c.rol) return;
    setState(() => _cambiandoRol = c.codigo);
    try {
      await ColaboracionService.cambiarRol(_menuCodigo, c.codigo, rol);
      if (!mounted) return;
      setState(
        () => _colaboradores = [
          for (final x in _colaboradores)
            x.codigo == c.codigo
                ? Colaborador(
                    codigo: x.codigo,
                    nombre: x.nombre,
                    apellido: x.apellido,
                    avatar: x.avatar,
                    rol: rol,
                  )
                : x,
        ],
      );
    } catch (e) {
      widget.onSnack(_mensaje(e), error: true);
    } finally {
      if (mounted) setState(() => _cambiandoRol = null);
    }
  }

  void _iniciarTransferencia() {
    if (_codigoTransferCtrl.text.trim().length < 6) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _errorTransfer = '';
      _confirmando = true;
    });
  }

  Future<void> _confirmarTransferencia() async {
    setState(() {
      _transfiriendo = true;
      _errorTransfer = '';
    });
    try {
      final res = await ColaboracionService.transferir(
        _menuCodigo,
        _codigoTransferCtrl.text.trim().toUpperCase(),
      );
      if (!mounted) return;
      if (res['estado'] == 'PENDIENTE') {
        setState(() {
          _transferPendiente = res;
          _confirmando = false;
          _codigoTransferCtrl.clear();
        });
      } else {
        widget.onTransferido();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorTransfer = _mensaje(e);
        _confirmando = false;
      });
    } finally {
      if (mounted) setState(() => _transfiriendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _invitarSection(),
          const SizedBox(height: 24),
          _listaSection(),
          const SizedBox(height: 24),
          const Divider(color: AppColors.kCardBorder),
          const SizedBox(height: 16),
          _transferirSection(),
        ],
      ),
    );
  }

  // ── Invitar ───────────────────────────────────────────────────────────────

  Widget _invitarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _Titulo('Invitar colaborador')),
            if (_limite != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _enLimite
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${_colaboradores.length}/$_limite',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _enLimite ? _kRed : AppColors.kTextMuted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Ingresa el código de 6 caracteres de la persona que quieres agregar. '
          'Los colaboradores pueden editar categorías y productos, pero no pueden '
          'publicar ni eliminar el menú.',
          style: TextStyle(fontSize: 12, color: AppColors.kTextMuted),
        ),
        const SizedBox(height: 12),
        if (_enLimite)
          _Aviso(
            icon: Icons.lock_outline,
            color: _kAmberDark,
            bg: _kAmberBg,
            border: const Color(0xFFFDE68A),
            text:
                'Alcanzaste el límite de $_limite colaboradores de tu plan.',
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _CodigoField(
                  controller: _codigoCtrl,
                  onChanged: () => setState(() => _error = ''),
                  onSubmitted: _invitar,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _rolInvitar,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.kTextSecondary,
                    ),
                    items: [
                      for (final r in ColaboracionService.roles)
                        DropdownMenuItem(value: r, child: Text(_rolLabel(r))),
                    ],
                    onChanged: _invitando
                        ? null
                        : (v) => setState(() => _rolInvitar = v ?? 'editor'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _invitando || _codigoCtrl.text.trim().length < 6
                  ? null
                  : _invitar,
              icon: _invitando
                  ? const _Spinner(color: Colors.white)
                  : const Icon(Icons.person_add_alt_1_outlined, size: 16),
              label: const Text('Invitar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.kBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _rolAyuda(_rolInvitar),
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ErrorText(_error),
        ],
        if (_invitacionEnviada != null) ...[
          const SizedBox(height: 8),
          _Aviso(
            icon: Icons.person_add_alt_1_outlined,
            color: const Color(0xFF4338CA),
            bg: const Color(0xFFEEF2FF),
            border: const Color(0xFFC7D2FE),
            text:
                'Invitación enviada a ${_nombre(_invitacionEnviada!, 'invitado', 'el usuario')}. '
                'Aparecerá como colaborador cuando la acepte desde sus notificaciones.',
          ),
        ],
      ],
    );
  }

  // ── Lista ─────────────────────────────────────────────────────────────────

  Widget _listaSection() {
    Widget body;
    if (_loading) {
      body = Column(
        children: List.generate(
          2,
          (_) => Container(
            height: 56,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    } else if (_errorCarga != null) {
      body = _Caja(
        child: Column(
          children: [
            Text(
              _errorCarga!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _kRed),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 15),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    } else if (_colaboradores.isEmpty) {
      body = const _Caja(
        child: Text(
          'No hay colaboradores en este menú.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        ),
      );
    } else {
      body = Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.kCardBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            for (var i = 0; i < _colaboradores.length; i++)
              _ColaboradorRow(
                colaborador: _colaboradores[i],
                divider: i > 0,
                removiendo: _removiendo == _colaboradores[i].codigo,
                cambiandoRol: _cambiandoRol == _colaboradores[i].codigo,
                onRemove: () => _remover(_colaboradores[i]),
                onRol: (rol) => _cambiarRol(_colaboradores[i], rol),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.people_outline, size: 15, color: AppColors.kTextPrimary),
            SizedBox(width: 6),
            _Titulo('Colaboradores actuales'),
          ],
        ),
        const SizedBox(height: 10),
        body,
      ],
    );
  }

  // ── Transferir ────────────────────────────────────────────────────────────

  Widget _transferirSection() {
    final List<Widget> contenido;
    if (!widget.menu.transferible) {
      contenido = [
        const _Aviso(
          icon: Icons.lock_outline,
          color: AppColors.kTextMuted,
          bg: Color(0xFFF8FAFC),
          border: AppColors.kCardBorder,
          text:
              'No se puede transferir en este momento: revisa que no tenga mesas con '
              'cuentas abiertas, pedidos sin resolver, ni cobro automático activo en la suscripción.',
        ),
      ];
    } else if (_transferPendiente != null) {
      contenido = [
        _AmberBox(
          title: 'Solicitud enviada',
          children: [
            Text(
              'Le enviamos una notificación a ${_nombre(_transferPendiente!, 'destino', 'el destinatario')}. '
              'Cuando acepte, pasará a ser el dueño del menú y tú quedarás como colaborador.',
              style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Si no acepta, el menú seguirá siendo tuyo.',
              style: TextStyle(fontSize: 12, color: Color(0xFFD97706)),
            ),
          ],
        ),
      ];
    } else {
      contenido = [
        const Text(
          'Transfiere la propiedad de este menú a otro usuario con su código. '
          'El destinatario recibirá una notificación y deberá aceptar. Al aceptar, quedas como colaborador.',
          style: TextStyle(fontSize: 12, color: AppColors.kTextMuted),
        ),
        const SizedBox(height: 12),
        if (!_confirmando)
          Row(
            children: [
              Expanded(
                child: _CodigoField(
                  controller: _codigoTransferCtrl,
                  focusColor: _kAmber,
                  onChanged: () => setState(() => _errorTransfer = ''),
                  onSubmitted: _iniciarTransferencia,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _codigoTransferCtrl.text.trim().length < 6
                    ? null
                    : _iniciarTransferencia,
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Transferir'),
                style: FilledButton.styleFrom(
                  backgroundColor: _kAmber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          )
        else
          _AmberBox(
            title: '¿Enviar solicitud de transferencia?',
            children: [
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB45309),
                  ),
                  children: [
                    const TextSpan(text: 'El usuario con código '),
                    TextSpan(
                      text: _codigoTransferCtrl.text.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(
                      text:
                          ' recibirá una notificación. Si acepta, pasará a ser el dueño y tú quedarás como colaborador.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _transfiriendo ? null : _confirmarTransferencia,
                    icon: _transfiriendo
                        ? const _Spinner(color: Colors.white)
                        : const Icon(Icons.swap_horiz, size: 15),
                    label: const Text('Sí, enviar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _transfiriendo
                        ? null
                        : () => setState(() {
                            _confirmando = false;
                            _errorTransfer = '';
                          }),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ],
          ),
        if (_errorTransfer.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ErrorText(_errorTransfer),
        ],
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.swap_horiz, size: 16, color: Color(0xFFD97706)),
            SizedBox(width: 6),
            _Titulo('Transferir menú'),
          ],
        ),
        const SizedBox(height: 8),
        ...contenido,
      ],
    );
  }
}

class _ColaboradorRow extends StatelessWidget {
  const _ColaboradorRow({
    required this.colaborador,
    required this.divider,
    required this.removiendo,
    required this.cambiandoRol,
    required this.onRemove,
    required this.onRol,
  });

  final Colaborador colaborador;
  final bool divider;
  final bool removiendo;
  final bool cambiandoRol;
  final VoidCallback onRemove;
  final ValueChanged<String> onRol;

  @override
  Widget build(BuildContext context) {
    final c = colaborador;
    final inicial = (c.nombre?.isNotEmpty == true ? c.nombre! : '?')[0]
        .toUpperCase();
    final repartidor = c.rol == 'repartidor';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: divider
            ? const Border(top: BorderSide(color: Color(0xFFF1F5F9)))
            : null,
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 36,
              height: 36,
              child: c.avatar != null && c.avatar!.isNotEmpty
                  ? Image.network(
                      c.avatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _Inicial(inicial),
                    )
                  : _Inicial(inicial),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              c.nombreCompleto.isEmpty ? 'Sin nombre' : c.nombreCompleto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.kTextPrimary,
              ),
            ),
          ),
          // Badge de rol; al tocarlo permite cambiarlo (PATCH .../rol).
          PopupMenuButton<String>(
            enabled: !cambiandoRol && !removiendo,
            tooltip: 'Cambiar rol',
            onSelected: onRol,
            itemBuilder: (_) => [
              for (final r in ColaboracionService.roles)
                CheckedPopupMenuItem(
                  value: r,
                  checked: r == c.rol,
                  child: Text(_rolLabel(r)),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: repartidor
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(99),
              ),
              child: cambiandoRol
                  ? const _Spinner(size: 10)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _rolLabel(c.rol),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: repartidor
                                ? const Color(0xFF475569)
                                : const Color(0xFF4338CA),
                          ),
                        ),
                        Icon(
                          Icons.expand_more,
                          size: 12,
                          color: repartidor
                              ? const Color(0xFF475569)
                              : const Color(0xFF4338CA),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 36,
            height: 36,
            child: removiendo
                ? const Center(child: _Spinner())
                : IconButton(
                    onPressed: onRemove,
                    tooltip: 'Eliminar colaborador',
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CodigoField extends StatelessWidget {
  const _CodigoField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    this.focusColor = AppColors.kBlue,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;
  final Color focusColor;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: 6,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
        _UpperCaseFormatter(),
      ],
      onChanged: (_) => onChanged(),
      onSubmitted: (_) => onSubmitted(),
      style: const TextStyle(
        fontFamily: 'monospace',
        letterSpacing: 4,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: 'ABCD12',
        counterText: '',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: focusColor, width: 1.5),
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.kTextPrimary,
    ),
  );
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: bg,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 12, color: color)),
        ),
      ],
    ),
  );
}

class _AmberBox extends StatelessWidget {
  const _AmberBox({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _kAmberBg,
      border: Border.all(color: _kAmberBorder),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 15, color: _kAmber),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kAmberDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...children,
      ],
    ),
  );
}

class _Caja extends StatelessWidget {
  const _Caja({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.kCardBorder),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Center(child: child),
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      color: _kRed,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _Inicial extends StatelessWidget {
  const _Inicial(this.letra);
  final String letra;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFE0E7FF),
    alignment: Alignment.center,
    child: Text(
      letra,
      style: const TextStyle(
        color: Color(0xFF4F46E5),
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    ),
  );
}

class _Spinner extends StatelessWidget {
  const _Spinner({this.size = 14, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(strokeWidth: 2, color: color),
  );
}
