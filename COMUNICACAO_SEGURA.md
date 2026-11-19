# Implementação de Comunicação Segura

Projeto Códice · Desenvolvimento para Dispositivos Móveis

Aaron Guerra Goldberg e Ramon Couto Santo

## O que foi adicionado

Na branch `dev`, o cliente fica em `lib/services/api_codice.dart` e a tela em `lib/views/sessao_segura_tela.dart` (rota `/sessao`). Na tela inicial, **criar meu NAVI** abre o cadastro e **já tenho um códice** abre o login. Os dois têm **entrar sem conta**, para usar o restante do app sem a API. A lista de NAVIs consultada é fictícia.

1. A pessoa cria a conta no próprio app: a tela envia usuário e senha em JSON para `POST /auth/registro`. A API guarda só o hash da senha e já devolve um JWT.
2. Nas próximas vezes, a tela envia usuário e senha para `POST /auth/login`. A API confere os dados e devolve o JWT em `access_token`.
3. O aplicativo grava o token usando `flutter_secure_storage` e abre a consulta.
4. O aplicativo lê o token de volta para enviar `GET /navis` com `Authorization: Bearer <token>`. A lista mostra ID, nome e descrição.
5. Se a consulta responder `401`, o aplicativo apaga o token e volta ao formulário de login. Se a remoção falhar, mostra um botão para tentar novamente.
6. Com **manter conectado** marcado, o token fica no armazenamento seguro. Ao reabrir o app, a sessão é recuperada, conferida pela API (`GET /perfil`) e o app abre direto na Home com o NAVI da conta. Sem a opção, o token fica só na memória e some quando o app fecha.
7. Cada conta guarda o perfil do NAVI (nome, elemento, traços e gostos) em `GET`/`PUT /perfil`, que também exigem o JWT. A API valida cada campo antes de salvar.

| Situação | O que aparece no app |
| --- | --- |
| API local desligada | Mensagem pedindo para rodar `node api/servidor.mjs` |
| Servidor remoto indisponível | Mensagem de indisponibilidade e opção de repetir a consulta |
| Tempo limite de 8 segundos | Mensagem informando que a API demorou |
| Usuário ou senha incorretos | Mensagem no formulário |
| Usuário já existe, usuário ou senha fora das regras | Motivo enviado pela API, no formulário |
| Senha e confirmação diferentes | Aviso no campo, antes de enviar |
| JWT inválido ou expirado | Formulário de login com aviso de sessão expirada ou inválida |
| JSON malformado ou com dados inesperados | Mensagem de resposta inválida |
| Falha ao ler, gravar ou apagar o token | Mensagem do armazenamento seguro |

## Contas e senhas

As contas ficam em `api/dados/usuarios.json`, que não vai para o Git. A senha nunca é guardada: a API usa **scrypt** com um sal aleatório de 16 bytes por conta e guarda só o sal e o hash. No login, o hash é recalculado e comparado em tempo constante (`timingSafeEqual`).

Quando o usuário não existe, a API calcula o hash do mesmo jeito e responde a mesma mensagem de senha errada. Assim, a resposta não revela quais usuários existem.

Regras do cadastro, conferidas no app e de novo na API:

- usuário com 3 a 32 letras, números, ponto, hífen ou sublinhado (guardado em minúsculas);
- senha com 8 a 128 caracteres;
- usuário repetido é recusado com `409`.

O segredo que assina os JWT é gerado na primeira execução e guardado em `api/dados/segredo-jwt.txt`, também fora do Git. Com isso, as sessões continuam valendo se a API reiniciar. Quem preferir pode passar o segredo em `CODICE_JWT_SECRET`.

## Por que usamos essas proteções

O `flutter_secure_storage` guarda o token usando a proteção do sistema operacional. No Android, as chaves ficam protegidas pelo Keystore. O `SharedPreferences` serve para dados simples, como tema, última aba ou uma pesquisa recente que não tenha informação privada. Como um token permite fazer requisições em nome de quem fez login, usamos o armazenamento seguro e evitamos guardar a senha.

O HTTPS usa TLS para criptografar os dados em trânsito, ajudar a detectar alterações e validar a identidade do servidor pelo certificado. Usar HTTP direto entre o celular e a API deixaria credenciais e tokens expostos durante o tráfego. No Codespaces, o aplicativo conversa por HTTPS com o proxy. O HTTP fica entre o proxy e o processo local, na mesma máquina. Também é possível ativar TLS direto na API com um certificado aceito pelo Android.

