import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/app_header.dart';

// Equivalente a src/modules/about/pages/AboutPage.jsx en React

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _goBack(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      GoRouter.of(context).pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => _goBack(context),
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppHeader(title: 'Acerca de'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ── Logo ────────────────────────────────────────────────────────
            SvgPicture.asset(
              'assets/logos/imagotipo-indigo-zammpy.svg',
              height: 28,
              colorFilter: const ColorFilter.mode(
                  Color(0xFF4A37F2), BlendMode.srcIn),
            ),

            const SizedBox(height: 32),

            // ── Descripción ─────────────────────────────────────────────────
            _Paragraph(
              'Zammpy nació de una necesidad real que vimos una y otra vez: '
              'restaurantes y negocios que debían actualizar constantemente sus '
              'menús, promociones e información, pero dependían de procesos lentos, '
              'costosos o poco prácticos.',
            ),
            const SizedBox(height: 16),
            _Paragraph(
              'Creemos que la presencia digital ya no es un lujo, sino una necesidad, '
              'y que las experiencias interactivas pueden ayudar a los negocios a '
              'conectar mejor con sus clientes.',
            ),
            const SizedBox(height: 16),
            _Paragraph(
              'Zammpy es una plataforma sencilla, moderna y flexible para gestionar '
              'menús digitales y experiencias interactivas sin complicaciones.',
            ),

            const SizedBox(height: 40),

            // ── Creadores ───────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  // Fotos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CreadorAvatar(asset: 'assets/creadores/jaider-avila.png', name: 'Jaider Ávila'),
                      const SizedBox(width: 16),
                      _CreadorAvatar(asset: 'assets/creadores/juan-pablo-perez.png', name: 'Juan Pablo Pérez'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Nombres y títulos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _CreadorInfo(nombre: 'Jaider Ávila',       titulo: 'Ingeniero de Sistemas'),
                      SizedBox(width: 48),
                      _CreadorInfo(nombre: 'Juan Pablo Pérez',   titulo: 'Ingeniero de Sistemas'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Quote
                  const Text(
                    '"Construyendo con insomnio y café."',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(color: Color(0xFFF1F5F9)),
            const SizedBox(height: 24),

            // ── Contacto ────────────────────────────────────────────────────
            _ContactRow(
              icon: Icons.phone_outlined,
              label: '+57 350 200 6159',
              onTap: () => _launch('tel:+573502006159'),
            ),
            const SizedBox(height: 20),
            _ContactRow(
              icon: Icons.mail_outline,
              label: 'zammpy.software@gmail.com',
              onTap: () => _launch('mailto:zammpy.software@gmail.com'),
            ),
            const SizedBox(height: 20),
            _ContactRow(
              icon: Icons.language_outlined,
              label: 'zammpy.com',
              onTap: () => _launch('https://zammpy.com'),
            ),

            const SizedBox(height: 32),
            const Divider(color: Color(0xFFF1F5F9)),
            const SizedBox(height: 20),

            // ── Legal ────────────────────────────────────────────────────────
            Row(
              children: [
                _LegalLink(
                  label: 'Términos y Condiciones',
                  onTap: () => _launch('https://zammpy.com/terminos'),
                ),
                const SizedBox(width: 20),
                _LegalLink(
                  label: 'Política de Privacidad',
                  onTap: () => _launch('https://zammpy.com/privacidad'),
                ),
              ],
            ),
          ],
        ),
      ),
      ),  // Scaffold
    );    // PopScope
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF475569),
            height: 1.6),
      );
}

class _CreadorAvatar extends StatelessWidget {
  const _CreadorAvatar({required this.asset, required this.name});
  final String asset;
  final String name;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 6),
          ],
        ),
        child: CircleAvatar(
          radius: 32,
          backgroundImage: AssetImage(asset),
        ),
      );
}

class _CreadorInfo extends StatelessWidget {
  const _CreadorInfo({required this.nombre, required this.titulo});
  final String nombre;
  final String titulo;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(nombre,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(titulo,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      );
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.label, required this.onTap});
  final IconData   icon;
  final String     label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF475569))),
          ],
        ),
      );
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});
  final String     label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF94A3B8))),
      );
}
