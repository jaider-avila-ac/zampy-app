import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'app_colors.dart';

// Equivalente a CropModal.jsx en React:
// Ventana de recorte circular 1:1 con drag + slider de zoom.
// Devuelve un File PNG cuadrado (máx 512×512).

const _kCropSize = 280.0;

Future<File?> showLogoCropDialog(BuildContext context, File imageFile) =>
    showDialog<File>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LogoCropDialog(imageFile: imageFile),
    );

class _LogoCropDialog extends StatefulWidget {
  const _LogoCropDialog({required this.imageFile});
  final File imageFile;

  @override
  State<_LogoCropDialog> createState() => _LogoCropDialogState();
}

class _LogoCropDialogState extends State<_LogoCropDialog> {
  ui.Image? _uiImage;
  Size   _imageSize = const Size(1, 1);
  double _minZoom   = 1.0;
  double _maxZoom   = 4.0;
  double _zoom      = 1.0;
  Offset _offset    = Offset.zero;
  bool   _saving    = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final w   = img.width.toDouble();
    final h   = img.height.toDouble();
    final mz  = _kCropSize / min(w, h);
    final mxz = min(mz * 4, 12.0);
    if (!mounted) return;
    setState(() {
      _uiImage    = img;
      _imageSize  = Size(w, h);
      _minZoom    = mz;
      _maxZoom    = mxz;
      _zoom       = mz;
      _offset     = Offset.zero;
    });
  }

  Offset _clamp(Offset o, double z) {
    final ex = max(0.0, (_imageSize.width  * z - _kCropSize) / 2);
    final ey = max(0.0, (_imageSize.height * z - _kCropSize) / 2);
    return Offset(o.dx.clamp(-ex, ex), o.dy.clamp(-ey, ey));
  }

  void _onPan(Offset delta) =>
      setState(() => _offset = _clamp(_offset + delta, _zoom));

  void _onZoomSlider(double value) => setState(() {
    _zoom   = value;
    _offset = _clamp(_offset, _zoom);
  });

  Future<void> _confirm() async {
    final img = _uiImage;
    if (img == null) return;
    setState(() => _saving = true);

    final nw      = img.width.toDouble();
    final nh      = img.height.toDouble();
    final srcSize = _kCropSize / _zoom;
    final srcX    = nw / 2 - srcSize / 2 - _offset.dx / _zoom;
    final srcY    = nh / 2 - srcSize / 2 - _offset.dy / _zoom;
    final outSize = min(512.0, srcSize).toInt();

    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(srcX, srcY, srcSize, srcSize),
      Rect.fromLTWH(0, 0, outSize.toDouble(), outSize.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );
    final picture      = recorder.endRecording();
    final croppedImage = await picture.toImage(outSize, outSize);
    final byteData     = await croppedImage.toByteData(format: ui.ImageByteFormat.png);

    if (!mounted) return;
    if (byteData == null) { Navigator.pop(context); return; }

    final bytes    = byteData.buffer.asUint8List();
    final tempFile = File(
      '${Directory.systemTemp.path}/logo_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await tempFile.writeAsBytes(bytes);
    if (!mounted) return;
    Navigator.pop(context, tempFile);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
            child: Row(
              children: [
                const Text('Ajustar logo',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: const Color(0xFF94A3B8),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Zona de recorte
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                GestureDetector(
                  onPanUpdate: (d) => _onPan(d.delta),
                  child: SizedBox.square(
                    dimension: _kCropSize,
                    child: ClipOval(
                      child: Container(
                        color: const Color(0xFFE2E8F0),
                        child: _uiImage == null
                            ? const Center(child: CircularProgressIndicator())
                            : CustomPaint(
                                painter: _CropPainter(
                                  image:     _uiImage!,
                                  imageSize: _imageSize,
                                  zoom:      _zoom,
                                  offset:    _offset,
                                  cropSize:  _kCropSize,
                                ),
                                size: const Size(_kCropSize, _kCropSize),
                              ),
                      ),
                    ),
                  ),
                ),

                // Slider de zoom
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.zoom_out, size: 16, color: Color(0xFF94A3B8)),
                    Expanded(
                      child: Slider(
                        value: _zoom,
                        min:   _minZoom,
                        max:   _maxZoom,
                        onChanged: _uiImage != null ? _onZoomSlider : null,
                        activeColor: AppColors.kBlue,
                      ),
                    ),
                    const Icon(Icons.zoom_in, size: 16, color: Color(0xFF94A3B8)),
                  ],
                ),
                const Text(
                  'Arrastra para mover · Desliza para hacer zoom',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Color(0xFF64748B))),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: (_saving || _uiImage == null) ? null : _confirm,
                  icon: _saving
                      ? const SizedBox(
                          width:  14, height: 14,
                          child:  CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 14),
                  label: const Text('Confirmar'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.kBlue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Dibuja la imagen escalada y desplazada dentro del área de recorte
class _CropPainter extends CustomPainter {
  const _CropPainter({
    required this.image,
    required this.imageSize,
    required this.zoom,
    required this.offset,
    required this.cropSize,
  });

  final ui.Image image;
  final Size     imageSize;
  final double   zoom;
  final Offset   offset;
  final double   cropSize;

  @override
  void paint(Canvas canvas, Size size) {
    final w    = imageSize.width  * zoom;
    final h    = imageSize.height * zoom;
    final left = cropSize / 2 - w / 2 + offset.dx;
    final top  = cropSize / 2 - h / 2 + offset.dy;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, imageSize.width, imageSize.height),
      Rect.fromLTWH(left, top, w, h),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.image != image || old.zoom != zoom || old.offset != offset;
}
