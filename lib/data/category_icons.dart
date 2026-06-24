import 'package:flutter/material.dart';

// Equivalente a src/data/categoryIcons.js en React
// Mapea los valores string de icono a IconData de Material Design.

const Map<String, IconData> kCategoryIconMap = {
  'burger':    Icons.local_fire_department,
  'cup':       Icons.local_cafe,
  'cake':      Icons.cake,
  'ice':       Icons.icecream,
  'box':       Icons.inventory_2,
  'pizza':     Icons.local_pizza,
  'bag':       Icons.shopping_bag,
  'soup':      Icons.rice_bowl,
  'star':      Icons.star,
  'heart':     Icons.favorite,
  'bread':     Icons.grain,
  'croissant': Icons.bakery_dining,
  'cookie':    Icons.cookie,
  'sandwich':  Icons.lunch_dining,
  'beef':      Icons.set_meal,
  'fish':      Icons.water,
  'salad':     Icons.eco,
  'leaf':      Icons.energy_savings_leaf,
  'wine':      Icons.wine_bar,
  'beer':      Icons.sports_bar,
  'chef':      Icons.restaurant_menu,
  'fork':      Icons.restaurant,
};

const List<(String value, String label, IconData icon)> kCategoryIconList = [
  ('burger',    'Burger',      Icons.local_fire_department),
  ('cup',       'Bebidas',     Icons.local_cafe),
  ('cake',      'Postres',     Icons.cake),
  ('ice',       'Helados',     Icons.icecream),
  ('box',       'Combos',      Icons.inventory_2),
  ('pizza',     'Pizza',       Icons.local_pizza),
  ('bag',       'Llevar',      Icons.shopping_bag),
  ('soup',      'Sopas',       Icons.rice_bowl),
  ('star',      'Especiales',  Icons.star),
  ('heart',     'Favoritos',   Icons.favorite),
  ('bread',     'Panadería',   Icons.grain),
  ('croissant', 'Croissant',   Icons.bakery_dining),
  ('cookie',    'Galletas',    Icons.cookie),
  ('sandwich',  'Sándwich',    Icons.lunch_dining),
  ('beef',      'Carnes',      Icons.set_meal),
  ('fish',      'Mariscos',    Icons.water),
  ('salad',     'Ensaladas',   Icons.eco),
  ('leaf',      'Vegano',      Icons.energy_savings_leaf),
  ('wine',      'Vinos',       Icons.wine_bar),
  ('beer',      'Cervezas',    Icons.sports_bar),
  ('chef',      'Del chef',    Icons.restaurant_menu),
  ('fork',      'General',     Icons.restaurant),
];

IconData categoryIcon(String? value) =>
    kCategoryIconMap[value] ?? Icons.restaurant;
