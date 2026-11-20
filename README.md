# Projeto Códice

> Um diário pessoal onde uma criatura digital aprende com a convivência.

O Projeto Códice é um aplicativo móvel de diário pessoal e assistência. O
usuário cria um NAVI, uma criatura digital que começa criança e aprende com o
que é compartilhado ao longo do tempo.

## O NAVI

O NAVI nasce aos **8 anos** e é analfabeto: ele não sabe nada além do que o
usuário ensina. O diário é a principal forma de entrada. Nele, o usuário pode
registrar acontecimentos, compromissos e informações para que o NAVI possa
lembrar e ajudar no dia a dia.

O NAVI também percebe outros NAVIs próximos por Bluetooth. Quando dois aparelhos
se encontram, os NAVIs conversam, criam afinidade e podem contar ao usuário o
que acharam do encontro. A interação acontece entre os NAVIs, sem revelar a
identidade real dos usuários.

## NAVICity

A NAVICity é o mundo onde os NAVIs vivem e continuam suas próprias rotinas.
Mesmo quando o usuário não está usando o aplicativo, o seu NAVI pode passear,
encontrar outros NAVIs e participar de acontecimentos dentro da cidade.

O usuário não controla tudo o que acontece na NAVICity. Ao retornar ao
aplicativo, ele recebe um relato do que o seu NAVI fez, incluindo encontros,
amizades e situações inesperadas. Assim, a cidade parece continuar existindo
mesmo quando não está sendo observada.

Os lugares da NAVICity possuem nomes e características próprias. Alguns são
revelados conforme o usuário passa fisicamente por locais correspondentes no
mundo real. Assim, o mapa é descoberto aos poucos.

## Navidês

Navidês é a linguagem usada pelos NAVIs quando conversam entre si. Ela não é
formada por palavras, mas por bipes, ritmos, pausas e diferentes entonações.
Cada NAVI se expressa de uma maneira própria, de acordo com sua personalidade
e com a relação que possui com os outros.

O usuário não precisa entender a conversa em Navidês. Depois do encontro, o
NAVI pode voltar a falar em português e contar o que achou da situação. Dessa
forma, a linguagem mantém os NAVIs independentes sem deixar a interação confusa
para quem está usando o aplicativo.

## Progressão

A idade representa o conhecimento adquirido pela convivência:

| Fase | Idade | O que está disponível |
| --- | ---: | --- |
| Criança | 8 anos | Diário, conversa, memória e assistência pessoal |
| Adolescente | 14 anos | NAVICity, mapa, conversa entre NAVIs e apelidos |
| Adulto | 18 anos | Conclusão da primeira etapa e autonomia total |

O NAVI cresce por convivência e conhecimento compartilhado, não por compras ou
repetição. A primeira etapa se encerra aos 18 anos.

## Escopo da primeira etapa

O projeto atual acompanha o NAVI desde o nascimento até a fase adulta, com
diário, memória, assistência pessoal, encontros por Bluetooth, afinidade e
NAVICity.

> A primeira etapa se encerra aos 18 anos.

## Rodando no celular

Precisa do Flutter 3.32+ e do JDK 17. Ative a depuração USB no Android,
conecte o cabo e, na pasta do projeto:

```sh
flutter pub get
flutter devices   # o celular tem que aparecer aqui
flutter run       # instala e abre no aparelho
```

Para gerar um APK e mandar para o celular: `flutter build apk --debug`
(o arquivo sai em `build/app/outputs/flutter-apk/`). No PC, o app aparece
dentro de uma moldura de celular; no aparelho ele ocupa a tela toda.

## Conversa com o Gemma (Ollama no PC)

