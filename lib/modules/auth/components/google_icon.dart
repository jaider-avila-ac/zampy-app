import 'package:flutter/material.dart';

// Ícono de Google SVG (equivalente a GoogleIcon.jsx en React)
class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // Azul
    canvas.drawArc(
      Rect.fromLTWH(0, 0, s, s),
      -0.523,
      -1.571,
      false,
      Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke..strokeWidth = s * 0.2,
    );
    // Rojo
    canvas.drawArc(
      Rect.fromLTWH(0, 0, s, s),
      -2.094,
      -1.047,
      false,
      Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.stroke..strokeWidth = s * 0.2,
    );
    // Amarillo
    canvas.drawArc(
      Rect.fromLTWH(0, 0, s, s),
      -3.142,
      -1.047,
      false,
      Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.stroke..strokeWidth = s * 0.2,
    );
    // Verde
    canvas.drawArc(
      Rect.fromLTWH(0, 0, s, s),
      0,
      -0.523,
      false,
      Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.stroke..strokeWidth = s * 0.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
