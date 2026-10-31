// Un tema del menú: estilo (skin) y paleta de colores. Los ids pueden venir como número o texto.
class TemaElegido {
  const TemaElegido(this.skin, this.paleta);
  final Object? skin;
  final Object? paleta;

  bool igualA(TemaElegido otro) => '$skin' == '${otro.skin}' && '$paleta' == '${otro.paleta}';
}