A conversa usa o **gemma3:1b** rodando no [Ollama](https://ollama.com), no
PC. O modelo (~800 MB) não vai para o GitHub: cada máquina instala o seu.

1. Instale o Ollama e baixe o modelo:
   ```sh
   ollama pull gemma3:1b
   ```
2. Deixe o Ollama aceitar conexões da rede (o celular fala com o PC pelo
   Wi-Fi). No Windows, crie a variável de ambiente `OLLAMA_HOST=0.0.0.0`,
   feche o Ollama pela bandeja e abra de novo. Se o Firewall perguntar,
   libere a rede privada (porta 11434).
3. Descubra o IP do PC (`ipconfig`, linha "Endereço IPv4") e, no app, abra
   **Menu → Configurações** e coloque `http://IP-DO-PC:11434`. Toque em
   "salvar e testar".

Celular e PC precisam estar na mesma rede Wi-Fi. No emulador Android o
endereço padrão `http://10.0.2.2:11434` já aponta para o PC. Também dá para
fixar o endereço na hora de rodar:
`flutter run --dart-define=OLLAMA_URL=http://192.168.0.10:11434`.

A NAVI recebe as memórias guardadas no Diário junto com cada pergunta.

## NAVI em 3D (VRM)

O app mostra a NAVI em 3D a partir de um modelo **.vrm** (o formato do
VRoid). O modelo é importado no próprio celular: **Menu → Importar NAVI**
(ou "trocar NAVI" na Home). Copie o `.vrm` para o celular por cabo, Drive ou
e-mail e escolha o arquivo. Nenhum `.vrm` vai para o repositório, porque cada
modelo tem a sua licença (a Alice, por exemplo, não permite redistribuir).

Na mesma tela dá para importar **animações prontas**, em três momentos. Vale
`.vrma` (como as do VRoid Motion Pack) ou `.fbx` do **Mixamo**: o visualizador
converte o esqueleto do Mixamo para o do VRM sozinho (`navi_3d/src/mixamo.js`).
No [mixamo.com](https://www.mixamo.com), baixe em **FBX Binary (.fbx)**, com
**Without Skin**. Os arquivos também ficam só no aparelho.

| Animação | Quando toca |
| --- | --- |
| Parada | o tempo todo, em repetição |
| Aceno | quando você toca na NAVI |
| Comemorar | quando ela fica feliz |

Sem animações importadas, a NAVI usa movimentos simples feitos pelo próprio app
(respirar, balançar e acenar). Por cima de qualquer animação, o app controla
o rosto: pisca, muda a expressão conforme o humor e mexe a boca enquanto o
Gemma responde. A foto pequena da NAVI (Diário, Conversa, menu) é tirada do
próprio modelo depois que ele carrega.

O 3D funciona no Android, no iOS e na web (`flutter run -d edge`). Na web,
o que é importado pela tela vale só até fechar a aba, e o `flutter run -d edge`
abre um navegador limpo a cada execução. Para apresentar, coloque os arquivos em
[assets/navi_local/](assets/navi_local/LEIA-ME.md) (`modelo.vrm`,
`parada.fbx`, `aceno.fbx`, `comemorar.fbx`): o app carrega tudo sozinho, na web
e no celular, e a pasta fica fora do Git.

O 3D roda numa WebView com [three.js](https://threejs.org) e
[three-vrm](https://github.com/pixiv/three-vrm). O código fica em `navi_3d/`
e é empacotado em `assets/navi_3d/navi.js`. Para alterar:

```sh
cd navi_3d
npm install
npm run build
```

No app de desktop do Windows o 3D não aparece. Sem modelo, a NAVI fica vazia
até você importar um `.vrm` (o app não traz imagem pronta).

## Organização do código

```
lib/
  main.dart          ponto de entrada
  app/               MaterialApp, Provider, rotas, abas e moldura do PC
  tema/              visual: cores, estilos de texto, ThemeData, imagens
  widgets/           componentes compartilhados (AvatarNavi, Navi3D, Painel…)
  models/ data/      dados: memórias, mensagens, lugares, humor, ajustes
  services/          diário, conversa com o Gemma e arquivos/servidor do 3D
  controllers/       estado compartilhado entre telas (memórias, apelidos)
  views/<tela>/      cada tela na sua pasta, com as partes dela ao lado
navi_3d/             visualizador VRM (JavaScript) usado pela WebView
```

Nenhuma tela declara cor ou estilo solto: tudo vem de `tema/`. A NAVI só é
desenhada pelo `widgets/avatar_navi.dart`.

As atividades entregues para a disciplina ficam na branch `Atividades`.

## Projeto acadêmico

Desenvolvido para a disciplina de Desenvolvimento para Dispositivos Móveis por
**Ramon Couto Santo** e **Aaron Guerra Goldberg**.

**Referências:** Pokémon GO, Mega Man NT Warrior, POU e Waze.

Link do Figma:https://www.figma.com/design/Do7j79OBvSKrucbwdNoc1S/C%C3%B3dice?node-id=0-1&t=tFKnwnIfS7nye4Rc-1

## Comunicação segura

Cadastro e login no próprio app, JWT guardado com segurança e consulta
protegida de NAVIs. Para usar no PC, rode a API antes (`node api/servidor.mjs`,
sem configurar nada). Na tela inicial, **criar meu NAVI** abre o cadastro e
**já tenho um códice** abre o login. Os dois têm **entrar sem conta**.

- [Atividade de comunicação segura](COMUNICACAO_SEGURA.md)
- [Relatório da atividade](Relatorio_Comunicacao_Segura.pdf)
- API de exemplo: [api/servidor.mjs](api/servidor.mjs)

## Servidor da NAVICity

A cidade que continua viva com o app fechado roda num servidor próprio, em Go,
com API de requisições assinadas (Ed25519). Veja [servidor/README.md](servidor/README.md).

## Além das atividades

Conversa com IA local, NAVI em 3D, animações do Mixamo e 3D na web:
[ALEM_DAS_ATIVIDADES.md](ALEM_DAS_ATIVIDADES.md).
