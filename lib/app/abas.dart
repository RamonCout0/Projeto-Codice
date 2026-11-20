import 'package:codice_app/app/rotas.dart';
import 'package:codice_app/widgets/icones.dart';

class Aba {
  final String nome;
  final String rota;
  final Ic icone;

  const Aba(this.nome, this.rota, this.icone);
}

const List<Aba> abas = [
  Aba('Navi', Rotas.navi, Ic.navi),
  Aba('Conversa', Rotas.conversa, Ic.conversa),
  Aba('Diário', Rotas.diario, Ic.diario),
  Aba('Cidade', Rotas.cidade, Ic.cidade),
  Aba('Encontros', Rotas.encontros, Ic.pessoas),
];
