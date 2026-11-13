class Mensagem {
  final bool daNavi;
  String texto;

  Mensagem.daNavi(this.texto) : daNavi = true;
  Mensagem.daPessoa(this.texto) : daNavi = false;
}
