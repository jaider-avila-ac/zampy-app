import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/suscripcion_service.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/wompi_card_form.dart';

// Equivalente a src/modules/subscription/components/AutoChargeSection.jsx en React.
// Guardar tarjeta (tokenizada directamente en Wompi), activar/desactivar el cobro
// automático y eliminar la tarjeta. Nuestro código nunca guarda datos de la tarjeta.

enum _Paso { idle, cargandoTerminos, terminos, guardando, listo }

String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

class AutoChargeSection extends StatefulWidget {
  const AutoChargeSection({
    super.key,
    required this.sus,
    required this.onRefresh,
    this.forceExpand = false,
  });

  final Map<String, dynamic> sus;
  final Future<void> Function() onRefresh;
  final bool forceExpand;

  /// Solo planes pagos en estados donde tiene sentido renovar.
  static bool aplica(Map<String, dynamic>? sus) =>
      sus != null &&
      sus['tipoPlan'] != 'trial' &&
      const ['ACTIVE', 'PAYMENT_REMINDER', 'PAST_DUE'].contains(sus['estado']);

  @override
  State<AutoChargeSection> createState() => _AutoChargeSectionState();
}

class _AutoChargeSectionState extends State<AutoChargeSection> {
  bool _expanded = false;
  _Paso _paso = _Paso.idle;
  Map<String, dynamic>? _tokens;
  bool _aceptaTerminos = false;
  bool _aceptaDatos = false;
  bool _toggling = false;
  bool _deleting = false;
  String? _error;

  String get _susId => widget.sus['id']?.toString() ?? '';
  bool get _hayTarjeta => widget.sus['tieneTarjetaGuardada'] == true;
  bool get _cobroActivo => widget.sus['cobroAuto'] == true;

  @override
  void initState() {
    super.initState();
    _expanded = widget.forceExpand;
  }

  @override
  void didUpdateWidget(covariant AutoChargeSection old) {
    super.didUpdateWidget(old);
    if (widget.forceExpand && !old.forceExpand) _expanded = true;
  }

  Future<void> _iniciarGuardarTarjeta() async {
    setState(() {
      _error = null;
      _paso = _Paso.cargandoTerminos;
    });
    try {
      final data = await SuscripcionService.getAcceptanceTokens();
      if (!mounted) return;
      setState(() {
        _tokens = data;
        _aceptaTerminos = false;
        _aceptaDatos = false;
        _paso = _Paso.terminos;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'No se pudieron cargar los términos de Wompi. Intenta de nuevo.';
        _paso = _Paso.idle;
      });
    }
  }

