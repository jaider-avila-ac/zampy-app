import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide MenuTheme;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../models/public_menu_model.dart';

class GaleriaAsidePanel {
  GaleriaAsidePanel._();

  static Future<void> show(
    BuildContext context,
    List<String> fotos,
    MenuTheme theme,
  ) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar galería',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _GaleriaPanel(fotos: fotos, theme: theme);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset =
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        return SlideTransition(position: offset, child: child);
      },
    );
  }
}

class _GaleriaPanel extends StatelessWidget {
  const _GaleriaPanel({required this.fotos, required this.theme});

  final List<String> fotos;
  final MenuTheme theme;

  @override
  Widget build(BuildContext context) {
    final width = math.min(380.0, MediaQuery.sizeOf(context).width * 0.92);
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: theme.surface,
        child: SafeArea(
          left: false,
          child: SizedBox(
            width: width,
            height: double.infinity,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: theme.border)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 17,
                        color: theme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Galería',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: theme.text,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: fotos.isEmpty
                      ? const Center(child: Text('Sin fotos todavía.'))
                      : Padding(
                          padding: const EdgeInsets.all(14),
                          child: MasonryGridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            itemCount: fotos.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => _showZoom(context, fotos[index]),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    fotos[index],
                                    width: double.infinity,
                                    fit: BoxFit.fitWidth,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        height: 160,
                                        color: theme.surfaceAlt,
                                        child: const Center(
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stack) =>
                                        Container(
                                          height: 160,
                                          color: theme.surfaceAlt,
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            color: theme.textMuted,
                                          ),
                                        ),
                                  ),
                                ),
                              );
                            },
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

  void _showZoom(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(child: Image.network(url, fit: BoxFit.contain)),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
