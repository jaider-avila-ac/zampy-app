import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Pantalla interna que carga el flujo OAuth de Google.
///
/// El backend (Spring Boot) redirige al frontend React con los params:
///   ?token=xxx&userId=xxx&email=xxx&nombre=xxx&apellido=xxx&avatar=xxx
///
/// Interceptamos esa redirección ANTES de que el WebView navegue,
/// extraemos los datos y los retornamos con Navigator.pop().
///
/// Retorna `Map` con datos del usuario si hay éxito, o `null` si canceló/error.
class GoogleAuthWebView extends StatefulWidget {
  const GoogleAuthWebView({super.key, required this.authUrl});
  final String authUrl;

  @override
  State<GoogleAuthWebView> createState() => _GoogleAuthWebViewState();
}

class _GoogleAuthWebViewState extends State<GoogleAuthWebView> {
  late final WebViewController _ctrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: _handleNavigation,
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  NavigationDecision _handleNavigation(NavigationRequest req) {
    final url = req.url;

    // El backend redirige al frontend con token en query params
    if (url.contains('token=')) {
      final uri    = Uri.tryParse(url);
      final params = uri?.queryParameters ?? {};
      final token  = params['token'];

      if (token != null && token.isNotEmpty) {
        final userData = <String, dynamic>{
          'token':    token,
          'userId':   int.tryParse(params['userId'] ?? '') ?? 0,
          'email':    params['email']    ?? '',
          'nombre':   params['nombre']   ?? '',
          'apellido': params['apellido'] ?? '',
          'avatar':   params['avatar'],
        };
        Navigator.pop(context, userData);
      } else {
        Navigator.pop(context, null);
      }
      return NavigationDecision.prevent;
    }

    // Error de autenticación
    if (url.contains('error=true') || url.contains('/login?error')) {
      Navigator.pop(context, null);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1B4B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Continuar con Google',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, null),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _ctrl),
          if (_loading)
            Container(
              color: const Color(0xFF1E1B4B),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
