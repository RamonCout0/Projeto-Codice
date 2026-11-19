# Além das atividades

Projeto Códice · Desenvolvimento para Dispositivos Móveis

As atividades pedidas na disciplina (eventos, navegação, estado global com
Provider, layout responsivo e comunicação segura) têm cada uma o seu registro.
Este documento descreve o que foi adicionado ao app **por conta própria**, fora
desses enunciados, para aproximar o Códice da ideia original do projeto: uma
NAVI que conversa, reage e aparece como uma personagem de verdade.

## Resumo

| Recurso | O que faz | Onde está |
| --- | --- | --- |
| Conversa com IA local | A NAVI responde com um modelo de linguagem rodando no PC (Ollama + Gemma) | `lib/services/conversa_gemma.dart` |
| Personalidade do NAVI | Nome, elemento, traços e gostos, salvos na conta, que o Gemma interpreta | `lib/models/perfil_navi.dart`, `lib/views/perfil_navi_tela.dart` |
| Manter conectado | Com a opção marcada, o app reabre direto no NAVI da conta | `lib/controllers/sessao.dart` |
| NAVI em 3D | Modelo VRM animado com three.js: respira, pisca, muda de expressão e mexe a boca | `navi_3d/src/`, `lib/widgets/navi_3d.dart` |
| Animações do Mixamo | Aceita `.fbx` do Mixamo e converte para o esqueleto do VRM | `navi_3d/src/mixamo.js` |
| 3D na web | A mesma NAVI 3D roda no navegador, além do Android e do iOS | `lib/widgets/navi_3d/` |
| Pasta da apresentação | Carrega modelo e animações sem importar nada pela tela | `assets/navi_local/` |
| Importar NAVI | Tela para trazer o `.vrm` e as animações para o app | `lib/views/importar_navi_tela.dart` |

## Conversa com a NAVI (Ollama + Gemma)

