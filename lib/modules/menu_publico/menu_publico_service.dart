import 'dart:convert';
import 'dart:ui' show Color;
import 'package:http/http.dart' as http;
import '../auth/auth_service.dart';
import 'models/menu_publico_model.dart';

class MenuPublicoService {
  MenuPublicoService._();

  static Future<MenuPublicoData?> getPublicData(String slug) async {
    try {
      final token = await AuthService.getToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final res = await http
          .get(Uri.parse('$kApiBase/api/public/menu/$slug'), headers: headers)
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      final raw = jsonDecode(res.body) as Map<String, dynamic>;
      // Same normalization as menuService.js getPublicData
      final published = raw['published'] as Map<String, dynamic>?;
      if (published == null) return null;
      return MenuPublicoData.fromJson({
        ...published,
        'menuId': raw['id'],
        'slug':   raw['slug'] ?? slug,
        'ownerId': raw['ownerId'],
        'theme':  raw['theme'],
      });
    } catch (_) {
      return null;
    }
  }

  /// Demo — primero intenta traer el menú del backend (para respetar su tema),
  /// si falla usa datos estáticos con tema por defecto.
  static Future<MenuPublicoData> getDemoData() async {
    // El backend puede tener el demo registrado con un slug específico
    final fromApi = await getPublicData('demo');
    if (fromApi != null) return fromApi;
    return _staticDemoData;
  }

  /// Datos estáticos de fallback — tema viene del backend cuando está disponible.
  static MenuPublicoData get _staticDemoData => MenuPublicoData(
        menuId: 0,
        slug: 'demo',
        // Sin colores hardcodeados: el tema por defecto se usará si el backend no responde
        theme: const MenuPublicoTheme(
          primary: Color(0xFFFF3B1F), // solo el color primario de referencia
        ),
        business: BusinessInfo(
          name: 'Burger & More',
          slogan: 'Sabor que enamora, calidad que conquista',
          bannerUrl:
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=1200&q=80',
          rating: 4.8,
          reviews: 1240,
          address: 'Calle 45 #12-30, Bogotá',
          phone: '+57 300 123 4567',
          schedule: 'Lun - Dom: 11:00 AM – 10:00 PM',
          tags: const ['Hamburguesas', 'Combos', 'Fast Food', 'Domicilios'],
        ),
        categories: const [
          MenuCategory(id: 'burgers',  label: 'Hamburguesas', icon: 'burger'),
          MenuCategory(id: 'drinks',   label: 'Bebidas',      icon: 'cup'),
          MenuCategory(id: 'desserts', label: 'Postres',      icon: 'cake'),
          MenuCategory(id: 'icecream', label: 'Helados',      icon: 'ice'),
          MenuCategory(id: 'combos',   label: 'Combos',       icon: 'box'),
        ],
        grupos: const [
          GrupoInfo(id: 'g1', name: 'Salsas disponibles',
              items: ['BBQ', 'Mostaza', 'Mayonesa', 'Chimichurri', 'Salsa secreta', 'Sriracha']),
          GrupoInfo(id: 'g2', name: 'Opciones de pan',
              items: ['Brioche', 'Integral', 'Sin gluten', 'Pretzel']),
          GrupoInfo(id: 'g3', name: 'Sabores disponibles',
              items: ['Vainilla', 'Chocolate', 'Fresa', 'Oreo', 'Maracuyá', 'Arequipe']),
        ],
        products: _demoProducts,
      );

  // ── Calificaciones de producto ────────────────────────────────────────────
  // Equivalente a interaccionService.calificar / miCalificacion

