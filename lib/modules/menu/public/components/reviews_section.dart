import 'package:flutter/material.dart' hide MenuTheme;
import '../models/public_menu_model.dart';

// Equivalente a src/components/ReviewsSection.jsx en React

class ReviewModel {
  final String  autor;
  final String  texto;
  final String? fecha;

  const ReviewModel({required this.autor, required this.texto, this.fecha});

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    autor: json['autorNombre'] as String? ?? json['autor'] as String? ?? 'Anónimo',
    texto: json['texto']       as String? ?? '',
    fecha: json['fechaCreacion'] as String?,
  );
}

class ReviewsSection extends StatelessWidget {
  const ReviewsSection({
    super.key,
    required this.reviews,
    required this.theme,
  });

  final List<ReviewModel> reviews;
  final MenuTheme         theme;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reseñas',
            style: TextStyle(fontWeight: FontWeight.w900,
                fontSize: 16, color: theme.text)),
        const SizedBox(height: 12),
        ...reviews.map((r) => _ReviewItem(review: r, theme: theme)),
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.review, required this.theme});
  final ReviewModel review;
  final MenuTheme   theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: theme.primary),
                child: Center(
                  child: Text(
                    review.autor.isNotEmpty ? review.autor[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.autor,
                  style: TextStyle(fontWeight: FontWeight.w600,
                      fontSize: 13, color: theme.text),
                ),
              ),
              if (review.fecha != null)
                Text(
                  _fmtFecha(review.fecha!),
                  style: TextStyle(fontSize: 11, color: theme.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.texto,
              style: TextStyle(fontSize: 13, color: theme.textMuted, height: 1.5)),
        ],
      ),
    );
  }

  String _fmtFecha(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
  }
}
