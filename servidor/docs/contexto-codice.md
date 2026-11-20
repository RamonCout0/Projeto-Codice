# Contexto: o Códice e onde a NAVICity entra

Resumo do projeto-mãe para quem trabalha no servidor. Fontes: repositórios
`RamonCout0/Projeto-Codice` (entregáveis da disciplina) e
`RamonCout0/codice-contexto-test` (app experimental, `lib/nucleo.dart`).

## O que é o Códice

App Flutter de diário pessoal e assistente (disciplina de Desenvolvimento para
Dispositivos Móveis, Ramon + Aaron; continuidade no TCC). O usuário cria um
**NAVI**, criatura digital que nasce aos 8 anos, analfabeta: só sabe o que o dono
ensina (o diário é a principal forma de ensinar). Cresce por convivência, não por
compras:

| Fase | Idade | Libera |
|---|---:|---|
| Criança | 8 | diário, conversa, memória, assistência |
| Adolescente | 14 | **NAVICity**, mapa, conversa entre NAVIs, apelidos |
| Adulto | 18 | fecha a Etapa 1 |

Três pilares: (1) NAVI + diário, (2) encontros anônimos por Bluetooth,
(3) **NAVICity**, o mundo onde os NAVIs vivem com o app fechado, com lugares
que se revelam conforme o dono passa por locais reais.

Duas línguas: **Navidês** (NAVI↔NAVI: bipes, ritmos, pausas) e português
(NAVI↔humano). A afinidade é um *relato* do NAVI, não uma medição exibida.

Referências: Pokémon GO, Mega Man NT Warrior, POU, Waze.

## Arquitetura geral

- O app funciona offline e sincroniza com Wi-Fi.
- O NAVI **não** vive em segundo plano no celular: ao abrir, reage ao tempo que
  passou. Quem faz a vida acontecer com o app fechado é a NAVICity (servidor).
- Avatares VRM (VRoid). A Frost tem licença sem redistribuição: o arquivo nunca
  vai para a nuvem. Visitantes trafegam como paleta/derivados (~30 bytes).
- O app hoje mostra a cidade mockada (Praça dos Bipes, Biblioteca Velha, Café
  da Esquina). O servidor transforma isso numa cidade que existe de verdade.
- Ponto mais delicado: a cola entre app e servidor (sincronização offline e
  assinaturas).

**Escopo deste repositório: só a NAVICity, no servidor.** O app Flutter e os VRM
ficam no PC do Ramon; builds de Flutter não rodam neste servidor.

## Contrato de domínio que já existe no app (`lib/nucleo.dart`)

O servidor precisa falar a mesma língua. Estes são os valores do app:

- **Elementos (7 no nucleo.dart; 9 no servidor):** água, fogo, gelo, ar, terra, raio, **normal**.
  Anel `água → fogo → gelo → ar → terra → raio`; cada elemento vence os **dois**
  seguintes (alcance 2). Normal fica fora do anel (neutro).
- **Roleta:** o NAVI não tem um elemento só, tem uma distribuição em % derivada
  das cores do VRM (piso de 3% por elemento). Dominante = maior fatia;
  especialista se o dominante ≥ 60%.
- **Traços (5, inteiros 0..100):** coragem, curiosidade, paciência,
  sociabilidade, agressividade.
- **Índole:** eixo Luz(+)↔Trevas(−), movido por escolhas (Etapa 2).
- **Afinidade (0..100) e tom:** hostil < 35 ≤ indiferente ≤ 65 < amistoso.
  `calcularAfinidade` é **simétrica**: base 50; mesmo elemento +20, um vence o
  outro −18, senão +4; `(20 − distânciaMédiaDeTraços) × 1.2`;
  `(socMédia − 50) × 0.35 − (agrMédia − 50) × 0.35`; arredonda e limita a 0..100.
  Em 30 mil confrontos: 18% hostil / 64% indiferente / 18% amistoso.
- **Anúncio BLE (14 bytes):** versão, id aleatório de 32 bits, elemento
  dominante, nível, os 5 traços, transformações, estado. Sem nome; o apelido
  nasce do id (sílabas).
- **Cidade local do app:** lotes por passos (5000 passos/lote), demanda
  emergente (elemento mais presente entre os NAVIs cruzados, mínimo 3, define a
  construção da área: Fonte, Forja, Câmara fria, Torre de vento, Jardim, Torre
  de energia, Praça).
- Sem login no app: identificador aleatório por instalação (`estado.id_radio`).
  Dado pessoal nunca sai do aparelho; só estado de jogo pode subir.
