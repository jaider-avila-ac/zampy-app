import 'dart:async';

import 'package:flutter/material.dart';

class ProductImage extends StatefulWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.backgroundColor = const Color(0xFFF1F5F9),
    this.foregroundColor = const Color(0xFFCBD5E1),
    this.logoUrl,
  });

  final String? url;
  // logo del menú: respaldo cuando el producto no tiene foto (o la suya no carga)
  final String? logoUrl;
  final BoxFit fit;
  // qué parte de la foto se ve (posición elegida por el dueño)
  final Alignment alignment;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  State<ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<ProductImage> {
  bool _loading = true;
  bool _ready = false;
  bool _failed = false;
  int _attempt = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant ProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _retryTimer?.cancel();
      _loading = true;
      _ready = false;
      _failed = false;
      _attempt = 0;
      _start();
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final url = widget.url;
    if (url == null || url.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }

    final ok = await _ProductImageLoader.load(url);
    if (!mounted) return;

    if (ok) {
      setState(() {
        _loading = false;
        _ready = true;
      });
      return;
    }

    if (_attempt >= 3) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }

    _attempt++;
    _retryTimer = Timer(Duration(seconds: _attempt * 2), _start);
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    if (url == null || url.isEmpty || _failed) return _fallback();

    if (_loading || !_ready) return _placeholder();

    return Image.network(
      url,
      fit: widget.fit,
      alignment: widget.alignment,
      width: widget.width,
      height: widget.height,
      gaplessPlayback: true,
      errorBuilder: (context, error, stack) => _fallback(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: widget.backgroundColor,
      alignment: Alignment.center,
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: widget.foregroundColor,
        ),
      ),
    );
  }

  Widget _fallback() {
    final logo = widget.logoUrl;
    return Container(
      width: widget.width,
      height: widget.height,
      color: widget.backgroundColor,
      alignment: Alignment.center,
      // Sin foto del producto: se muestra el logo del menú atenuado (si no hay logo o no carga,
      // cae al ícono genérico).
      child: logo != null && logo.isNotEmpty
          ? FractionallySizedBox(
              widthFactor: 0.4,
              heightFactor: 0.4,
              child: Opacity(
                opacity: 0.3,
                child: Image.network(
                  logo,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.restaurant_outlined,
                    size: 26,
                    color: widget.foregroundColor,
                  ),
                ),
              ),
            )
          : Icon(
              Icons.restaurant_outlined,
              size: 26,
              color: widget.foregroundColor,
            ),
    );
  }
}

// Una sola petición por URL y como máximo 3 descargas simultáneas.
// Evita los HTTP 429 de hosts como Wikimedia cuando una lista pide
// muchas imágenes a la vez.
class _ProductImageLoader {
  static const _maxConcurrent = 3;
  static int _active = 0;
  static final List<Completer<void>> _waiting = [];
  static final Map<String, Future<bool>> _inFlight = {};

  static Future<bool> load(String url) {
    return _inFlight.putIfAbsent(url, () => _load(url));
  }

  static Future<bool> _load(String url) async {
    await _acquire();
    try {
      final provider = NetworkImage(url);
      final stream = provider.resolve(ImageConfiguration.empty);
      final completer = Completer<bool>();
      late ImageStreamListener listener;

      listener = ImageStreamListener(
        (info, synchronousCall) {
          if (!completer.isCompleted) completer.complete(true);
          stream.removeListener(listener);
        },
        onError: (error, stackTrace) {
          if (!completer.isCompleted) completer.complete(false);
          stream.removeListener(listener);
        },
      );

      stream.addListener(listener);
      final ok = await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          stream.removeListener(listener);
          return false;
        },
      );

      if (!ok) _inFlight.remove(url);
      return ok;
    } catch (_) {
      _inFlight.remove(url);
      return false;
    } finally {
      _release();
    }
  }

  static Future<void> _acquire() {
    if (_active < _maxConcurrent) {
      _active++;
      return Future.value();
    }
    final completer = Completer<void>();
    _waiting.add(completer);
    return completer.future;
  }

  static void _release() {
    if (_waiting.isNotEmpty) {
      _waiting.removeAt(0).complete();
    } else if (_active > 0) {
      _active--;
    }
  }
}
