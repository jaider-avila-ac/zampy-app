import 'package:flutter/material.dart' hide MenuTheme;
import '../models/public_menu_model.dart';

// Equivalente a src/components/Footer.jsx en React
// Muestra logo, info, redes sociales y créditos del menú

class MenuFooter extends StatelessWidget {
  const MenuFooter({super.key, required this.info, required this.theme});
  final MenuInfo  info;
  final MenuTheme theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      decoration: BoxDecoration(
        color:  t.surface,
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Logo + nombre + slogan ───────────────────────────────────────
          Row(
            children: [
              _Avatar(info: info, theme: t),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize:   15,
                        color:      t.text,
                      ),
                    ),
                    if (info.slogan != null && info.slogan!.isNotEmpty)
                      Text(
                        info.slogan!,
                        style: TextStyle(fontSize: 11, color: t.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Info del negocio ─────────────────────────────────────────────
          if (info.locationText.isNotEmpty) ...[
            _InfoRow(icon: Icons.public, label: info.locationText, theme: t),
            const SizedBox(height: 8),
          ],
          if (info.hasAddress) ...[
            _InfoRow(icon: Icons.location_on_outlined, label: info.address!, theme: t),
            const SizedBox(height: 8),
          ],
          if (info.hasSchedule) ...[
            _InfoRow(icon: Icons.access_time_outlined, label: info.schedule!, theme: t),
            const SizedBox(height: 8),
          ],
          if (info.hasWhatsapp || info.hasPhone) ...[
            _InfoRow(
              icon:  Icons.phone_outlined,
              label: (info.whatsapp ?? info.phone)!,
              theme: t,
            ),
            const SizedBox(height: 8),
          ],

          // ── Botón "Cómo llegar" ──────────────────────────────────────────
          if (info.hasAddress) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:        t.surfaceAlt,
                  borderRadius: BorderRadius.circular(t.buttonRadius),
                  border:       Border.all(color: t.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.navigation_outlined, size: 13, color: t.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Cómo llegar',
                      style: TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w600,
                        color:      t.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Tags del negocio ─────────────────────────────────────────────
          if (info.tags.isNotEmpty) ...[
            Wrap(
              spacing:    8,
              runSpacing: 8,
              children: info.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:        t.surfaceAlt,
                  borderRadius: BorderRadius.circular(t.badgeRadius),
                  border:       Border.all(color: t.border),
                ),
                child: Text(tag, style: TextStyle(fontSize: 11, color: t.textMuted)),
              )).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // ── Redes sociales — solo las que el negocio tiene ───────────────
          if (info.hasInstagram || info.hasFacebook || info.hasWhatsapp ||
              info.hasTiktok    || info.hasWebsite) ...[
            Row(children: [
              Text('Síguenos:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.textMuted)),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing:    8,
              runSpacing: 8,
              children: [
                if (info.hasInstagram)
                  _SocialChip(label: 'Instagram', color: const Color(0xFFE1306C), theme: t),
                if (info.hasFacebook)
                  _SocialChip(label: 'Facebook',  color: const Color(0xFF1877F2), theme: t),
                if (info.hasWhatsapp)
                  _SocialChip(label: 'WhatsApp',  color: const Color(0xFF25D366), theme: t),
                if (info.hasTiktok)
                  _SocialChip(label: 'TikTok',    color: const Color(0xFF010101), theme: t),
                if (info.hasWebsite)
                  _SocialChip(label: 'Web',       color: const Color(0xFF6366F1), theme: t),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // ── Créditos Zammpy ──────────────────────────────────────────────
          Divider(color: t.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2026 Zammpy. Todos los derechos reservados.',
                style: TextStyle(fontSize: 10, color: t.textMuted),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:        t.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(t.badgeRadius),
                ),
                child: Text(
                  'Menú digital',
                  style: TextStyle(
                    fontSize:   10,
                    fontWeight: FontWeight.w600,
                    color:      t.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.info, required this.theme});
  final MenuInfo  info;
  final MenuTheme theme;

  @override
  Widget build(BuildContext context) {
    if (info.logoUrl != null && info.logoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          info.logoUrl!,
          width: 56, height: 56,
          fit: BoxFit.cover,
          errorBuilder: (ctx, e, st) => _initial(),
        ),
      );
    }
    return _initial();
  }

  Widget _initial() => Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: theme.primary, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          info.name.isNotEmpty ? info.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22,
          ),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.theme});
  final IconData  icon;
  final String    label;
  final MenuTheme theme;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 14, color: theme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 13, color: theme.textMuted)),
          ),
        ],
      );
}

class _SocialChip extends StatelessWidget {
  const _SocialChip({required this.label, required this.color, required this.theme});
  final String    label;
  final Color     color;
  final MenuTheme theme;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:        theme.surfaceAlt,
          borderRadius: BorderRadius.circular(theme.buttonRadius),
          border:       Border.all(color: theme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      theme.text,
              ),
            ),
          ],
        ),
      );
}
