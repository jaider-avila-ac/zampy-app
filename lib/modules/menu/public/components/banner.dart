import 'package:flutter/material.dart' hide MenuTheme;
import '../models/public_menu_model.dart';

// Equivalente a src/components/Banner.jsx en React — layout móvil
// React: banner h-72, logo -mt-12 (Stack overlap), info centrada debajo

class Banner extends StatelessWidget {
  const Banner({super.key, required this.info, required this.theme});
  final MenuInfo  info;
  final MenuTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Banner + Logo en Stack (equivalente a -mt-12 de React) ───────
        Stack(
          clipBehavior: Clip.none,
          alignment:    Alignment.bottomCenter,
          children: [
            // Banner: h-72 igual que React móvil
            SizedBox(
              height: 288,
              width:  double.infinity,
              child:  _BannerImage(bannerUrl: info.bannerUrl, theme: theme),
            ),
            // Logo: mitad sobresale del banner — 132px → 66px fuera
            Positioned(
              bottom: -66,
              child: _Logo(logoUrl: info.logoUrl, name: info.name, theme: theme),
            ),
          ],
        ),

        // Espacio para el logo que sobresale (132px / 2 = 66px + 8px margen)
        const SizedBox(height: 74),

        // ── Info centrada debajo del logo ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            children: [
              Text(
                info.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight:  FontWeight.w900,
                  fontSize:    24,
                  letterSpacing: -0.5,
                  color:       theme.text,
                ),
              ),
              if (info.slogan != null && info.slogan!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  info.slogan!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: theme.textMuted),
                ),
              ],
              const SizedBox(height: 12),
              // Chips de contacto — solo los que el negocio tiene (igual que React)
              Wrap(
                alignment:  WrapAlignment.center,
                spacing:    6,
                runSpacing: 6,
                children: [
                  if (info.locationText.isNotEmpty)
                    _InfoChip(icon: Icons.public, text: info.locationText, theme: theme),
                  if (info.hasAddress)
                    _InfoChip(icon: Icons.location_on_outlined, text: info.address!, theme: theme),
                  if (info.hasSchedule)
                    _InfoChip(icon: Icons.access_time_outlined, text: info.schedule!, theme: theme),
                  if (info.hasWhatsapp || info.hasPhone)
                    _InfoChip(icon: Icons.phone_outlined, text: (info.whatsapp ?? info.phone)!, theme: theme),
                ],
              ),
              // Redes sociales — solo si el negocio las tiene (igual que React)
              if (info.hasInstagram || info.hasFacebook || info.hasTiktok || info.hasWebsite) ...[
                const SizedBox(height: 8),
                Wrap(
                  alignment:  WrapAlignment.center,
                  spacing:    6,
                  runSpacing: 6,
                  children: [
                    if (info.hasInstagram)
                      _SocialChip(label: 'Instagram', color: const Color(0xFFE1306C), theme: theme),
                    if (info.hasFacebook)
                      _SocialChip(label: 'Facebook', color: const Color(0xFF1877F2), theme: theme),
                    if (info.hasTiktok)
                      _SocialChip(label: 'TikTok', color: const Color(0xFF010101), theme: theme),
                    if (info.hasWebsite)
                      _SocialChip(label: 'Web', color: const Color(0xFF6366F1), theme: theme),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({this.bannerUrl, required this.theme});
  final String?   bannerUrl;
  final MenuTheme theme;

  @override
  Widget build(BuildContext context) {
    if (bannerUrl != null && bannerUrl!.isNotEmpty) {
      return Image.network(
        bannerUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (ctx, err, st) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primary,
              Color.alphaBlend(Colors.white.withValues(alpha: 0.3), theme.primary),
            ],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
          ),
        ),
      );
}

class _Logo extends StatelessWidget {
  const _Logo({this.logoUrl, required this.name, required this.theme});
  final String?   logoUrl;
  final String    name;
  final MenuTheme theme;

  @override
  Widget build(BuildContext context) => Container(
        width:  132,
        height: 132,
        decoration: BoxDecoration(
          shape:     BoxShape.circle,
          border:    Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: ClipOval(
          child: logoUrl != null && logoUrl!.isNotEmpty
              ? Image.network(
                  logoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => _initialsLogo(),
                )
              : _initialsLogo(),
        ),
      );

  Widget _initialsLogo() => Container(
        color: theme.primary,
        alignment: Alignment.center,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w900, fontSize: 46,
          ),
        ),
      );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text, required this.theme});
  final IconData  icon;
  final String    text;
  final MenuTheme theme;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:        theme.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: theme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: theme.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: TextStyle(fontSize: 11, color: theme.textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

class _SocialChip extends StatelessWidget {
  const _SocialChip({required this.label, required this.color, required this.theme});
  final String    label;
  final Color     color;
  final MenuTheme theme;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:        theme.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: theme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: theme.text,
              ),
            ),
          ],
        ),
      );
}