  static Future<double?> rateProduct(
      String menuSlug, String productId, int stars) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;
      final res = await http
          .post(
            Uri.parse(
                '$kApiBase/api/interacciones/menu/$menuSlug/productos/$productId/calificar'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'estrellas': stars}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['promedio'] as num?)?.toDouble();
      }
    } catch (_) {}
    return null;
  }

  static Future<int?> getMyRating(String menuSlug, String productId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;
      final res = await http
          .get(
            Uri.parse(
                '$kApiBase/api/interacciones/menu/$menuSlug/productos/$productId/mi-calificacion'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['estrellas'] as num?)?.toInt();
      }
    } catch (_) {}
    return null;
  }

  static final List<Producto> _demoProducts = [
    // ── Hamburguesas ──────────────────────────────────────────
    Producto(
      id: 'b1', category: 'burgers',
      name: 'Classic Smash',
      description: 'Carne angus aplastada, queso americano, pepinillos, mostaza y salsa especial.',
      components: const ['Carne angus', 'Queso americano', 'Pepinillos', 'Mostaza', 'Salsa especial', 'Pan brioche'],
      price: 18000,
      image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&q=80',
      tags: const ['Popular', 'Clásico'], rating: 4.9, isFeatured: true,
      grupoIds: const ['g1', 'g2'],
      sizes: const [
        ProductoVariante(id: 's', label: 'Pequeño', price: 18000),
        ProductoVariante(id: 'm', label: 'Mediano',  price: 20000),
        ProductoVariante(id: 'l', label: 'Grande',   price: 22000),
      ],
      ingredients: const [
        ProductoVariante(id: 'no-onion',    label: 'Sin cebolla'),
        ProductoVariante(id: 'extra-cheese',label: 'Extra queso', price: 1500),
      ],
      extras: const [
        ProductoVariante(id: 'fries', label: 'Papas fritas', price: 3500),
        ProductoVariante(id: 'drink', label: 'Bebida',       price: 4000),
      ],
    ),
    Producto(
      id: 'b2', category: 'burgers',
      name: 'BBQ Bacon Stack',
      description: 'Doble carne, tocino crocante, cebolla caramelizada, salsa BBQ premium.',
      components: const ['Doble carne', 'Tocino crocante', 'Cebolla caramelizada', 'Salsa BBQ', 'Pan brioche'],
      price: 24000, promoActive: true, promoPrice: 19000,
      image: 'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=600&q=80',
      tags: const ['Nuevo', 'Especial del día'], rating: 4.8,
      grupoIds: const ['g1', 'g2'],
      sizes: const [
        ProductoVariante(id: 's', label: 'Pequeño', price: 24000),
        ProductoVariante(id: 'm', label: 'Mediano',  price: 26000),
        ProductoVariante(id: 'l', label: 'Grande',   price: 28000),
      ],
      extras: const [
        ProductoVariante(id: 'fries',   label: 'Papas fritas', price: 3500),
        ProductoVariante(id: 'protein', label: 'Proteína extra', price: 5000),
      ],
    ),
    Producto(
      id: 'b5', category: 'burgers',
      name: 'Truffle Mushroom',
      description: 'Carne wagyu, champiñones salteados, queso gruyère y aceite de trufa.',
      components: const ['Carne wagyu', 'Champiñones', 'Queso gruyère', 'Aceite de trufa', 'Pan artesanal'],
      price: 29000, promoActive: true, promoPrice: 24000,
      promoEndsAt: DateTime(2026, 12, 31, 23, 59),
      image: 'https://images.unsplash.com/photo-1561758033-d89a9ad46330?w=600&q=80',
      tags: const ['Premium', 'Chef'], rating: 5.0, isFeatured: true,
      grupoIds: const ['g1', 'g2'],
      sizes: const [
        ProductoVariante(id: 's', label: 'Pequeño', price: 29000),
        ProductoVariante(id: 'm', label: 'Mediano',  price: 31000),
        ProductoVariante(id: 'l', label: 'Grande',   price: 33000),
      ],
    ),
    Producto(
      id: 'b6', category: 'burgers',
      name: 'Double Smash',
      description: 'Dos carnes, doble queso americano, salsa secreta y vegetales frescos.',
      price: 26000,
      image: 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=600&q=80',
      tags: const ['Popular'], rating: 4.8,
      sizes: const [
        ProductoVariante(id: 's', label: 'Pequeño', price: 26000),
        ProductoVariante(id: 'l', label: 'Grande',   price: 30000),
      ],
    ),
    // ── Bebidas ───────────────────────────────────────────────
    Producto(
      id: 'd1', category: 'drinks',
      name: 'Limonada de Coco',
      description: 'Limonada natural con leche de coco y menta fresca.',
      price: 9000,
      image: 'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=600&q=80',
      tags: const ['Refrescante', 'Popular'], rating: 4.9, isFeatured: true,
      sizes: const [
        ProductoVariante(id: 's', label: '350ml', price: 9000),
        ProductoVariante(id: 'm', label: '500ml', price: 11000),
        ProductoVariante(id: 'l', label: '700ml', price: 12500),
      ],
    ),
    Producto(
      id: 'd2', category: 'drinks',
      name: 'Milkshake Oreo',
      description: 'Malteada espesa de vainilla con galleta Oreo triturada y crema.',
      price: 12000, promoActive: true, promoPrice: 9500,
      image: 'https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=600&q=80',
      tags: const ['Favorito'], rating: 4.9,
      sizes: const [
        ProductoVariante(id: 's', label: '300ml', price: 12000),
        ProductoVariante(id: 'l', label: '500ml', price: 15000),
      ],
    ),
    Producto(
      id: 'd3', category: 'drinks',
      name: 'Agua de Panela',
      description: 'Tradicional bebida colombiana con limón y hierbabuena.',
      price: 5000,
      image: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=600&q=80',
      tags: const ['Tradicional'], rating: 4.5,
    ),
    Producto(
      id: 'd5', category: 'drinks',
      name: 'Smoothie Verde',
      description: 'Espinaca, manzana verde, jengibre y limón. Refrescante y saludable.',
      price: 11000,
      image: 'https://images.unsplash.com/photo-1638176066666-ffb2f013c7dd?w=600&q=80',
      tags: const ['Saludable', 'Vegano'], rating: 4.7,
    ),
    // ── Postres ───────────────────────────────────────────────
    Producto(
      id: 'p1', category: 'desserts',
      name: 'Brownie Caliente',
      description: 'Brownie de chocolate con nueces, servido caliente con helado de vainilla.',
      components: const ['Brownie', 'Nueces', 'Helado de vainilla'],
      price: 10000,
      image: 'https://images.unsplash.com/photo-1607920591413-4ec007e70023?w=600&q=80',
      tags: const ['Caliente', 'Popular'], rating: 4.9,
    ),
    Producto(
      id: 'p2', category: 'desserts',
      name: 'Cheesecake de Frutos Rojos',
      description: 'Cremoso cheesecake con cobertura de frutos rojos frescos.',
      price: 11000,
      image: 'https://images.unsplash.com/photo-1562440499-64916591-8a633?w=600&q=80',
      tags: const ['Favorito'], rating: 4.8,
    ),
    // ── Helados ───────────────────────────────────────────────
    Producto(
      id: 'i1', category: 'icecream',
      name: 'Copa Artesanal',
      description: 'Dos bolas de helado artesanal a elegir de nuestra carta de sabores.',
      price: 8500, isFeatured: true,
      image: 'https://images.unsplash.com/photo-1501443762994-82bd5dace89a?w=600&q=80',
      tags: const ['Popular'], rating: 4.8,
      grupoIds: const ['g3'],
    ),
    Producto(
      id: 'i2', category: 'icecream',
      name: 'Sundae de Chocolate',
      description: 'Helado de vainilla con salsa de chocolate caliente, nueces y crema chantillí.',
      price: 9000,
      image: 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=600&q=80',
      tags: const ['Clásico'], rating: 4.7,
    ),
    // ── Combos ────────────────────────────────────────────────
    Producto(
      id: 'c1', category: 'combos',
      name: 'Combo Classic',
      description: 'Classic Smash + papas fritas medianas + bebida 350ml a tu elección.',
      price: 28000, promoActive: true, promoPrice: 24000,
      image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&q=80',
      tags: const ['Ahorra', 'Popular'], rating: 4.9, isFeatured: true,
    ),
    Producto(
      id: 'c2', category: 'combos',
      name: 'Combo Premium',
      description: 'Truffle Mushroom + papas fritas grandes + milkshake de tu elección.',
      price: 42000, promoActive: true, promoPrice: 36000,
      image: 'https://images.unsplash.com/photo-1561758033-d89a9ad46330?w=600&q=80',
      tags: const ['Premium', 'Mejor valor'], rating: 4.8,
    ),
  ];
}
