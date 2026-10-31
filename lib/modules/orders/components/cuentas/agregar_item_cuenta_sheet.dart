import 'package:flutter/material.dart' hide MenuTheme;

import '../../../../services/pedido_service.dart';
import '../../../../shared/app_colors.dart';
import '../../../menu/public/components/product_image.dart';
import '../../../menu/public/components/product_modal.dart';
import '../../../menu/public/models/public_menu_model.dart';
import '../../hooks/catalogo_menu.dart';
import '../../hooks/pagina_cursor.dart' show mensaje;
import '../../models/cuenta_mesa.dart';
import '../../models/pedido_negocio.dart' show toNum;
import '../../utils/formato.dart';
import '../../utils/order_items.dart';
import '../comun/hoja_formulario.dart';

String _normalizar(String? v) {
  const con = 'áéíóúüñÁÉÍÓÚÜÑ';
  const sin = 'aeiouunAEIOUUN';
  final buf = StringBuffer();
  for (final ch in (v ?? '').split('')) {
    final i = con.indexOf(ch);
    buf.write(i >= 0 ? sin[i] : ch);
  }
  return buf.toString().toLowerCase();
}

/// Agregar un ítem olvidado a una cuenta en curso (queda como entregado). Se elige y configura el producto con el
/// mismo modal del menú (modo personal) y se envía todo junto (equivale a AgregarItemCuentaModal.jsx).
class AgregarItemCuentaSheet extends StatefulWidget {
  const AgregarItemCuentaSheet({super.key, required this.menu, required this.cuenta, required this.catalogo});

  final String menu;
  final CuentaMesa cuenta;
  final CatalogoMenu catalogo;

  @override
  State<AgregarItemCuentaSheet> createState() => _AgregarItemCuentaSheetState();
}

class _AgregarItemCuentaSheetState extends State<AgregarItemCuentaSheet> {
  late Future<PublicMenuData?> _carga = widget.catalogo.cargar();
  final _busqueda = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  List<MenuProduct> _visibles(PublicMenuData data) {
    final q = _normalizar(_busqueda.text.trim());
    // los productos ocultos ya vienen fuera del catálogo publicado
    return data.products
        .where((p) => q.isEmpty || [p.name, p.description, ...p.tags].any((v) => _normalizar(v).contains(q)))
        .toList();
  }

  void _configurar(PublicMenuData data, MenuProduct producto) {
    ProductModal.show(
      context,
      producto,
      data.theme,
      grupos: data.grupos,
      staffMode: true,
      onConfiguredAdd: (item) => setState(() => _items = addConfiguredOrderItem(_items, item)),
    );
  }

  void _cantidad(Map<String, dynamic> item, int delta) => setState(() {
        _items = [
          for (final i in _items)
            if (!identical(i, item))
              i
            else if (toNum(i['quantity']) + delta > 0)
              {...i, 'quantity': toNum(i['quantity']) + delta},
        ];
      });

