import 'package:flutter/material.dart';
import 'package:codice_app/app/rotas.dart';

class Aba {
  final String nome;
  final String rota;
  final IconData icone;

  const Aba(this.nome, this.rota, this.icone);
}

const List<Aba> abas = [
  Aba('Navi', Rotas.navi, Icons.sentiment_satisfied_alt_outlined),
  Aba('Conversa', Rotas.conversa, Icons.chat_bubble_outline),
  Aba('Diário', Rotas.diario, Icons.article_outlined),
  Aba('Cidade', Rotas.cidade, Icons.account_balance_outlined),
  Aba('Encontros', Rotas.encontros, Icons.people_outline),
];
