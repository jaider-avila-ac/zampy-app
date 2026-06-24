import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../services/suscripcion_service.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/wompi_card_form.dart';

// Equivalente a src/modules/subscription/pages/CheckoutPage.jsx en React
// Steps: select → card-loading-terms → card-terms → processing → success/pending/declined
// "Otros métodos" abre checkoutUrl en WebView en-app.

enum _Step {
  select,
  cardLoadingTerms,
  cardTerms,
  processing,
  success,
  pending,
  declined,
  webView,
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.menuId,
    required this.tipo,
    this.plan,
  });

  final int    menuId;
  final String tipo;   // checkout | renovacion | upgrade
  final String? plan;  // código de plan (ej. 'basic', 'premium')

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  _Step _step = _Step.select;

  // Acceptance tokens (Wompi)
  Map<String, dynamic>? _tokens;
  bool _acceptedTerms  = false;
  bool _acceptedPersonal = false;

  // Resultado del pago con tarjeta
  String? _resultMensaje;

  // URL para WebView (otros métodos)
  String? _checkoutUrl;

  // Error en cualquier paso
  String _error = '';

  // ── Carga acceptance tokens para tarjeta ─────────────────────────────────
  Future<void> _loadCardTerms() async {
    setState(() { _step = _Step.cardLoadingTerms; _error = ''; });
    try {
      final tokens = await SuscripcionService.getAcceptanceTokens();
      if (!mounted) return;
      setState(() {
        _tokens            = tokens;
        _acceptedTerms     = false;
        _acceptedPersonal  = false;
        _step              = _Step.cardTerms;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _step = _Step.select; });
    }
  }

  // ── Pago con tarjeta (tras tokenizar en WompiCardForm) ────────────────────
  Future<void> _onCardToken(String cardToken) async {
    if (_tokens == null) return;
    setState(() { _step = _Step.processing; _error = ''; });
    try {
      final result = await SuscripcionService.pagarConTarjeta(
        widget.menuId,
        tipoPlan:          widget.plan ?? '',
        cardToken:         cardToken,
        acceptanceToken:   _tokens!['acceptanceToken'] as String,
        personalAuthToken: _tokens!['personalAuthToken'] as String,
      );
      if (!mounted) return;
      final status = result['status'] as String? ?? '';
      setState(() {
        _resultMensaje = result['mensaje'] as String?;
        _step = switch (status) {
          'APPROVED' => _Step.success,
          'PENDING'  => _Step.pending,
          _          => _Step.declined,
        };
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _resultMensaje = e.toString().replaceFirst('Exception: ', '');
          _step          = _Step.declined;
        });
      }
    }
  }

  // ── Otros métodos (PSE, Nequi, Daviplata) ────────────────────────────────
  Future<void> _iniciarOtrosMetodos() async {
    setState(() { _error = ''; });
    try {
      final Map<String, dynamic> result;
      switch (widget.tipo) {
        case 'checkout':
          result = await SuscripcionService.iniciarCheckout(widget.menuId, widget.plan);
        case 'upgrade':
          result = await SuscripcionService.iniciarUpgrade(widget.menuId);
        default:
          result = await SuscripcionService.iniciarPago(widget.menuId);
      }
      final url = result['checkoutUrl'] as String?;
      if (url == null || url.isEmpty) throw Exception('No se recibió URL de pago');
      if (!mounted) return;
      setState(() { _checkoutUrl = url; _step = _Step.webView; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _step == _Step.webView ? null : AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        leading: _step == _Step.success
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _handleBack,
              ),
      ),
      body: switch (_step) {
        _Step.select           => _SelectStep(
            tipo:              widget.tipo,
            plan:              widget.plan,
            error:             _error,
            onTarjeta:         _loadCardTerms,
            onOtrosMetodos:    _iniciarOtrosMetodos,
          ),
        _Step.cardLoadingTerms => const Center(child: CircularProgressIndicator()),
        _Step.cardTerms        => _CardTermsStep(
            tokens:            _tokens!,
            acceptedTerms:     _acceptedTerms,
            acceptedPersonal:  _acceptedPersonal,
            onTermsChanged:    (v) => setState(() => _acceptedTerms    = v),
            onPersonalChanged: (v) => setState(() => _acceptedPersonal = v),
            onToken:           _onCardToken,
            canProceed:        _acceptedTerms && _acceptedPersonal,
          ),
        _Step.processing       => _ProcessingStep(),
        _Step.success          => _ResultStep(
            icon:    Icons.check_circle_outline,
            color:   const Color(0xFF16A34A),
            title:   '¡Pago aprobado!',
            message: _resultMensaje ?? 'Tu suscripción ha sido activada.',
            onAction: () => context.go('/menus/${widget.menuId}/edit'),
            actionLabel: 'Ir al editor',
          ),
        _Step.pending          => _ResultStep(
            icon:    Icons.access_time,
            color:   const Color(0xFFB45309),
            title:   'Pago pendiente',
            message: _resultMensaje ?? 'Estamos verificando tu pago. Te notificaremos cuando se confirme.',
            onAction: () => context.go('/menus/${widget.menuId}/edit'),
            actionLabel: 'Ir al editor',
          ),
        _Step.declined         => _ResultStep(
            icon:    Icons.cancel_outlined,
            color:   const Color(0xFFDC2626),
            title:   'Pago rechazado',
            message: _resultMensaje ?? 'El pago no pudo procesarse. Intenta con otra tarjeta.',
            onAction: () => setState(() { _step = _Step.select; _error = ''; }),
            actionLabel: 'Intentar de nuevo',
          ),
        _Step.webView          => _WebViewStep(
            url:      _checkoutUrl!,
            menuId:   widget.menuId,
            onClose:  () => context.go('/menus/${widget.menuId}/edit'),
            onResult: (susId) {
              if (susId != null) {
                context.go('/billing/sus/$susId');
              } else {
                // Wompi redirigió pero no sabemos el susId → recargar SuscripcionPage
                context.go('/billing/${widget.menuId}');
              }
            },
          ),
      },
    );
  }

  void _handleBack() {
    switch (_step) {
      case _Step.cardTerms:
        setState(() => _step = _Step.select);
      case _Step.declined:
        setState(() => _step = _Step.select);
      default:
        context.pop();
    }
  }
}