A aba **Conversa** usa o modelo **gemma3:1b** rodando no
[Ollama](https://ollama.com), no próprio PC. O app manda as mensagens para a
API `/api/chat` e mostra a resposta conforme ela vai sendo escrita
(streaming).

- A NAVI recebe uma instrução de sistema montada a partir do **perfil**
  (veja abaixo), da **vida dela no app** (lugares da Cidade e NAVIs que
  conheceu nos Encontros) e das **memórias do Diário**. O histórico da
  conversa vai junto em cada pergunta.
- Regras do prompt: quando perguntam sobre ela, conta algo concreto da
  própria vida antes de perguntar; sobre a pessoa, usa só o que está escrito
  no diário ou na conversa, sem inventar detalhes; não repete a pergunta
  anterior.
- A resposta aparece em **ritmo de fala** (cerca de 25 letras por segundo,
  com pausas em vírgulas e pontos), para a boca do modelo 3D acompanhar. O
  Gemma escreve bem mais rápido do que isso; o texto espera numa fila.
- Emojis são filtrados: o `gemma3:1b` às vezes ignora a regra do prompt.
- O humor da NAVI muda conforme a resposta: *pensando* enquanto espera,
  *curiosa* quando ela pergunta algo, *feliz* quando responde e *confusa*
  quando dá erro.
- O endereço do Ollama é configurável em **Menu → Configurações**, ou na hora
  de rodar com `--dart-define=OLLAMA_URL=http://IP-DO-PC:11434`.

O modelo (~800 MB) não vai para o repositório: cada máquina instala o seu com
`ollama pull gemma3:1b`. Ele é pequeno e às vezes enfeita a resposta. Para
uma NAVI mais esperta, dá para instalar o `gemma3:4b` (~3,3 GB) e trocar o
modelo em **Menu → Configurações**.

**Sem placa de vídeo** (notebook só com vídeo integrado), o Ollama roda na CPU.
Medido na CPU, o `gemma3:1b` gera cerca de 28 tokens/s, bem acima do ritmo de
fala da NAVI (cerca de 6 tokens/s). O `gemma3:4b` fica em torno de 7 a 10
tokens/s: acompanha a fala, mas a primeira resposta pode levar uns 30 s. Para
apresentar, o `1b` é o mais seguro.

Para não esperar na primeira pergunta, o app **aquece** o Gemma assim que abre:
manda a personalidade e o diário antes, e o Ollama guarda essa leitura. Ele
também pede para o modelo ficar carregado por 30 minutos (`keep_alive`). Antes
de apresentar, vale abrir a aba Conversa uma vez.

## Personalidade do NAVI

Na criação da conta (ou em **Menu → Personalidade**, ou tocando no nome na
Home), a pessoa define:

| Campo | Opções |
| --- | --- |
| Nome | até 20 caracteres |
| Elemento | Gelo, Fogo, Água, Terra, Ar, Luz, Sombra ou Elétrico |
| Personalidade | de 1 a 3 traços: curiosa, tímida, brincalhona, carinhosa, teimosa, corajosa, sonhadora, organizada, dramática, calma |
| Do que gosta | texto livre, até 140 caracteres |

Cada elemento e traço tem uma descrição de comportamento (por exemplo, Fogo:
*animada e intensa; fala com entusiasmo*). Essas descrições viram o texto de
personalidade que o Gemma recebe, e a própria tela mostra uma prévia dele
("como o Gemma vai interpretar"). O elemento também dá a cor do app: o
palco, o brilho atrás do busto na Conversa e o contorno do retrato.

O perfil fica salvo na conta pela API (`GET`/`PUT /perfil`) e numa cópia no
armazenamento seguro, quando a pessoa marca **manter conectado**. Assim, ao
reabrir, o app vai direto para a Home com o NAVI dela. Sem conta, o perfil
fica só no aparelho.

## NAVI em 3D (VRM + three.js)

A NAVI deixou de ser uma imagem e passou a ser um modelo 3D no formato
**VRM**, o formato do VRoid Studio. Ela é desenhada por uma página
**three.js + three-vrm** que roda dentro do app:

- **Android/iOS:** numa WebView. Os arquivos são entregues por um pequeno
  servidor HTTP que só existe dentro do aparelho (`127.0.0.1`).
- **Web:** num iframe da mesma origem do app, conversando com o Flutter por
  `postMessage`.

A animação é feita em camadas, recalculadas a cada quadro:

1. **Corpo:** animações prontas (`.vrma` ou Mixamo), quando existem. Sem elas,
   o próprio app calcula uma animação simples: respirar, balançar e acenar.
2. **Cabeça:** inclinação conforme o humor, somada por cima do corpo.
3. **Rosto:** expressão do humor, piscar de olhos e boca se mexendo enquanto
   ela "fala" (sincronizado com a resposta do Gemma).

O cabelo e a roupa têm física própria do VRM (*spring bones*). A foto pequena
da NAVI (Diário, Conversa, menu) é **tirada do próprio modelo** depois que
ele carrega, então sempre combina com a personagem escolhida.

Detalhes de comportamento:

- Ao tocar nela, ela acena, uma vez a cada 8 segundos no máximo, para não
  repetir o gesto a cada toque.
- Quando a aba fica escondida, o desenho é pausado para economizar bateria.
- Na Home, a câmera enquadra o corpo inteiro com os pés na base do palco.

## Animações do Mixamo

O [Mixamo](https://www.mixamo.com) (Adobe) tem milhares de animações gratuitas
de personagens, mas elas usam outro esqueleto (`mixamorig`) e outra pose de
descanso. O arquivo `navi_3d/src/mixamo.js` faz a **conversão
(retargeting)** para o esqueleto humanoide do VRM:

1. Lê o `.fbx` com o `FBXLoader` do three.js.
2. Para cada osso, troca o nome do Mixamo pelo osso equivalente do VRM
   (quadril, coluna, braços, pernas e todos os dedos).
3. Remove a rotação de descanso do Mixamo e leva o movimento para o espaço do
   osso "normalizado" do VRM.
4. Ajusta a altura do quadril à altura do modelo e trava o deslocamento
   horizontal, para a NAVI não sair do enquadramento.
5. Corrige a orientação de modelos VRM 0.x, que olham para o lado oposto.

As animações têm três momentos:

| Animação | Quando toca |
| --- | --- |
| Parada | o tempo todo, em repetição |
| Aceno | quando você toca na NAVI |
| Comemorar | quando ela fica feliz |

Cada uma pode ser `.vrma` (VRM Animation) ou `.fbx` do Mixamo. Para baixar do
Mixamo: escolha a animação, **Download → Format: FBX Binary (.fbx)**,
**Skin: Without Skin**. Para animações de andar ou correr, marque **In Place**.

## 3D na web

Para que a apresentação funcione no navegador (`flutter run -d edge`), o
visualizador ganhou uma segunda implementação:

- `lib/widgets/navi_3d/visualizador.dart` define a interface comum.
- `visualizador_io.dart` (celular) usa WebView e o servidor local.
- `visualizador_web.dart` (navegador) usa um iframe e passa os arquivos como
  URL: do próprio app ou `blob:` para arquivos importados na aba.

O Dart escolhe a implementação certa na compilação, com *import
condicional*. O resto do app usa só o widget `Navi3D`, sem saber em qual
plataforma está.

## Pasta da apresentação (`assets/navi_local/`)

O `flutter run -d edge` abre um navegador com perfil novo toda vez, então um
modelo importado pela tela se perderia a cada execução. Para apresentar, os
arquivos podem ficar nesta pasta:

```
assets/navi_local/
├── modelo.vrm
├── parada.fbx      (ou .vrma)
├── aceno.fbx       (ou .vrma)
└── comemorar.fbx   (ou .vrma)
```

O app carrega tudo sozinho, na web e no celular. O que for importado pela tela
**Importar NAVI** tem prioridade sobre a pasta.

## Licenças dos modelos

Modelos `.vrm` e animações têm licenças próprias: alguns não permitem
redistribuição, e as animações do Mixamo podem ser usadas em projetos, mas não
redistribuídas como arquivos soltos. Por isso **nenhum desses arquivos vai para
o GitHub**. O `.gitignore` bloqueia `*.vrm`, `*.vrma`, `*.fbx` e o conteúdo de
`assets/navi_local/`, e cada pessoa coloca os seus arquivos localmente.

## Como testar

```powershell
flutter pub get
flutter run -d edge
```

Com `assets/navi_local/modelo.vrm` no lugar, a Frost aparece em 3D na Home
(corpo inteiro) e na Conversa (busto). Na primeira abertura ela leva alguns
segundos para carregar; até lá aparece só a barra de progresso. Sem nenhum
modelo, o palco fica vazio, com um atalho para importar um `.vrm`.

Para alterar o visualizador 3D (`navi_3d/src/`), gere o bundle de novo:

```powershell
cd navi_3d
npm install
npm run build
```
