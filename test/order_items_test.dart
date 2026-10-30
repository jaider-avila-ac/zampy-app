import 'package:flutter_test/flutter_test.dart';
import 'package:zammpy_app/modules/orders/utils/order_items.dart';

Map<String, dynamic> _item({List<String> ing = const [], String? size, String? note}) => {
      'productId': 'P1',
      'productName': 'Hamburguesa',
      'sizeId': size,
      'ingredientIds': ing,
      'extraIds': <String>[],
      'grupos': <String, List<String>>{'G1': ['Papas']},
      'unitPrice': 15000,
      'priceBreakdown': {'basePrice': 15000, 'ingredientsTotal': 0, 'extrasTotal': 0},
      'note': note,
    };

void main() {
  test('la misma configuración suma cantidad; otra configuración es otro ítem', () {
    var items = addConfiguredOrderItem([], _item(ing: ['a', 'b']));
    items = addConfiguredOrderItem(items, _item(ing: ['b', 'a'])); // mismo orden lógico
    items = addConfiguredOrderItem(items, _item(ing: ['a']));
    expect(items.length, 2);
    expect(items.first['quantity'], 2);
    expect(calculateOrderTotal(items), 45000);
  });

  test('la clave es igual a la de React (productId__size__ing__ext__grupos__nota)', () {
    expect(buildOrderItemKey(_item(ing: ['b', 'a'], size: 'S', note: ' sin sal ')),
        'P1__S__a,b____G1:Papas__sin sal');
  });

  test('payload del pedido incluye desglose y tamaño', () {
    final p = toOrderItemPayload({..._item(size: 'S'), 'sizeLabel': 'Grande', 'quantity': 2});
    expect(p['priceBreakdown']['subtotal'], 30000);
    expect(p['size'], {'id': 'S', 'label': 'Grande', 'price': 15000});
    expect(p.containsKey('ingredients'), isFalse);
  });
}