  Future<void> _agregar() async {
    if (_items.isEmpty || _guardando) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await PedidoService.agregarItemCuenta(widget.menu, widget.cuenta.codigo, _items.map(toOrderItemPayload).toList());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = mensaje(e, 'No se pudo agregar el ítem.'));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.sizeOf(context).height * 0.88;
    return SizedBox(
      height: alto,
      child: FutureBuilder<PublicMenuData?>(
        future: _carga,
        builder: (context, snap) {
          final cabecera = Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Agregar ítem olvidado',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.kTextPrimary)),
                      Text('${widget.cuenta.mesaNombre} · se registrará como entregado',
                          style: const TextStyle(fontSize: 12, color: AppColors.kTextSecondary)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context, false), icon: const Icon(Icons.close, size: 20)),
              ],
            ),
          );
          if (snap.connectionState != ConnectionState.done) {
            return Column(children: [cabecera, const Expanded(child: Center(child: CircularProgressIndicator()))]);
          }
          final data = snap.data;
          if (snap.hasError || data == null) {
            return Column(children: [
              cabecera,
              Expanded(
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      snap.hasError ? mensaje(snap.error!, 'No se pudo cargar el menú.') : 'El menú no tiene una versión publicada.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.kTextSecondary),
                    ),
                    if (snap.hasError)
                      TextButton(onPressed: () => setState(() => _carga = widget.catalogo.cargar()), child: const Text('Reintentar')),
                  ]),
                ),
              ),
            ]);
          }
          return _contenido(cabecera, data);
        },
      ),
    );
  }

  Widget _contenido(Widget cabecera, PublicMenuData data) {
    final productos = _visibles(data);
    final lista = productos.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No encontramos productos parecidos', style: TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
            ),
          )
        : ListView.separated(
            itemCount: productos.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (_, i) {
              final p = productos[i];
              return ListTile(
                onTap: () => _configurar(data, p),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ProductImage(url: p.imageUrl ?? '', width: 44, height: 44, alignment: p.imageAlignment),
                ),
                title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  (p.description ?? '').trim().isEmpty ? 'Ver opciones del producto' : p.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.tune, size: 18, color: AppColors.kBlueLight),
              );
            },
          );
    final seleccion = _items.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Los productos agregados aparecerán aquí.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [for (final item in _items) _ItemElegido(item: item, onCantidad: (d) => _cantidad(item, d))],
          );
    final total = calculateOrderTotal(_items);

    return Column(
      children: [
        cabecera,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _busqueda,
            onChanged: (_) => setState(() {}),
            decoration: decoracionCampo(hint: 'Escribe el nombre, descripción o etiqueta…').copyWith(
              prefixIcon: const Icon(Icons.search, size: 18),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          // en tablet, catálogo y selección lado a lado (como md:grid-cols-2 de la web)
          child: LayoutBuilder(
            builder: (context, c) => c.maxWidth >= 540
                ? Row(children: [
                    Expanded(child: lista),
                    const VerticalDivider(width: 1),
                    Expanded(child: ColoredBox(color: const Color(0xFFF8FAFC), child: seleccion)),
                  ])
                : Column(children: [
                    Expanded(flex: 3, child: lista),
                    const Divider(height: 1),
                    Expanded(flex: 2, child: ColoredBox(color: const Color(0xFFF8FAFC), child: seleccion)),
                  ]),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.kRed)),
                ),
              BotonGuardar(
                texto: _items.isEmpty ? 'Agregar a la cuenta' : 'Agregar a la cuenta · ${precio(total)}',
                guardando: _guardando,
                onPressed: _items.isEmpty ? null : _agregar,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemElegido extends StatelessWidget {
  const _ItemElegido({required this.item, required this.onCantidad});

  final Map<String, dynamic> item;
  final ValueChanged<int> onCantidad;

  @override
  Widget build(BuildContext context) {
    final cantidad = toNum(item['quantity']);
    List<String> lista(String k) => item[k] is List ? (item[k] as List).map((e) => '$e').toList() : const [];
    final grupos = item['gruposResumen'] is Map ? item['gruposResumen'] as Map : const {};
    const detalle = TextStyle(fontSize: 12, color: AppColors.kTextSecondary);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item['productName'] ?? ''}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    if (item['sizeLabel'] != null) Text('Tamaño: ${item['sizeLabel']}', style: detalle),
                    if (lista('ingredientLabels').isNotEmpty) Text('Personalización: ${lista('ingredientLabels').join(', ')}', style: detalle),
                    if (lista('extraLabels').isNotEmpty) Text('Adiciones: ${lista('extraLabels').join(', ')}', style: detalle),
                    for (final e in grupos.entries)
                      Text('${e.key}: ${e.value is List ? (e.value as List).join(', ') : e.value}', style: detalle),
                    if (item['note'] != null)
                      Text('Nota: ${item['note']}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB45309))),
                  ],
                ),
              ),
              Text(precio(toNum(item['unitPrice']) * cantidad), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton.outlined(
                onPressed: () => onCantidad(-1),
                visualDensity: VisualDensity.compact,
                iconSize: 15,
                icon: Icon(cantidad == 1 ? Icons.delete_outline : Icons.remove),
              ),
              SizedBox(width: 28, child: Text('$cantidad', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
              IconButton.filled(
                onPressed: () => onCantidad(1),
                visualDensity: VisualDensity.compact,
                iconSize: 15,
                style: IconButton.styleFrom(backgroundColor: AppColors.kBlue),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
