import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_cache.dart';
import '../../shared/app_colors.dart';
import 'ajustes_service.dart';
import 'dispositivo_model.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  String? _codigoInv;
  List<Dispositivo> _dispositivos = [];
  bool _loadingDisp = true;
  bool _loadError = false;
  bool _copied = false;
  int? _revoking;

  @override
  void initState() {
    super.initState();
    // Mostrar cache al instante
    final cachedCodigo = AppCache.get<String>('ajustes_codigo_inv');
    final cachedDisp   = AppCache.get<List<Dispositivo>>('ajustes_dispositivos');
    if (cachedCodigo != null) _codigoInv = cachedCodigo;
    if (cachedDisp   != null) { _dispositivos = cachedDisp; _loadingDisp = false; }
    // Refrescar en segundo plano
    _bgFetch();
  }

  Future<void> _bgFetch() async {
    await Future.wait([_bgFetchCodigo(), _bgFetchDispositivos()]);
  }

  Future<void> _loadAll() => _bgFetch();

  Future<void> _bgFetchCodigo() async {
    final codigo = await AjustesService.getCodigoInv();
    if (!mounted) return;
    if (codigo != null) AppCache.set('ajustes_codigo_inv', codigo);
    setState(() => _codigoInv = codigo);
  }

  Future<void> _bgFetchDispositivos() async {
    final list = await AjustesService.getDispositivos();
    if (!mounted) return;
    AppCache.set('ajustes_dispositivos', list);
    setState(() { _dispositivos = list; _loadingDisp = false; });
  }

  Future<void> _recargarDisp() async {
    setState(() { _loadingDisp = true; _loadError = false; });
    await _bgFetchDispositivos();
  }

  Future<void> _copiarCodigo() async {
    if (_codigoInv == null) return;
    await Clipboard.setData(ClipboardData(text: _codigoInv!));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _revocar(int id) async {
    setState(() => _revoking = id);
    final ok = await AjustesService.revocarDispositivo(id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _dispositivos = _dispositivos.where((d) => d.id != id).toList();
        _revoking = null;
      });
    } else {
      setState(() => _revoking = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No se pudo cerrar esa sesión. Intenta de nuevo.'),
        backgroundColor: AppColors.kRed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgPage,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: AppColors.kBlue,
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildCodigoInv(),
            const SizedBox(height: 24),
            _buildSesionesHeader(),
            const SizedBox(height: 12),
            _buildSesiones(),
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
                const Icon(Icons.settings_outlined,
                    size: 18, color: AppColors.kBlue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ajustes',
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
    return const Text(
      'Gestiona tu cuenta y sesiones activas',
      style: TextStyle(fontSize: 12, color: AppColors.kTextMuted),
    );
  }

  // ── Código de invitación ───────────────────────────────────────────────────
  Widget _buildCodigoInv() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Código de invitación',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.kTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Comparte este código para que alguien te agregue como colaborador en uno de sus menús.',
          style: TextStyle(fontSize: 11, color: AppColors.kTextMuted, height: 1.4),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.kCardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: _codigoInv != null
                    ? Text(
                        _codigoInv!,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.kBlue,
                          letterSpacing: 5,
                          fontFamily: 'monospace',
                        ),
                      )
                    : Container(
                        height: 28,
                        width: 140,
                        decoration: BoxDecoration(
                          color: AppColors.kSkeleton,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
              ),
              if (_codigoInv != null)
                GestureDetector(
                  onTap: _copiarCodigo,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _copied
                          ? const Color(0xFFD1FAE5)
                          : AppColors.kSkeleton,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_outlined,
                          size: 13,
                          color: _copied
                              ? AppColors.kGreen
                              : AppColors.kTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copiado' : 'Copiar',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _copied
                                ? AppColors.kGreen
                                : AppColors.kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Sesiones — header ──────────────────────────────────────────────────────
  Widget _buildSesionesHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sesiones activas',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kTextPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Dispositivos con sesión iniciada',
                style: TextStyle(fontSize: 11, color: AppColors.kTextMuted),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded,
              size: 18, color: AppColors.kTextMuted),
          tooltip: 'Actualizar',
          onPressed: _recargarDisp,
        ),
      ],
    );
  }

  // ── Sesiones — lista ───────────────────────────────────────────────────────
  Widget _buildSesiones() {
    if (_loadingDisp) {
      return Column(
        children: List.generate(
          2,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.kSkeleton,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    if (_loadError) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.kRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              'No se pudieron cargar las sesiones.',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _recargarDisp,
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_dispositivos.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kCardBorder),
        ),
        child: const Center(
          child: Text(
            'No hay sesiones activas.',
            style: TextStyle(fontSize: 13, color: AppColors.kTextMuted),
          ),
        ),
      );
    }

    return Column(
      children: _dispositivos
          .map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DispositivoCard(
                  dispositivo: d,
                  revoking: _revoking == d.id,
                  onRevocar: () => _revocar(d.id),
                ),
              ))
          .toList(),
    );
  }
}

// ── Dispositivo card ──────────────────────────────────────────────────────────

class _DispositivoCard extends StatelessWidget {
  const _DispositivoCard({
    required this.dispositivo,
    required this.revoking,
    required this.onRevocar,
  });

  final Dispositivo dispositivo;
  final bool revoking;
  final VoidCallback onRevocar;

  @override
  Widget build(BuildContext context) {
    final d = dispositivo;
    final isEste = d.esEste;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEste ? const Color(0xFFEEF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEste ? const Color(0xFFC7D2FE) : AppColors.kCardBorder,
        ),
      ),
      child: Row(
        children: [
          // Ícono dispositivo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEste
                  ? const Color(0xFFE0E7FF)
                  : AppColors.kSkeleton,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              d.isMobile ? Icons.smartphone_outlined : Icons.computer_outlined,
              size: 20,
              color: isEste ? AppColors.kBlue : AppColors.kTextSecondary,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      d.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextPrimary,
                      ),
                    ),
                    if (isEste)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.kBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Este dispositivo',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    _StatusBadge(activo: d.navegando),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${d.ip ?? 'IP desconocida'} · Iniciado ${Dispositivo.formatDate(d.creadoEn)}',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.kTextMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Botón revocar (no en el dispositivo actual)
          if (!isEste) ...[
            const SizedBox(width: 8),
            revoking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.kRed),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.kTextMuted),
                    tooltip: 'Cerrar sesión en este dispositivo',
                    onPressed: onRevocar,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.activo});
  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: activo ? const Color(0xFFD1FAE5) : AppColors.kSkeleton,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            activo ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: 9,
            color: activo ? AppColors.kGreen : AppColors.kTextMuted,
          ),
          const SizedBox(width: 3),
          Text(
            activo ? 'Activo' : 'Inactivo',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: activo ? AppColors.kGreen : AppColors.kTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
