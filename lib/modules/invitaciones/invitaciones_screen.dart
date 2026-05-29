import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_cache.dart';
import '../../shared/app_colors.dart';
import '../auth/auth_service.dart';
import 'invitacion_model.dart';
import 'invitacion_service.dart';

class InvitacionesScreen extends StatefulWidget {
  const InvitacionesScreen({super.key});

  @override
  State<InvitacionesScreen> createState() => _InvitacionesScreenState();
}

class _InvitacionesScreenState extends State<InvitacionesScreen> {
  InvitacionEstado? _estado;
  bool _loading = true;
  bool _toggling = false;
  bool _copied = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final cached = AppCache.get<InvitacionEstado>('invitacion_estado');
    if (cached != null) { _estado = cached; _loading = false; }
    _bgFetch();
  }

  Future<void> _bgFetch() async {
    final data = await InvitacionService.getEstado();
    if (!mounted) return;
    if (data != null) AppCache.set('invitacion_estado', data);
    setState(() {
      _estado = data;
      _loading = false;
      _error = data == null && _estado == null
          ? 'No se pudo cargar el estado de invitaciones'
          : '';
    });
  }

  Future<void> _load() => _bgFetch();

  String get _enlace {
    if (_estado == null || _estado!.codigoInv.isEmpty) return '';
    return '$kApiBase/invite/${_estado!.codigoInv}';
  }

  Future<void> _handleCopy() async {
    if (_enlace.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _enlace));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _handleToggle() async {
    setState(() { _toggling = true; _error = ''; });
    final nuevoActivo = await InvitacionService.toggleActivo();
    if (!mounted) return;
    if (nuevoActivo == null) {
      setState(() { _error = 'No se pudo cambiar el estado del enlace'; _toggling = false; });
      return;
    }
    setState(() {
      _estado = _estado?.copyWith(invActivo: nuevoActivo);
      _toggling = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgPage,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: AppColors.kBlue,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            if (_loading) _buildLoader(),
            if (!_loading && _error.isNotEmpty) _buildError(),
            if (!_loading && _estado != null) ...[
              _buildStats(),
              const SizedBox(height: 16),
              _buildEnlaceCard(),
              const SizedBox(height: 16),
              _buildComoFunciona(),
            ],
          ],
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.kCardBorder)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      size: 20, color: AppColors.kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
                const Icon(Icons.people_outline,
                    size: 18, color: AppColors.kBlue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Invitaciones',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Encabezado ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invita personas y gana días gratis al completar logros',
          style: TextStyle(fontSize: 12, color: AppColors.kTextMuted, height: 1.4),
        ),
      ],
    );
  }

  // ── Loader ─────────────────────────────────────────────────────────────────
  Widget _buildLoader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: AppColors.kBlue),
        ),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.kRed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _error,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  // ── Estadísticas ───────────────────────────────────────────────────────────
  Widget _buildStats() {
    return Row(
      children: [
        Expanded(child: _StatCard(
          icon: Icons.person_outline,
          value: _estado!.completadas,
          label: 'Completadas',
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          icon: Icons.access_time_outlined,
          value: _estado!.pendientes,
          label: 'Pendientes',
        )),
      ],
    );
  }

  // ── Tarjeta del enlace ─────────────────────────────────────────────────────
  Widget _buildEnlaceCard() {
    final activo = _estado!.invActivo;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + badge estado
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tu enlace de invitación',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: activo ? AppColors.kGreen : AppColors.kTextMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  activo ? 'Activo' : 'Inactivo',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Enlace + botón copiar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.kBgPage,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.kCardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _enlace,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.kTextSecondary,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _handleCopy,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _copied ? Icons.check_rounded : Icons.copy_outlined,
                      size: 16,
                      color: _copied ? AppColors.kGreen : AppColors.kTextMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Botón toggle
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _toggling ? null : _handleToggle,
              icon: _toggling
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.power_settings_new_rounded, size: 14),
              label: Text(
                _toggling
                    ? 'Cambiando…'
                    : activo
                        ? 'Desactivar enlace'
                        : 'Activar enlace',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    activo ? AppColors.kSkeleton : AppColors.kBlue,
                foregroundColor:
                    activo ? AppColors.kTextPrimary : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Nota explicativa
          Text(
            activo
                ? 'El enlace está activo. Los registros a través de él serán rastreados. Desactivar no afecta las invitaciones ya en progreso.'
                : 'El enlace está inactivo. Los registros desde él no contarán. Desactivar no afecta las invitaciones ya en progreso.',
            style: const TextStyle(
                fontSize: 11, color: AppColors.kTextMuted, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Cómo funciona ──────────────────────────────────────────────────────────
  Widget _buildComoFunciona() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CÓMO FUNCIONA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.kTextMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ..._pasos.asMap().entries.map((e) => Padding(
                padding: EdgeInsets.only(
                    bottom: e.key < _pasos.length - 1 ? 10 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.kBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.kTextSecondary,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static const _pasos = [
    'Comparte tu enlace con quien quieras.',
    'Cuando se registren, quedan vinculados a tu código.',
    'Una invitación se completa cuando el invitado reacciona a 3 menús distintos.',
    'Cada invitación completada cuenta para desbloquear logros y ganar días gratis.',
  ];
}

// ── StatCard ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.kBlue),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.kTextPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.kTextMuted),
          ),
        ],
      ),
    );
  }
}