  Future<void> _onToken(String cardToken) async {
    setState(() {
      _paso = _Paso.guardando;
      _error = null;
    });
    try {
      await SuscripcionService.guardarFuentePago(
        _susId,
        cardToken,
        _tokens?['acceptanceToken']?.toString() ?? '',
        _tokens?['personalAuthToken']?.toString() ?? '',
      );
      if (!mounted) return;
      setState(() => _paso = _Paso.listo);
      await widget.onRefresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _msg(e).isEmpty
            ? 'No se pudo guardar la tarjeta. Intenta de nuevo.'
            : _msg(e);
        _paso = _Paso.terminos;
      });
    }
  }

  Future<void> _toggle() async {
    setState(() {
      _error = null;
      _toggling = true;
    });
    try {
      await SuscripcionService.toggleCobroAuto(_susId, !_cobroActivo);
      await widget.onRefresh();
    } catch (e) {
      if (mounted) setState(() => _error = _msg(e));
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _eliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarjeta'),
        content: const Text(
          '¿Eliminar la tarjeta guardada y desactivar el cobro automático?',
        ),
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
    if (ok != true || !mounted) return;
    setState(() {
      _error = null;
      _deleting = true;
    });
    try {
      await SuscripcionService.eliminarFuentePago(_susId);
      if (mounted) setState(() => _paso = _Paso.idle);
      await widget.onRefresh();
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo eliminar la tarjeta.');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subLabel = _cobroActivo
        ? 'Activo — se cobra automáticamente al vencer'
        : _hayTarjeta
        ? 'Desactivado — tarjeta guardada disponible'
        : 'Sin tarjeta guardada';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.autorenew,
                    size: 17,
                    color: _cobroActivo
                        ? const Color(0xFF4F46E5)
                        : AppColors.kTextMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Renovación automática',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kTextPrimary,
                          ),
                        ),
                        Text(
                          subLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _cobroActivo
                          ? const Color(0xFFEEF2FF)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      _cobroActivo ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _cobroActivo
                            ? const Color(0xFF4338CA)
                            : AppColors.kTextSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.kTextMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _contenido(),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _contenido() {
    const small = TextStyle(fontSize: 12, color: AppColors.kTextSecondary);
    return [
      if (_error != null) ...[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _error!,
            style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
          ),
        ),
        const SizedBox(height: 10),
      ],
      if (_hayTarjeta) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: AppColors.kCardBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.credit_card,
                size: 16,
                color: AppColors.kTextMuted,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tarjeta guardada',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextPrimary,
                      ),
                    ),
                    Text(
                      'Registrada en Wompi para cobros automáticos',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.kTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _deleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      tooltip: 'Eliminar tarjeta',
                      onPressed: _eliminar,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.kTextMuted,
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
      if (_paso == _Paso.idle && _hayTarjeta) ...[
        _cobroActivo
            ? OutlinedButton.icon(
                onPressed: _toggling ? null : _toggle,
                icon: _spinnerOr(Icons.autorenew, dark: true),
                label: const Text('Desactivar cobro automático'),
              )
            : FilledButton.icon(
                onPressed: _toggling ? null : _toggle,
                icon: _spinnerOr(Icons.autorenew),
                label: const Text('Activar cobro automático'),
              ),
        TextButton(
          onPressed: _iniciarGuardarTarjeta,
          child: const Text('Cambiar tarjeta', style: TextStyle(fontSize: 12)),
        ),
      ],
      if (_paso == _Paso.idle && !_hayTarjeta) ...[
        const Text(
          'Con la renovación automática, Zammpy cobra tu suscripción sin que tengas '
          'que hacerlo manualmente. Puedes cancelarla en cualquier momento.',
          style: small,
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _iniciarGuardarTarjeta,
          icon: const Icon(Icons.credit_card, size: 16),
          label: const Text('Guardar tarjeta y activar cobro automático'),
        ),
      ],
      if (_paso == _Paso.cargandoTerminos)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      if (_paso == _Paso.terminos && _tokens != null) ..._terminos(small),
      if (_paso == _Paso.guardando)
        const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Guardando tarjeta y activando cobro automático…',
                style: TextStyle(fontSize: 12, color: AppColors.kTextSecondary),
              ),
            ),
          ],
        ),
      if (_paso == _Paso.listo)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.check, size: 16, color: Color(0xFF4338CA)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '¡Listo! Tu tarjeta fue guardada y el cobro automático está activo.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF4338CA)),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _terminos(TextStyle small) {
    final t = _tokens!;
    return [
      const Text(
        'Para guardar tu tarjeta, acepta los términos de Wompi e ingresa los datos. '
        'La tarjeta se envía directamente a Wompi: nosotros nunca vemos sus datos.',
        style: TextStyle(fontSize: 12, color: AppColors.kTextSecondary),
      ),
      const SizedBox(height: 8),
      _Check(
        value: _aceptaTerminos,
        onChanged: (v) => setState(() => _aceptaTerminos = v),
        texto: 'Acepto los ',
        enlace: 'términos y condiciones de Wompi',
        url: t['acceptancePermalink']?.toString(),
      ),
      _Check(
        value: _aceptaDatos,
        onChanged: (v) => setState(() => _aceptaDatos = v),
        texto: 'Autorizo el ',
        enlace: 'tratamiento de mis datos personales',
        url: t['personalAuthPermalink']?.toString(),
      ),
      const SizedBox(height: 8),
      if (_aceptaTerminos && _aceptaDatos)
        WompiCardForm(
          wompiBaseUrl:
              t['wompiBaseUrl']?.toString() ?? 'https://production.wompi.co/v1',
          publicKey: t['publicKey']?.toString() ?? '',
          onToken: _onToken,
          loading: false,
        )
      else
        const Text(
          'Acepta los términos para continuar.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.kTextMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      TextButton(
        onPressed: () => setState(() {
          _paso = _Paso.idle;
          _tokens = null;
        }),
        child: Text('Cancelar', style: small),
      ),
    ];
  }

  Widget _spinnerOr(IconData icon, {bool dark = false}) => _toggling
      ? SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: dark ? AppColors.kBlue : Colors.white,
          ),
        )
      : Icon(icon, size: 15);
}

class _Check extends StatelessWidget {
  const _Check({
    required this.value,
    required this.onChanged,
    required this.texto,
    required this.enlace,
    required this.url,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String texto;
  final String enlace;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          visualDensity: VisualDensity.compact,
          activeColor: AppColors.kBlue,
        ),
        Expanded(
          child: Wrap(
            children: [
              GestureDetector(
                onTap: () => onChanged(!value),
                child: Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.kTextSecondary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: url == null || url!.isEmpty
                    ? null
                    : () => launchUrl(
                        Uri.parse(url!),
                        mode: LaunchMode.externalApplication,
                      ),
                child: Text(
                  enlace,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.kBlue,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.kBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
