import 'package:flutter/material.dart' hide MenuTheme;
import 'package:provider/provider.dart';
import '../../../../context/auth_context.dart';
import '../../../../services/interaccion_service.dart';
import '../models/public_menu_model.dart';

// Equivalente a src/modules/menu/public/components/ReviewsSection.jsx en React

class ReviewModel {
  final String  id;
  final String  autorNombre;
  final String? autorAvatar;
  final String  texto;
  final String? tiempoRelativo;
  final bool    esPropia;

  const ReviewModel({
    required this.id,
    required this.autorNombre,
    required this.texto,
    this.autorAvatar,
    this.tiempoRelativo,
    this.esPropia = false,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    id:             json['id']?.toString()            ?? UniqueKey().toString(),
    autorNombre:    json['autorNombre']  as String?   ?? json['autor'] as String? ?? 'Anónimo',
    autorAvatar:    json['autorAvatar']  as String?,
    texto:          json['texto']        as String?   ?? '',
    tiempoRelativo: json['tiempoRelativo'] as String?,
    esPropia:       json['esPropia']     as bool?     ?? false,
  );
}

String? _validateReview(String texto) {
  if (RegExp(r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}').hasMatch(texto)) {
    return 'La reseña no puede contener correos electrónicos';
  }
  if (RegExp(r'https?://|www\.', caseSensitive: false).hasMatch(texto)) {
    return 'La reseña no puede contener enlaces';
  }
  if (RegExp(r'\b\d{7,}\b').hasMatch(texto)) {
    return 'La reseña no puede contener números de teléfono';
  }
  return null;
}

// ── Datos demo — mismos que React ────────────────────────────────────────────
const _demoReviews = [
  ReviewModel(id: 'd1', autorNombre: 'Valentina R.', texto: 'Increíble sabor, el servicio es muy rápido. ¡Volveré pronto!'),
  ReviewModel(id: 'd2', autorNombre: 'Andrés M.',    texto: 'La hamburguesa clásica es espectacular. Las papas podrían estar más crujientes.'),
  ReviewModel(id: 'd3', autorNombre: 'Catalina P.',  texto: 'El mejor lugar del sector. El combo familiar alcanzó para todos.'),
];

class ReviewsSection extends StatefulWidget {
  const ReviewsSection({
    super.key,
    required this.theme,
    this.menuSlug,
    this.meEncantas = 0,
    this.ownerId,
  });

  final MenuTheme theme;
  final String?   menuSlug;
  final int       meEncantas;
  final int?      ownerId;

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  List<ReviewModel> _reviews         = [];
  int               _encantaTotal    = 0;
  bool              _meEncanta       = false;
  bool              _myReview        = false;
  bool              _loadingEncanta  = false;
  bool              _confirmDelete   = false;
  bool              _deletingReview  = false;
  bool              _sending         = false;
  bool              _loadingData     = true;
  final _ctrl = TextEditingController();

  bool get _isDemo => widget.menuSlug == null;

