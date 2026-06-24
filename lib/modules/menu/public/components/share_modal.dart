import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide MenuTheme;
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/public_menu_model.dart';

// Equivalente a src/modules/menu/public/components/ShareModal.jsx
// QR generado en el cliente (React usa react-qrcode-logo, nosotros usamos qr_flutter)

class ShareModal extends StatefulWidget {
  const ShareModal({
    super.key,
    required this.slug,
    required this.theme,
  });

  final String    slug;
  final MenuTheme theme;

  static Future<void> show(BuildContext context, String slug, MenuTheme theme) {
    return showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => ShareModal(slug: slug, theme: theme),
    );
  }

  @override
  State<ShareModal> createState() => _ShareModalState();
}

class _ShareModalState extends State<ShareModal> {
  bool _copied      = false;
  bool _downloading = false;

  // La clave para capturar el widget QR como imagen
  final _qrKey = GlobalKey();

  String get _shareUrl => 'https://app.zammpy.com/menu/${widget.slug}';

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _shareUrl));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _shareLink() async {
    await Share.share(_shareUrl, subject: 'Menú digital');
  }

  // Captura el widget QR y lo comparte como PNG — equivalente a downloadQR() en React
  Future<void> _downloadQr() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      // Renderiza el widget QR a imagen usando QrPainter
      final painter = QrPainter(
        data:    _shareUrl,
        version: QrVersions.auto,
        eyeStyle: const QrEyeStyle(
          eyeShape:  QrEyeShape.square,
          color:     Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color:           Colors.black,
        ),
      );
      final imageData = await painter.toImageData(600, format: ui.ImageByteFormat.png);
      if (imageData == null) throw Exception('No se pudo generar el QR');

      final tmp  = Directory.systemTemp;
      final file = File('${tmp.path}/qr-${widget.slug}.png');
      await file.writeAsBytes(imageData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'QR Menú digital',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo descargar el QR')),
        );
      }
    }
    if (mounted) setState(() => _downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;

    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color:        t.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Drag handle
              Center(
                child: Container(
                  width:  36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color:        t.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Text(
                    'Compartir menú',
                    style: TextStyle(
                      fontSize:   17,
                      fontWeight: FontWeight.w900,
                      color:      t.text,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width:  32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:        t.surfaceAlt,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.close, size: 16, color: t.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Botón compartir (sistema share sheet)
              _ActionButton(
                icon:  Icons.share_outlined,
                label: 'Compartir',
                bg:    t.primary,
                fg:    Colors.white,
                onTap: _shareLink,
              ),
              const SizedBox(height: 16),

              // QR Code generado en el cliente — React: <QRCode value={shareUrl} size={240} />
              Center(
                child: RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    width:   220,
                    height:  220,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:        Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data:            _shareUrl,
                      version:         QrVersions.auto,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color:    Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color:           Colors.black,
                      ),
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Descargar QR
              _ActionButton(
                icon:        _downloading ? null : Icons.download_outlined,
                label:       _downloading ? 'Generando...' : 'Descargar QR',
                bg:          t.surfaceAlt,
                fg:          t.text,
                onTap:       _downloading ? null : _downloadQr,
                loading:     _downloading,
                borderColor: t.border,
              ),
              const SizedBox(height: 12),

              // URL + Copiar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color:        t.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(color: t.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _shareUrl,
                        style: TextStyle(fontSize: 12, color: t.text),
                        maxLines:  1,
                        overflow:  TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _copyLink,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:        t.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _copied ? Icons.check : Icons.copy_outlined,
                              size:  14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _copied ? 'Copiado' : 'Copiar',
                              style: const TextStyle(
                                fontSize:   11,
                                fontWeight: FontWeight.w700,
                                color:      Colors.white,
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
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.icon,
    this.loading = false,
    this.borderColor,
  });

  final String      label;
  final Color       bg;
  final Color       fg;
  final VoidCallback? onTap;
  final IconData?   icon;
  final bool        loading;
  final Color?      borderColor;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height:    44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:        bg,
            borderRadius: BorderRadius.circular(12),
            border:       borderColor != null ? Border.all(color: borderColor!) : null,
          ),
          child: loading
              ? SizedBox(
                  width:  18,
                  height: 18,
                  child:  CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : Row(
                  mainAxisSize:      MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: fg),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w700,
                        color:      fg,
                      ),
                    ),
                  ],
                ),
        ),
      );
}
