import 'package:flutter/material.dart';

// Paleta Zammpy — equivalente a las variables CSS de Tailwind en React
abstract class AppColors {
  // Azul — color de marca (indigo-600)
  static const kBlue      = Color(0xFF4F46E5); // indigo-600
  static const kBlueDark  = Color(0xFF4338CA); // indigo-700
  static const kBlueLight = Color(0xFF6366F1); // indigo-500

  // Fondos
  static const kWhite      = Colors.white;
  static const kBgPage     = Color(0xFFF8FAFC); // slate-50
  static const kCardBorder = Color(0xFFE2E8F0); // slate-200

  // Texto
  static const kTextPrimary   = Color(0xFF0F172A); // slate-900
  static const kTextSecondary = Color(0xFF475569); // slate-600
  static const kTextMuted     = Color(0xFF94A3B8); // slate-400

  // Skeleton / placeholder
  static const kSkeleton = Color(0xFFF1F5F9); // slate-100

  // Feedback
  static const kRed   = Color(0xFFDC2626); // red-600
  static const kGreen = Color(0xFF16A34A); // green-600
}
