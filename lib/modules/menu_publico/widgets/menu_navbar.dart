import 'package:flutter/material.dart';
import '../models/menu_publico_model.dart';

/// Equivalente a Navbar.jsx — sticky header con logo, nombre, horario y búsqueda.
class MenuNavbar extends StatefulWidget {
  const MenuNavbar({
    super.key,
    required this.business,
    required this.theme,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onBack,
  });

  final BusinessInfo business;
  final MenuPublicoTheme theme;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onBack;

  @override
  State<MenuNavbar> createState() => _MenuNavbarState();
}

class _MenuNavbarState extends State<MenuNavbar> {
  bool _searchOpen = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (_searchOpen) {
      _ctrl.clear();
      widget.onSearchChanged('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg   = widget.theme.navBg;
    final fg   = widget.theme.navText;
    final prim = widget.theme.primary;
    final border = widget.theme.navBorder;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                // Botón back
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 20, color: fg),
                  onPressed: widget.onBack,
                ),

                // Logo + nombre (oculto cuando búsqueda abierta)
                if (!_searchOpen) ...[
                  _buildLogo(prim, fg),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTitle(fg)),
                ],

                // Barra de búsqueda expandida
                if (_searchOpen)
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: widget.theme.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          Icon(Icons.search, size: 14,
                              color: widget.theme.textMuted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              autofocus: true,
                              onChanged: widget.onSearchChanged,
                              style: TextStyle(
                                  fontSize: 14, color: widget.theme.text),
                              decoration: InputDecoration(
                                hintText: 'Buscar en el menú...',
                                hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: widget.theme.textMuted),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (widget.searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _ctrl.clear();
                                widget.onSearchChanged('');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(Icons.close,
                                    size: 14,
                                    color: widget.theme.textMuted),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Botón buscar toggle
                GestureDetector(
                  onTap: _toggleSearch,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _searchOpen
                          ? prim
                          : fg.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _searchOpen ? Icons.close : Icons.search,
                      size: 16,
                      color: _searchOpen ? Colors.white : fg,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(Color prim, Color fg) {
    final b = widget.business;
    if (b.logoUrl != null && b.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          b.logoUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initialBox(prim, fg),
        ),
      );
    }
    return _initialBox(prim, fg);
  }

  Widget _initialBox(Color prim, Color fg) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: prim,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.business.name.isNotEmpty
              ? widget.business.name[0].toUpperCase()
              : '?',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
        ),
      );

  Widget _buildTitle(Color fg) {
    final b = widget.business;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          b.name,
          style: TextStyle(
              color: fg, fontWeight: FontWeight.w900, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (b.schedule != null && b.schedule!.isNotEmpty)
          Row(
            children: [
              Icon(Icons.access_time, size: 10,
                  color: fg.withValues(alpha: 0.6)),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  b.schedule!,
                  style: TextStyle(
                      fontSize: 10, color: fg.withValues(alpha: 0.6)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