// ── Step: seleccionar método de pago ─────────────────────────────────────────
class _SelectStep extends StatelessWidget {
  const _SelectStep({
    required this.tipo,
    required this.plan,
    required this.error,
    required this.onTarjeta,
    required this.onOtrosMetodos,
  });

  final String   tipo;
  final String?  plan;
  final String   error;
  final VoidCallback onTarjeta;
  final VoidCallback onOtrosMetodos;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.lock_outline, size: 36, color: AppColors.kBlue),
        const SizedBox(height: 14),
        const Text(
          'Selecciona cómo quieres pagar',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Elige el método de pago que prefieras',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 30),

        // Tarjeta débito/crédito
        _MethodCard(
          icon: Icons.credit_card_outlined,
          title: 'Tarjeta débito o crédito',
          subtitle: 'Visa, Mastercard, American Express',
          onTap: onTarjeta,
        ),
        const SizedBox(height: 12),

        // Otros métodos
        _MethodCard(
          icon: Icons.account_balance_outlined,
          title: 'PSE, Nequi, Daviplata y más',
          subtitle: 'Serás redirigido a la pasarela de pago',
          onTap: onOtrosMetodos,
        ),

        if (error.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ErrorBanner(error: error),
        ],

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 12, color: Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            const Text('Pago seguro · Powered by Wompi',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData     icon;
  final String       title;
  final String       subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.kBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

// ── Step: términos + formulario tarjeta ───────────────────────────────────────
class _CardTermsStep extends StatelessWidget {
  const _CardTermsStep({
    required this.tokens,
    required this.acceptedTerms,
    required this.acceptedPersonal,
    required this.onTermsChanged,
    required this.onPersonalChanged,
    required this.onToken,
    required this.canProceed,
  });

  final Map<String, dynamic> tokens;
  final bool acceptedTerms;
  final bool acceptedPersonal;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onPersonalChanged;
  final void Function(String) onToken;
  final bool canProceed;

  @override
  Widget build(BuildContext context) {
    final permalink         = tokens['acceptancePermalink'] as String? ?? '';
    final personalPermalink = tokens['personalAuthPermalink'] as String? ?? '';
    final wompiBase         = tokens['wompiBaseUrl'] as String? ?? 'https://api.wompi.co/v1';
    final publicKey         = tokens['publicKey'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Términos y condiciones',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        const SizedBox(height: 16),

        // Términos Wompi
        _TermsCheck(
          checked: acceptedTerms,
          onChanged: onTermsChanged,
          text: 'Acepto los ',
          linkText: 'términos y condiciones de Wompi',
          linkUrl: permalink,
        ),
        const SizedBox(height: 10),

        // Datos personales
        _TermsCheck(
          checked: acceptedPersonal,
          onChanged: onPersonalChanged,
          text: 'Autorizo el ',
          linkText: 'tratamiento de datos personales',
          linkUrl: personalPermalink,
        ),

        const SizedBox(height: 24),
        const Divider(color: Color(0xFFE2E8F0)),
        const SizedBox(height: 20),

        const Text('Datos de la tarjeta',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        const SizedBox(height: 16),

        WompiCardForm(
          wompiBaseUrl: wompiBase,
          publicKey:    publicKey,
          onToken:      onToken,
          loading:      !canProceed,
        ),
      ],
    );
  }
}

class _TermsCheck extends StatelessWidget {
  const _TermsCheck({
    required this.checked,
    required this.onChanged,
    required this.text,
    required this.linkText,
    required this.linkUrl,
  });

  final bool     checked;
  final ValueChanged<bool> onChanged;
  final String   text;
  final String   linkText;
  final String   linkUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: checked,
          onChanged: (v) => onChanged(v ?? false),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeColor: AppColors.kBlue,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!checked),
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  children: [
                    TextSpan(text: text),
                    TextSpan(
                      text: linkText,
                      style: const TextStyle(
                          color: AppColors.kBlue,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.kBlue),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Step: procesando ─────────────────────────────────────────────────────────
class _ProcessingStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Procesando pago...',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          ],
        ),
      );
}

// ── Step: resultado (success / pending / declined) ────────────────────────────
class _ResultStep extends StatelessWidget {
  const _ResultStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.onAction,
    required this.actionLabel,
  });

  final IconData     icon;
  final Color        color;
  final String       title;
  final String       message;
  final VoidCallback onAction;
  final String       actionLabel;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: color),
              const SizedBox(height: 20),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 10),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(actionLabel,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Step: WebView (PSE, Nequi, etc.) ─────────────────────────────────────────
class _WebViewStep extends StatefulWidget {
  const _WebViewStep({
    required this.url,
    required this.menuId,
    required this.onClose,
    required this.onResult,
  });
  final String url;
  final int    menuId;
  final VoidCallback onClose;
  // susId si Wompi redirigió a /billing/sus/{susId}, null si cerró sin resultado
  final void Function(int? susId) onResult;

  @override
  State<_WebViewStep> createState() => _WebViewStepState();
}

class _WebViewStepState extends State<_WebViewStep> {
  late final WebViewController _controller;
  bool _pageLoading = true;

  // El backend configura como redirectUrl de Wompi: https://app.zammpy.com/billing/...
  // El WebView navega libremente (PSE redirige al banco y de vuelta, etc.).
  // Solo cuando llega a app.zammpy.com sabemos que Wompi terminó → cerramos.
  static bool _esRedirectApp(String url) {
    try {
      return Uri.parse(url).host == 'app.zammpy.com';
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _pageLoading = true),
        onPageFinished: (_) => setState(() => _pageLoading = false),
        onNavigationRequest: (request) {
          // Wompi redirigió de vuelta a la web app → cerramos WebView
          if (_esRedirectApp(request.url)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) widget.onResult(null);
            });
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pago seguro',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
        bottom: _pageLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

// ── Banner de error ──────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 14, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(error,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B))),
            ),
          ],
        ),
      );
}