A única exceção é a API rodando **no próprio aparelho** (`localhost`, `127.0.0.1` ou `::1`). Nesse caso, o tráfego não passa pela rede e não há onde ser interceptado, então o app aceita `http://`. Para qualquer outro endereço, ele continua exigindo HTTPS. A própria API, sem TLS, só aceita conexões locais.

Como o app web roda em outra porta (por exemplo `localhost:8090`), o navegador pede permissão à API antes de cada chamada (CORS). A API só libera origens locais e as listadas em `CODICE_ORIGENS`.

O pacote `Encrypt` ficou de fora porque o HTTPS já protege o caminho até o servidor e o armazenamento seguro protege o token no aparelho. Uma camada a mais poderia ser útil para proteger campos que devam continuar criptografados quando passam por um intermediário ou são gravados no banco. A vantagem seria limitar quem pode ler esses campos. A desvantagem seria administrar chaves, rotações e recuperação, além de dificultar consultas. Uma chave fixa no app poderia ser extraída.

## Como rodar no PC (web)

Com Node 20 ou superior, em dois terminais na raiz do repositório:

```powershell
node api/servidor.mjs
```

```powershell
flutter run -d edge
```

Não precisa configurar nada: a API sobe em `http://localhost:8080` e o app já aponta para ela. Na tela inicial, toque em **criar meu NAVI**, crie a conta e veja a lista protegida.

## Como rodar no emulador Android

O emulador tem o próprio `localhost`. Para ligar a porta dele à do PC:

```powershell
adb reverse tcp:8080 tcp:8080
```

```powershell
flutter run -d emulator-5554
```

## Como rodar a API no GitHub Codespaces

Para acessar de um celular de verdade, a API precisa de um endereço HTTPS. Abra um Codespace na branch `dev` e rode `node api/servidor.mjs` no terminal.

Na aba **Ports**, adicione a porta **8080**. Deixe o protocolo da porta como **HTTP**, pois é assim que o proxy conversa com o Node local. Para que o celular acesse a API sem uma sessão do navegador no GitHub, marque a porta como **Public** e copie o endereço externo **HTTPS**. Use apenas contas de teste e os dados fictícios. Ao terminar, torne a porta privada ou pare o Codespace.

```powershell
flutter run --dart-define=CODICE_API_URL=https://SEU-ENDERECO
```

A API também lê do ambiente:

| Variável | Para que serve |
| --- | --- |
| `PORT` | porta (padrão 8080) |
| `CODICE_TOKEN_TTL` | duração do token em segundos (padrão 900) |
| `CODICE_DADOS` | pasta das contas e do segredo (padrão `api/dados`) |
| `CODICE_JWT_SECRET` | segredo do JWT, em vez do gerado automaticamente |
| `CODICE_SENHA` | opcional: cria a conta de demonstração `aluno` com essa senha |
| `CODICE_ORIGENS` | origens extras do app web liberadas no CORS |
| `CODICE_TLS_CERT` / `CODICE_TLS_KEY` | arquivos PEM para subir HTTPS direto |

Os testes do servidor rodam com `node --test api/servidor.test.mjs` (usam uma pasta temporária, sem tocar em `api/dados`). Os do cliente ficam em `test/api_codice_test.dart` (`flutter test`).

## Roteiro dos cinco prints

| Print | Como reproduzir |
| --- | --- |
| Login realizado | Crie a conta ou entre e capture a mensagem de sessão guardada, sem mostrar a senha. |
| Sessão recuperada | Entre com **manter conectado** marcado, feche o app e abra de novo: ele vai direto para a Home e mostra o aviso de sessão recuperada. |
| Consulta protegida | Capture a lista de NAVIs mostrando ID, nome e descrição. |
| Sessão expirada | Reinicie a API com `$env:CODICE_TOKEN_TTL=15; node api/servidor.mjs`, saia da sessão, entre de novo, espere 15 segundos e toque em **Atualizar lista**. |
| Falha de comunicação | Entre de novo, pare a API com `Ctrl+C` e toque em **Atualizar lista**. |

Guarde apenas prints das telas, sem mostrar senha, JWT ou segredo.
