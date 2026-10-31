import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../context/notificacion_context.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/app_header.dart';
import '../../../shared/responsive.dart';
import '../../orders/components/comun/estados_lista.dart';
import '../../orders/hooks/eventos_pedidos.dart';
import '../components/historial/mis_ordenes_mesero.dart';
import '../components/mesa_card.dart';
import '../components/panel/mesa_panel.dart';
import '../hooks/use_historial_mesero.dart';
import '../hooks/use_mesas_mesero.dart';
import '../models/mesa_mesero.dart';

// Equivalente a MeseroPage.jsx: mesas y la mesa elegida (en tablet ancha, lado a lado; en el teléfono, una a la vez)
// y el historial "Mis órdenes". Se refresca en vivo con los eventos de pedidos del menú.

class MeseroPage extends StatefulWidget {
  const MeseroPage({super.key, required this.codigo});

  final String codigo;

  @override
  State<MeseroPage> createState() => _MeseroPageState();
}

class _MeseroPageState extends State<MeseroPage> {
  late final _mesas = UseMesasMesero(widget.codigo);
  late final _historial = UseHistorialMesero(widget.codigo);
  late final EventosPedidos _eventos;
  String? _mesaCodigo; // por código: siempre se lee la versión al día de la mesa
  bool _verHistorial = false;
  bool _historialCargado = false;

  @override
  void initState() {
    super.initState();
    _eventos = EventosPedidos(context.read<NotificacionContext>(), widget.codigo, _mesas.recargar);
    _mesas.cargar();
  }

  @override
  void dispose() {
    _eventos.cerrar();
    _mesas.dispose();
    _historial.dispose();
    super.dispose();
  }

  MesaMesero? get _mesa => _mesas.mesas.where((m) => m.codigo == _mesaCodigo).firstOrNull;

  void _elegir(MesaMesero m) {
    if (m.abiertaPorOtro) return;
    setState(() => _mesaCodigo = m.codigo);
  }

  void _cambiarVista(bool historial) {
    setState(() => _verHistorial = historial);
    if (historial && !_historialCargado) {
      _historialCargado = true;
      _historial.cargar();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _mesas,
        builder: (context, _) {
          final ancho = esAncho(context);
          final mesa = _mesa;
          // en el teléfono, con una mesa abierta, "atrás" vuelve a la cuadrícula
          final panelSolo = !ancho && mesa != null && !_verHistorial;
          return PopScope(
            canPop: !panelSolo,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && panelSolo) setState(() => _mesaCodigo = null);
            },
            child: Scaffold(
              backgroundColor: AppColors.kBgPage,
              appBar: AppHeader(
                title: (_mesas.resumen?.nombre ?? '').isEmpty ? 'Vista mesero' : _mesas.resumen!.nombre,
                subtitle: 'Vista del mesero',
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Wrap(spacing: 6, children: [
                      _Pestana(icono: Icons.table_restaurant_outlined, texto: 'Mesas', activa: !_verHistorial, onTap: () => _cambiarVista(false)),
                      _Pestana(icono: Icons.assignment_outlined, texto: 'Mis órdenes', activa: _verHistorial, onTap: () => _cambiarVista(true)),
                    ]),
                  ),
                  const Divider(height: 1),
                  Expanded(child: _cuerpo(ancho, mesa, panelSolo)),
                ],
              ),
            ),
          );
        },
      );

  Widget _cuerpo(bool ancho, MesaMesero? mesa, bool panelSolo) {
    if (_verHistorial) return MisOrdenesMesero(historial: _historial);
    if (_mesas.cargando) return const CargandoLista();

    final panel = mesa == null
        ? null
        : MesaPanel(
            key: ValueKey(mesa.codigo),
            menu: widget.codigo,
            slug: _mesas.resumen?.slug,
            mesa: mesa,
            onMesaLibre: _mesas.recargar,
          );

    if (panelSolo) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: Colors.white,
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _mesaCodigo = null),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Mesas'),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: panel!),
      ]);
    }

    final grilla = RefreshIndicator(
      onRefresh: _mesas.recargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_mesas.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(children: [
                Text(_mesas.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.kRed)),
                TextButton(onPressed: _mesas.cargar, child: const Text('Reintentar')),
              ]),
            )
          else if (_mesas.mesas.isEmpty)
            const ListaVacia(
              icono: Icons.table_restaurant_outlined,
              texto: 'Sin mesas configuradas\nEl administrador del menú debe crear mesas primero.',
            )
          else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisExtent: 112,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _mesas.mesas.length,
              itemBuilder: (_, i) => MesaCard(
                mesa: _mesas.mesas[i],
                seleccionada: _mesas.mesas[i].codigo == _mesaCodigo,
                onTap: () => _elegir(_mesas.mesas[i]),
              ),
            ),
            const SizedBox(height: 12),
            Text('${_mesas.mesas.length} mesa${_mesas.mesas.length == 1 ? '' : 's'}',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
          ],
        ],
      ),
    );

    // tablet ancha: cuadrícula y panel lado a lado (como lg: en la web)
    if (ancho) {
      return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: grilla),
        const VerticalDivider(width: 1),
        SizedBox(
          width: 400,
          child: ColoredBox(
            color: const Color(0xFFF8FAFC),
            child: panel ?? const ListaVacia(icono: Icons.assignment_outlined, texto: 'Selecciona una mesa'),
          ),
        ),
      ]);
    }
    return grilla;
  }
}

class _Pestana extends StatelessWidget {
  const _Pestana({required this.icono, required this.texto, required this.activa, required this.onTap});

  final IconData icono;
  final String texto;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        avatar: Icon(icono, size: 15, color: activa ? Colors.white : AppColors.kTextSecondary),
        label: Text(texto),
        selected: activa,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: activa ? Colors.white : AppColors.kTextSecondary),
        selectedColor: AppColors.kBlue,
        backgroundColor: Colors.white,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}
