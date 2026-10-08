# Atividade — Navegação (Drawer + BottomNavigationBar) · Projeto Códice

**Arquivo:** `AtvNavegacao.dart` (o mesmo código está no `main.dart`)
**Dupla:** Ramon Couto Santo e Aaron Guerra Goldberg

Navigator nativo do Flutter, sem pacotes externos de navegação. Dados
mockados em memória.

## Como as pilhas estão organizadas

```
Navigator RAIZ (MaterialApp)
  /               login
  /app            AppShell: Drawer + BottomNavigationBar
  /configuracoes  push por cima do app (a barra inferior some)

AppShell: IndexedStack com 1 Navigator por aba
  Navi       /navi
  Conversa   /conversa
  Diário     /diario
  Cidade     /cidade > /cidade/lugar
  Encontros  /encontros > /encontros/navi > /encontros/apelido
```

## Requisitos

| # | Requisito | Onde está |
|---|---|---|
| 1 | Rotas nomeadas centralizadas | Classe `Rotas`: constantes de nome, `Rotas.mapa` no `MaterialApp.routes` e `Rotas.gerar` no `MaterialApp.onGenerateRoute`. Os Navigators das abas usam o mesmo `Rotas.gerar` |
| 2 | Drawer com 3 itens | `MenuLateral`: **Configurações** (`pushNamed`), **Sobre** (`AlertDialog`) e **Sair** (`pushReplacementNamed('/')`) |
| 3 | Abas com pilha preservada | `AppShell`: `IndexedStack` com um `Navigator` (e uma `GlobalKey`) por aba. Trocar de aba não descarta nenhuma pilha |
| 4 | Parâmetros via arguments | `/cidade/lugar` recebe um `Lugar`; `/encontros/navi` recebe um `NaviEncontrado` |
| 5 | Retorno com `Navigator.pop(valor)` | `ApelidoScreen` devolve o apelido com `Navigator.pop(context, apelido)`. A `NaviScreen` espera com `await pushNamed<String>` |
| 6 | Voltar do sistema respeita cada aba | `PopScope` no `AppShell`: fecha o Drawer, ou faz pop na aba atual, ou volta para a aba Navi, ou fecha o app |

Extra: tocar de novo na aba aberta volta para a raiz dela (`popUntil`).

## Logs (`debugPrint`)

Cada Navigator tem um `ObservadorDaPilha` (um `NavigatorObserver`) que
imprime a operação e como a pilha ficou depois dela:

```
[Encontros] pushNamed(/encontros/navi, arguments: Pixel)
[pilha Encontros] PUSH /encontros/navi  =>  [/encontros > /encontros/navi]
[Encontros] pushNamed<String>(/encontros/apelido, arguments: "Pixel")
[pilha Encontros] PUSH /encontros/apelido  =>  [/encontros > /encontros/navi > /encontros/apelido]
[Apelido] Navigator.pop(context, "Faísca")
[pilha Encontros] POP  /encontros/apelido  =>  [/encontros > /encontros/navi]
[Encontros] ApelidoScreen devolveu: "Faísca"
[abas] Encontros -> Cidade  (pilha preservada: [/cidade > /cidade/lugar])
[voltar] pop na pilha da aba Encontros
[pilha Encontros] POP  /encontros/navi  =>  [/encontros]
```

## Prints (roteiro)

1. **Drawer aberto:** em qualquer aba, tocar no ícone ☰ ao lado do título.
2. **Empilhamento numa aba:** Encontros → Pixel → "dar um apelido". O título
   "Encontros / apelido" e a seta de voltar mostram a terceira tela da pilha,
   com a barra inferior ainda visível.
3. **Console:** o terminal do `flutter run` depois do passo 2, mais uma troca
   de aba e um voltar do Android (logs como os de cima).

## Descrição

**Por que Navigators aninhados (dentro de um `IndexedStack`)?**

Só o `IndexedStack` não bastava. Ele mantém as telas vivas, mas, com um
Navigator só, qualquer `push` dentro de uma aba entraria na pilha global,
por cima da barra inferior, e as pilhas das abas iam se misturar. Com um
Navigator por aba, cada seção tem o seu próprio histórico. Quando a pessoa
abre o Pixel em Encontros, a tela entra na pilha de Encontros, e a barra
continua embaixo. As duas peças se completam: o `IndexedStack` mantém os
cinco Navigators montados, então a pilha de uma aba (e o texto do Diário
pela metade) continua lá quando a pessoa troca de aba e depois volta.

Também ficou clara a divisão entre as duas pilhas. O que é **da seção** vai
para o Navigator da aba: detalhe do lugar, do NAVI, tela de apelido. O que
é **do app inteiro** vai para o Navigator raiz: Configurações entra com
`push` por cima de tudo, e o logout usa `pushReplacement`, porque o login
tem que **substituir** o app. Se fosse um `push`, o voltar do Android
levaria a pessoa de volta para dentro do app depois de sair.

**Principal dificuldade técnica**

O botão voltar do Android. O evento chega só ao Navigator raiz, que não
conhece as pilhas das abas. Para ele, o app inteiro é uma rota só (`/app`).
Então, com a pessoa na terceira tela de Encontros, o voltar tentava fechar
o app em vez de voltar uma tela.

Resolvemos com um `PopScope(canPop: false)` em volta do `AppShell`. Ele
segura o voltar e o `_voltar()` decide, em ordem: se o Drawer está aberto,
fecha o Drawer (o `PopScope` também bloqueava esse fechamento); se a aba
atual tem histórico, faz `maybePop` no Navigator **dessa aba**, encontrado
pela `GlobalKey`; se a aba está na raiz, vai para a aba Navi; e só na raiz
da Navi o app fecha.

Uma dificuldade menor: `pushNamed<String>` quebrava com erro de tipo,
porque o `onGenerateRoute` criava uma `MaterialPageRoute<dynamic>`. A rota
de apelido passou a ser criada como `MaterialPageRoute<String>`.
