import 'package:flutter/material.dart';
import 'package:codice_app/controllers/sessao.dart';
import 'package:provider/provider.dart';
import 'package:codice_app/models/memoria.dart';
import 'package:codice_app/tema/cores.dart';
import 'package:codice_app/tema/estilos.dart';
import 'package:codice_app/widgets/basicos.dart';

/// "Posso guardar isso?" — nada vira memória sem confirmação.
Future<bool?> confirmarGuardar(
  BuildContext context,
  String texto,
  Set<String> etiquetas,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Posso guardar isso?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('«$texto»', maxLines: 4, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Text(
            etiquetas.isEmpty
                ? 'sem etiqueta — vai como "geral".'
                : 'etiquetas: ${etiquetas.join(', ')}',
            style: const TextStyle(color: Cores.roxoClaro, fontSize: 12),
          ),
          const SizedBox(height: 6),
          const Text(
            'nada vira memória sem você confirmar.',
            style: Estilos.legenda,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('ainda não'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('pode guardar'),
        ),
      ],
    ),
  );
}

/// Pergunta da contradição: true = mudou (substitui a antiga).
Future<bool?> perguntarContradicao(BuildContext context, Memoria antiga) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Cores.ambarFundo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Cores.ambarBorda),
      ),
      icon: const Icon(Icons.favorite_border, color: Cores.ambar),
      title: const Text('«Você mudou de emprego?»'),
      content: Text(
        'antes você me contou: «${antiga.texto}»\n\n'
        'dois fatos que eu guardo se contradizem.',
        style: const TextStyle(color: Cores.ambarTexto, fontSize: 13),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Cores.ambar),
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('não, é o mesmo'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Cores.ambar,
            foregroundColor: Cores.sobreAmbar,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('sim, mudei'),
        ),
      ],
    ),
  );
}

Future<String?> pedirNovaEtiqueta(BuildContext context) async {
  // O controller não é descartado aqui: o diálogo ainda usa o campo
  // durante a animação de saída.
  final campo = TextEditingController();
  final nome = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('nova etiqueta'),
      content: TextField(
        controller: campo,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'ex: família'),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, campo.text),
          child: const Text('adicionar'),
        ),
      ],
    ),
  );
  return nome?.trim();
}

/// Lista do que a NAVI sabe (aberta pelo selo ou segurando a NAVI).
void mostrarMemorias(BuildContext context, List<Memoria> memorias) {
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'o que ${ctx.read<Sessao>().perfil.nome} sabe (${memorias.length})',
            style: Estilos.tituloDialogo,
          ),
          const SizedBox(height: 2),
          const Text('só o que você confirmou.', style: Estilos.legenda),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: memorias.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _CartaoMemoria(memorias[i]),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CartaoMemoria extends StatelessWidget {
  final Memoria memoria;

  const _CartaoMemoria(this.memoria);

  @override
  Widget build(BuildContext context) {
    final q = memoria.quando;
    return Painel(
      raio: BorderRadius.circular(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            memoria.texto,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Estilos.corpo,
          ),
          const SizedBox(height: 6),
          Text(
            '${memoria.etiquetas.join(' · ')}  ·  ${q.day}/${q.month}',
            style: const TextStyle(color: Cores.roxoClaro, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
