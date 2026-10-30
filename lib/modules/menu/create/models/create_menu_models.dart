class CategoriaRestaurante {
  final String codigo;
  final String nombre;
  final String icono;

  const CategoriaRestaurante({
    required this.codigo,
    required this.nombre,
    required this.icono,
  });

  factory CategoriaRestaurante.fromJson(Map<String, dynamic> json) =>
      CategoriaRestaurante(
        codigo: (json['codigo'] ?? json['id'] ?? '').toString(),
        nombre: json['nombre'] as String? ?? '',
        icono: json['icono'] as String? ?? 'utensils',
      );
}

/// Solo lo básico del contrato actual: lo demás se completa desde el hub/editor.
class CrearMenuDraft {
  final String restaurantCategoryCode;
  final String name;
  final String slug;

  const CrearMenuDraft({
    required this.restaurantCategoryCode,
    required this.name,
    required this.slug,
  });

  Map<String, dynamic> toJson() => {
    'restaurantCategoryCode': restaurantCategoryCode,
    'name': name.trim(),
    'slug': slug.trim(),
  };
}

String slugify(String text) {
  var s = text.toLowerCase();
  const accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
    'ä': 'a',
    'ö': 'o',
  };
  for (final e in accents.entries) {
    s = s.replaceAll(e.key, e.value);
  }
  s = s.replaceAll(RegExp(r'[^a-z0-9\s-]'), '').trim();
  s = s.replaceAll(RegExp(r'\s+'), '-');
  s = s.replaceAll(RegExp(r'-+'), '-');
  if (s.length > 50) s = s.substring(0, 50);
  return s;
}

String? slugError(String slug) {
  if (slug.isEmpty) return 'Requerido';
  if (slug.length < 3) return 'Mínimo 3 caracteres';
  if (slug.length > 50) return 'Máximo 50 caracteres';
  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(slug)) {
    return 'Solo letras minúsculas, números y guiones';
  }
  if (slug.startsWith('-') || slug.endsWith('-')) {
    return 'No puede empezar ni terminar con guión';
  }
  if (slug.contains('--')) return 'Sin guiones consecutivos';
  return null;
}
