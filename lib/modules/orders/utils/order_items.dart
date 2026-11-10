// Equivalente a src/utils/orderItems.js en React.
// Los ítems del carrito se guardan en el servidor (/carrito/{menú}) y la web y la app comparten ese
// contenido, así que se manejan como mapas con exactamente las mismas claves que usa React:
// productId, productName, productImage, sizeId, sizeLabel, ingredientIds, ingredientLabels,
// extraIds, extraLabels, grupos {id: [nombres]}, gruposResumen, unitPrice, ingredientDetails,
// extraDetails, grupoDetails, promo, priceBreakdown, note, quantity.

List<String> _strings(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];

num _num(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;

/// Clave de deduplicación: mismo producto con la misma configuración suma cantidad.
String buildOrderItemKey(Map<String, dynamic> item) {
  final grupos = item['grupos'] is Map ? Map<String, dynamic>.from(item['grupos'] as Map) : <String, dynamic>{};
  final gruposKey = (grupos.keys.toList()..sort())
      .map((k) => '$k:${(_strings(grupos[k])..sort()).join('|')}')
      .join(';');
  return [
    '${item['productId'] ?? ''}',
    '${item['sizeId'] ?? ''}',
    '${item['cantidadId'] ?? ''}',
    (_strings(item['ingredientIds'])..sort()).join(','),
    (_strings(item['extraIds'])..sort()).join(','),
    gruposKey,
    '${item['note'] ?? ''}'.trim(),
  ].join('__');
}

List<Map<String, dynamic>> addConfiguredOrderItem(
  List<Map<String, dynamic>> items,
  Map<String, dynamic> configured,
) {
  final key = buildOrderItemKey(configured);
  if (!items.any((i) => buildOrderItemKey(i) == key)) {
    return [...items, {...configured, 'quantity': 1}];
  }
  return [
    for (final i in items)
      buildOrderItemKey(i) == key ? {...i, 'quantity': _num(i['quantity']) + 1} : i,
  ];
}

num calculateOrderTotal(List<Map<String, dynamic>> items) => items.fold<num>(
      0,
      (t, i) => t + _num(i['unitPrice']) * _num(i['quantity']),
    );

/// Forma de cada ítem en POST /pedidos (igual que toOrderItemPayload de React).
Map<String, dynamic> toOrderItemPayload(Map<String, dynamic> item) {
  final breakdown = item['priceBreakdown'] is Map ? item['priceBreakdown'] as Map : const {};
  final unit = _num(item['unitPrice']);
  final entry = <String, dynamic>{
    'productId': item['productId'],
    'productName': item['productName'],
    'productImage': item['productImage'],
    'quantity': item['quantity'],
    'note': item['note'],
    'priceBreakdown': {
      'basePrice': breakdown['basePrice'] ?? unit,
      'ingredientsTotal': breakdown['ingredientsTotal'] ?? 0,
      'extrasTotal': breakdown['extrasTotal'] ?? 0,
      'unitPrice': unit,
      'subtotal': unit * _num(item['quantity']),
    },
  };
  if (item['cantidadId'] != null) {
    entry['cantidad'] = {'id': item['cantidadId'], 'label': item['cantidadLabel'], 'price': breakdown['basePrice']};
  }
  if (item['sizeId'] != null) {
    entry['size'] = {'id': item['sizeId'], 'label': item['sizeLabel'], 'price': breakdown['basePrice']};
  }
  if (item['promo'] != null) entry['promo'] = item['promo'];
  for (final (src, dst) in const [
    ('ingredientDetails', 'ingredients'),
    ('extraDetails', 'extras'),
    ('grupoDetails', 'grupos'),
  ]) {
    final v = item[src];
    if (v is List && v.isNotEmpty) entry[dst] = v;
  }
  return entry;
}
