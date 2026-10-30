import 'package:flutter/widgets.dart';

// Adaptación a tablets: la app también se usa en tablets (sobre todo el personal del negocio).

class Breakpoints {
  Breakpoints._();

  /// Desde aquí se considera tablet (ancho lógico).
  static const double tablet = 600;

  /// Tablet grande u horizontal: caben dos columnas cómodas.
  static const double ancho = 900;
}

bool esTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

bool esAncho(BuildContext context) => MediaQuery.sizeOf(context).width >= Breakpoints.ancho;

/// Padding para listas de lectura/formularios: en pantallas anchas centra el contenido en
/// [maxWidth] sin achicar el área de scroll (el gesto de recargar y la barra siguen a todo el ancho).
EdgeInsets contenidoPadding(
  BuildContext context, {
  double maxWidth = 720,
  double horizontal = 16,
  double top = 16,
  double bottom = 32,
}) {
  final w = MediaQuery.sizeOf(context).width;
  final lateral = w > maxWidth + horizontal * 2 ? (w - maxWidth) / 2 : horizontal;
  return EdgeInsets.fromLTRB(lateral, top, lateral, bottom);
}

/// Restricción para hojas inferiores (bottom sheets): en tablet no ocupan todo el ancho.
BoxConstraints hojaConstraints(BuildContext context, {double maxWidth = 560}) =>
    BoxConstraints(maxWidth: esTablet(context) ? maxWidth : double.infinity);