  @override
  void initState() {
    super.initState();
    _encantaTotal = widget.meEncantas;
    if (_isDemo) {
      _reviews     = List.from(_demoReviews);
      _loadingData = false;
    } else {
      _loadData();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    final slug      = widget.menuSlug!;
    final isLoggedIn = context.read<AuthContext>().isLoggedIn;

    final futures = await Future.wait([
      isLoggedIn
          ? InteraccionService.misResenas(slug)
          : InteraccionService.getResenas(slug),
      InteraccionService.getResumen(slug),
      if (isLoggedIn) InteraccionService.estadoEncanta(slug),
    ]);

    final rawReviews = futures[0] as List<dynamic>;
    final resumen    = futures[1] as Map<String, dynamic>?;
    final encanta    = futures.length > 2 ? futures[2] as Map<String, dynamic>? : null;

    if (!mounted) return;
    setState(() {
      _reviews      = rawReviews
          .whereType<Map<String, dynamic>>()
          .map(ReviewModel.fromJson)
          .toList();
      _myReview     = _reviews.any((r) => r.esPropia);
      _encantaTotal = (resumen?['meEncantas'] as num?)?.toInt() ?? widget.meEncantas;
      _meEncanta    = encanta?['meEncanta'] as bool? ?? false;
      _loadingData  = false;
    });
  }

  Future<void> _handleEncanta() async {
    final auth = context.read<AuthContext>();
    if (!auth.isLoggedIn) { _showAuthModal(); return; }
    if (_isDemo) return;
    setState(() => _loadingEncanta = true);
    try {
      final data = await InteraccionService.toggleEncanta(widget.menuSlug!);
      if (data != null && mounted) {
        setState(() {
          _meEncanta    = data['meEncanta'] as bool? ?? _meEncanta;
          _encantaTotal = (data['total'] as num?)?.toInt() ?? _encantaTotal;
        });
      }
    } finally {
      if (mounted) setState(() => _loadingEncanta = false);
    }
  }

  Future<void> _handleSendReview() async {
    final auth = context.read<AuthContext>();
    if (!auth.isLoggedIn) { _showAuthModal(); return; }
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final error = _validateReview(text);
    if (error != null) {
      _showSnack(error, isError: true);
      return;
    }
    setState(() => _sending = true);
    try {
      final data = await InteraccionService.crearResena(widget.menuSlug!, text);
      if (data != null && mounted) {
        final newReview = ReviewModel.fromJson(data);
        setState(() {
          _reviews   = [newReview, ..._reviews];
          _myReview  = true;
          _ctrl.clear();
        });
        _showSnack('¡Gracias por tu opinión!');
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _handleDeleteReview() async {
    setState(() => _deletingReview = true);
    try {
      await InteraccionService.eliminarResena(widget.menuSlug!);
      if (mounted) {
        setState(() {
          _reviews       = _reviews.where((r) => !r.esPropia).toList();
          _myReview      = false;
          _confirmDelete = false;
        });
      }
    } finally {
      if (mounted) setState(() => _deletingReview = false);
    }
  }

  void _showAuthModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: widget.theme.border, borderRadius: BorderRadius.circular(2))),
            Icon(Icons.lock_outline, size: 36, color: widget.theme.primary),
            const SizedBox(height: 12),
            Text('Inicia sesión',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: widget.theme.text)),
            const SizedBox(height: 6),
            Text('Necesitas una cuenta para realizar esta acción.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: widget.theme.textMuted)),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFef4444) : const Color(0xFF22c55e),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t          = widget.theme;
    final auth       = context.watch<AuthContext>();
    final isLoggedIn = auth.isLoggedIn;
    final userId     = auth.user?['userId'] as int?;
    final isOwner    = isLoggedIn && widget.ownerId != null && userId == widget.ownerId;
    final reviews    = _isDemo ? _demoReviews : _reviews;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: ícono + "RESEÑAS" + badge + "Me encanta" ──────────
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 16, color: t.primary),
                const SizedBox(width: 6),
                Text('RESEÑAS',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w900,
                    letterSpacing: 0.5, color: t.text,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: t.surfaceAlt,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${reviews.length}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.textMuted),
                  ),
                ),
                const Spacer(),
                // Botón Me encanta
                GestureDetector(
                  onTap: _loadingEncanta ? null : _handleEncanta,
                  child: AnimatedOpacity(
                    opacity: _loadingEncanta ? 0.5 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:        _meEncanta ? const Color(0xFFec4899) : t.surfaceAlt,
                        borderRadius: BorderRadius.circular(t.buttonRadius),
                        border:       Border.all(
                          color: _meEncanta ? const Color(0xFFec4899) : t.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _meEncanta ? Icons.favorite : Icons.favorite_border,
                            size: 13,
                            color: _meEncanta ? Colors.white : t.textMuted,
                          ),
                          if (_encantaTotal > 0) ...[
                            const SizedBox(width: 4),
                            Text('$_encantaTotal',
                              style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: _meEncanta ? Colors.white : t.textMuted,
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          Text('Me encanta',
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: _meEncanta ? Colors.white : t.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: t.border, height: 1),
          const SizedBox(height: 12),

          // ── Formulario o prompt de login ───────────────────────────────
          if (!_isDemo && !isOwner) ...[
            if (!isLoggedIn)
              GestureDetector(
                onTap: _showAuthModal,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: t.surfaceAlt,
                    borderRadius: BorderRadius.circular(t.cardRadius),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color:  t.primary.withValues(alpha: 0.12),
                          shape:  BoxShape.circle,
                        ),
                        child: Icon(Icons.chat_bubble_outline, size: 15, color: t.primary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('¿Quieres dejar tu reseña?',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.text)),
                          Text('Inicia sesión o regístrate →',
                            style: TextStyle(fontSize: 11, color: t.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else if (_myReview)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: t.surfaceAlt,
                  borderRadius: BorderRadius.circular(t.cardRadius),
                  border: Border.all(color: t.border),
                ),
                child: _confirmDelete
                    ? Row(
                        children: [
                          Text('¿Eliminar tu reseña?',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: Color(0xFFef4444))),
                          const Spacer(),
                          TextButton(
                            onPressed: _deletingReview ? null : () => setState(() => _confirmDelete = false),
                            child: Text('Cancelar', style: TextStyle(fontSize: 11, color: t.text)),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton(
                            onPressed: _deletingReview ? null : _handleDeleteReview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFef4444),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(_deletingReview ? 'Eliminando…' : 'Sí, eliminar'),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Text('Ya dejaste una reseña en este menú',
                            style: TextStyle(fontSize: 12, color: t.textMuted)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() => _confirmDelete = true),
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline, size: 13, color: Color(0xFFef4444)),
                                const SizedBox(width: 3),
                                const Text('Eliminar',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                                    color: Color(0xFFef4444))),
                              ],
                            ),
                          ),
                        ],
                      ),
              )
            else ...[
              // Textarea + botón enviar
              _ReviewForm(theme: t, ctrl: _ctrl, sending: _sending, onSend: _handleSendReview),
              const SizedBox(height: 12),
            ],
          ],

          // ── Lista de reseñas o estado vacío ────────────────────────────
          if (_loadingData)
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(color: t.primary),
            ))
          else if (reviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(children: [
                  Icon(Icons.chat_bubble_outline, size: 36,
                    color: t.textMuted.withValues(alpha: 0.3)),
                  const SizedBox(height: 8),
                  Text('Sé el primero en dejar una reseña',
                    style: TextStyle(fontSize: 13, color: t.textMuted)),
                ]),
              ),
            )
          else
            Column(
              children: reviews.map((rev) => _ReviewCard(review: rev, theme: t)).toList(),
            ),
        ],
      ),
    );
  }
}

