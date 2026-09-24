# Atividade — Eventos em Flutter · Projeto Códice

**Tela:** Diário (arquivo `AtvEventos.dart`, o mesmo código está no `main.dart`)
**Dupla:** Ramon Couto Santo e Aaron Guerra Goldberg

No Diário, o usuário escreve sobre o dia e a NAVI Frost só aprende o que ele
confirma. Todo evento da tela segue o ciclo **captura → processamento →
resposta** (e-book, cap. 6, "O princípio da orquestração de eventos").

## Eventos implementados

| Componente | Evento | O que acontece |
|---|---|---|
| `TextField` do diário | `onChanged` | Conta as palavras, imprime o valor no console (`debugPrint`), acende as etiquetas sugeridas e libera ou bloqueia o botão guardar (mínimo de 5 palavras) |
| `TextField` do diário | foco (`FocusNode`) | A borda da página acende quando o campo recebe foco |
| Botão **guardar no diário** | `onPressed` | Só funciona com 5 palavras ou mais. Valida, abre um `AlertDialog`, mostra "lendo…", guarda a memória e mostra uma `SnackBar` |
| Botão **apagar** | `onPressed` | Toque curto só mostra uma dica, para ninguém perder o texto sem querer |
| Botão **apagar** | `onLongPress` | Apaga o texto e mostra uma `SnackBar` com a ação **desfazer** |
| Avatar da Frost (`GestureDetector`) | `onTap` | Ela diz o que entendeu até agora |
| Avatar da Frost | `onDoubleTap` | Carinho: o contador de corações sobe e o balão fica rosa |
| Avatar da Frost | `onLongPress` | Abre a lista do que ela sabe (bottom sheet) |
| Etiquetas (`InkWell`) | `onTap` | Marca ou desmarca a etiqueta. O "+" abre um diálogo para criar uma etiqueta nova |

## Encadeamento de eventos

**guardar** → valida o mínimo de palavras → `AlertDialog` "Posso guardar
isso?" → (confirmou) "lendo…" por 1,2 s → a memória entra na lista, a barra
"rumo aos 14" sobe e a Frost fala → `SnackBar` com a ação **ver**, que abre a
lista de memórias → **se o texto fala de emprego e já existe uma memória de
emprego, ela abre sozinha um segundo `AlertDialog`: «Você mudou de
emprego?»**

Outros dois encadeamentos: **desfazer** na SnackBar devolve o texto e chama o
`onChanged` pelo código, porque uma alteração feita por código não dispara o
evento sozinha. E cruzar o limite de 5 palavras faz a Frost reagir sozinha.

## Eventos simultâneos

- Enquanto o guardar está em andamento, uma trava (`_processando`) desabilita
  o botão, o campo, o apagar e os gestos. Um toque duplo não cria duas
  memórias.
- Cada SnackBar nova esconde a anterior (`hideCurrentSnackBar`), então os
  avisos não formam fila e o que aparece é sempre o último evento.
- Cada fala nova da Frost cancela o timer da fala anterior: quem chega por
  último vence.
- Como a Frost reconhece toque **e** duplo toque, o `onTap` espera alguns
  milissegundos para ter certeza de que não é um duplo toque. É a
  desambiguação de gestos que o e-book descreve em "Eventos compostos e
  conflitos de gestos".

## Decisão de design

**O botão guardar fica desabilitado em vez de mostrar um erro depois do
clique.** O próprio botão diz "escreva mais 3 palavras", e o rodapé da
página mostra "faltam 3 para ela entender". Assim a condição fica visível
antes da ação, e não vira castigo depois. O e-book trata o clique como um
**"contrato de confiança"**: cada botão deve fazer exatamente o que promete.
Pelo mesmo motivo, **apagar exige segurar**: é uma ação destrutiva e não pode
acontecer por acidente. Ainda assim, pode ser desfeita.

## Prints (roteiro)

1. **Campo de texto:** digitar "Acordei cansado, a prova ficou pra quinta"
   (etiquetas *sono* e *prova* acendem, contador e status mudando).
2. **Botão:** tocar em guardar e mostrar o `AlertDialog` "Posso guardar
   isso?" (ou a SnackBar "memória guardada").
3. **Gesto:** dois toques na Frost (corações no balão) ou segurar (lista do
   que ela sabe).

Extra para a apresentação: escrever "Comecei num emprego novo hoje, no café
da esquina" e guardar. A pergunta sobre a contradição aparece
sozinha.
