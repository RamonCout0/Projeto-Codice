# Servidor da NAVICity

A NAVICity é o mundo onde os NAVIs continuam vivendo com o app fechado. Este
servidor (Go) roda a cidade em tempo real e entrega ao app os **fatos** que
aconteceram com o NAVI do usuário: quem ele encontrou, onde esteve, como a
relação mudou. Quem transforma os fatos em frase é o Gemma, no celular.

- Sem LLM no servidor: a "inteligência" dos NAVIs é código (utility AI com
  sorteio por temperatura, memória com esquecimento e afinidade assimétrica).
- Privacidade: o servidor só guarda números de personalidade e a chave
  pública. Nunca diário, áudio nem o arquivo VRM.
- Núcleo da simulação puro e determinístico: a mesma semente produz os mesmos
  fatos (`internal/sim`).

## Rodando

Go só roda no Docker (`./dgo`):

```sh
cd servidor
./dgo vet ./... && ./dgo test ./...        # testes
./dgo run ./cmd/navicity-sim               # cidade no terminal, imprime os fatos
cp env.exemplo .env                        # ajuste TAILSCALE_IP
docker compose up -d --build navicity      # liga a cidade com a API
docker compose logs -f navicity            # fatos ao vivo
curl http://$TAILSCALE_IP:8080/saude
```

A porta 8080 é publicada só no `TAILSCALE_IP`; sem ele, só em `127.0.0.1`.
`TIME_SCALE` acelera o relógio (padrão 1 = tempo real) e `SEMENTE` fixa a
aleatoriedade. Sem banco de dados ainda: ao reiniciar, a cidade recomeça e o
app precisa se registrar de novo.

## Mapa

Praça dos Bipes, Biblioteca Velha e Café da Esquina, ligadas por passagens com
tempo de caminhada (praça↔biblioteca 4 min, praça↔café 3, biblioteca↔café 6).

## Autenticação: requisições assinadas

Não há senha nem token. Cada instalação do app gera um par de chaves
**Ed25519**, manda a pública no registro e assina cada pedido com a privada.
Como nenhum segredo trafega, HTTP dentro da rede privada não expõe credencial.

O texto assinado tem quatro linhas:

```
MÉTODO
/caminho?query
carimbo (segundos Unix)
sha256 do corpo em hexadecimal
```

Cabeçalhos: `X-Carimbo`, `X-Assinatura` (base64 da assinatura) e, depois do
registro, `X-Navi` (o id recebido). O carimbo só vale por 60 segundos, então
o relógio do celular precisa estar certo. Assinatura inválida, carimbo velho e
id desconhecido recebem o mesmo `401`.

## Endpoints

| Método | Rota | Corpo / resposta |
| --- | --- | --- |
| GET | `/saude` | `{"estado":"ok"}` (sem assinatura) |
| POST | `/navis` | `{"chave_publica":"<base64 de 32 bytes>","perfil":{"elemento":"gelo","tracos":["curiosa","calma"]}}` → `201` com `id`, `apelido`, `area`, `estado`, `areas`. Assinado com a chave enviada. `409` se a chave já existe. |
| GET | `/cidade` | onde o NAVI está agora, os lugares (`id`, `nome`, `tipo`, `presentes`, `voce`) e o relógio da cidade (`agora_s`) |
| GET/PUT | `/gm/iris` | configuração da Iris (`tracos` 0 a 100 e `personalidade`, até 800 caracteres). Exige `Authorization: Bearer <NAVICITY_ADMIN_TOKEN>`; sem a variável, a rota fica desligada (404). Os traços valem na hora e ficam em `NAVICITY_DADOS/iris.json`. |
| GET | `/fatos?desde=N` | `{"fatos":[…],"cursor":N}`: só fatos do NAVI de quem pergunta, do ponto de vista dele |

Tipos de fato: `entrou`, `partiu`, `chegou`, `conheceu`, `conversou`,
`recusou`, `mudou_tom`. Cada fato traz `quando_s` (segundos desde o
nascimento da cidade) e a resposta traz `agora_s`, para o app dizer "há 12
minutos". Quando o outro NAVI é um GM vem `outro_gm: true`. O app guarda o
`cursor` e o envia como `desde` na próxima consulta.

## Perfil do app → cidade

O app descreve o NAVI com um elemento e de 1 a 3 traços em texto. A cidade
precisa de números, então a tradução fica em `internal/dominio/perfil_app.go`:

- **Elemento:** vira a fatia dominante (60%) de uma roleta de 10 elementos.
  `eletrico` vira `raio`. `luz`, `sombra` e `cyber` ficam fora do anel de
  vantagens (água→fogo→gelo→ar→terra→raio): são neutros, como `normal`.
- **Cyber é só dos GMs.** Nenhum jogador escolhe: o registro recusa (`400`).
  A **Iris**, game master da cidade, é um NAVI da casa de elemento Cyber que
  mora na Biblioteca Velha; o app a mostra com o selo `GM`.
- **Traços:** cada um desloca os 5 números (coragem, curiosidade, paciência,
  sociabilidade, agressividade), que partem de 50.
- **Afinidade:** o primeiro encontro de um par usa uma fórmula simétrica; depois
  disso cada lado evolui sozinho, então A→B passa a diferir de B→A.

## Estrutura

```
cmd/navicity-server/   API HTTP + relógio real
cmd/navicity-sim/      simulação no terminal
internal/dominio/      elementos, traços, afinidade (puro)
internal/sim/          fila de eventos, mapa, decisão, fatos (puro, sem I/O)
internal/cidade/       liga a simulação ao mundo de fora (uma goroutine só)
internal/api/          HTTP e assinatura Ed25519
docs/                  contexto do projeto
```

## Configuração da Iris

Só o dono da cidade mexe: defina `NAVICITY_ADMIN_TOKEN` (e `NAVICITY_DADOS`, a
pasta do `iris.json`) no servidor. No app: **Menu → Iris · GM**, onde a chave é
pedida uma vez e guardada no aparelho. Os cinco traços mudam o comportamento
dela na simulação assim que você salva; o texto de personalidade fica gravado
para a IA narradora usar.

## App web (iPhone e qualquer navegador)

O iPhone roda o Códice pelo navegador: `servidor/web/servir.mjs` entrega o build
web e repassa só `/api/chat` e `/api/tags` ao Ollama (o navegador não consegue
falar direto com ele por causa do CORS). A API Go libera o CORS da rede do
Tailscale; a API de login, as origens de `CODICE_ORIGENS`.

```sh
flutter build web --release --no-web-resources-cdn \
  --dart-define=CODICE_API_URL=http://100.x.y.z:8081 \
  --dart-define=NAVICITY_URL=http://100.x.y.z:8080 \
  --dart-define=OLLAMA_URL=http://100.x.y.z:8090
CODICE_WEB_HOST=100.x.y.z node servidor/web/servir.mjs
```

No Safari do iPhone (com o Tailscale ligado) abra `http://100.x.y.z:8090` e use
**Compartilhar → Adicionar à Tela de Início**. Limites do navegador: sem
Bluetooth, e a página HTTP guarda o login no localStorage (não há cofre
criptografado em HTTP).