// ── Widget del formulario de reseña ──────────────────────────────────────────
class _ReviewForm extends StatefulWidget {
  const _ReviewForm({
    required this.theme,
    required this.ctrl,
    required this.sending,
    required this.onSend,
  });
  final MenuTheme            theme;
  final TextEditingController ctrl;
  final bool                 sending;
  final VoidCallback         onSend;

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final t        = widget.theme;
    final text     = widget.ctrl.text;
    final error    = text.trim().isNotEmpty ? _validateReview(text.trim()) : null;
    final tooLong  = text.length > 150;
    final canSend  = text.trim().isNotEmpty && !tooLong && error == null && !widget.sending;
    final borderCol = (tooLong || (error != null && text.trim().isNotEmpty))
        ? const Color(0xFFef4444)
        : t.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(t.cardRadius),
                  border: Border.all(color: borderCol),
                ),
                child: TextField(
                  controller: widget.ctrl,
                  maxLines:   2,
                  minLines:   2,
                  maxLength:  150,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  style: TextStyle(fontSize: 13, color: t.text),
                  decoration: InputDecoration(
                    hintText:         'Comparte tu experiencia...',
                    hintStyle:        TextStyle(fontSize: 13, color: t.textMuted),
                    border:           InputBorder.none,
                    contentPadding:   const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: canSend ? widget.onSend : null,
              child: AnimatedOpacity(
                opacity: canSend ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color:        t.primary,
                    borderRadius: BorderRadius.circular(t.buttonRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.send_outlined, size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(widget.sending ? 'Enviando…' : 'Enviar',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (error != null && text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(error,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFef4444))),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${150 - text.length} caracteres restantes',
              style: TextStyle(
                fontSize: 11,
                color: tooLong ? const Color(0xFFef4444) : t.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Card de una reseña ────────────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.theme});
  final ReviewModel review;
  final MenuTheme   theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        t.surface,
        borderRadius: BorderRadius.circular(t.cardRadius),
        border:       Border.all(color: t.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          _Avatar(nombre: review.autorNombre, avatar: review.autorAvatar, theme: t),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.autorNombre,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      review.tiempoRelativo ?? 'hace unos días',
                      style: TextStyle(fontSize: 11, color: t.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  review.texto,
                  style: TextStyle(fontSize: 13, height: 1.5, color: t.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.nombre, this.avatar, required this.theme});
  final String    nombre;
  final String?   avatar;
  final MenuTheme theme;

  @override
  Widget build(BuildContext context) {
    if (avatar != null && avatar!.isNotEmpty) {
      return ClipOval(
        child: Image.network(avatar!,
          width: 36, height: 36, fit: BoxFit.cover,
          errorBuilder: (ctx, e, st) => _initials(),
        ),
      );
    }
    return _initials();
  }

  Widget _initials() => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: theme.primary, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      );
}
