# Implementação de Comunicação Segura

Projeto Códice · Desenvolvimento para Dispositivos Móveis

Aaron Guerra Goldberg e Ramon Couto Santo

## O que foi adicionado

O app principal continua em `AtvNavegacao_provider.dart`, aberto pelo `main.dart`. Os botões da tela inicial levam à autenticação. A atividade usa uma conta de demonstração e uma lista de NAVIs fictícios. Os usuários, senhas e dados pessoais do Códice ficam fora dessa demonstração.

1. A tela envia usuário e senha em JSON para `POST /auth/login`.
2. A API confere os dados e devolve o JWT em `access_token`.
3. O aplicativo grava o token usando `flutter_secure_storage` e abre a consulta.
4. O aplicativo lê o token de volta para enviar `GET /navis` com `Authorization: Bearer <token>`. A lista mostra ID, nome e descrição.
5. Se a consulta responder `401`, o aplicativo apaga o token e volta ao formulário. Se a remoção falhar, mostra um botão para tentar novamente.
6. Ao reabrir a área de login depois de fechar o app, a sessão pode ser recuperada do armazenamento seguro e é conferida pela API novamente.

| Situação | O que aparece no app |
| --- | --- |
| Servidor indisponível | Mensagem de indisponibilidade e opção de repetir a consulta |
| Tempo limite de 8 segundos | Mensagem informando que a API demorou |
| Usuário ou senha incorretos | Mensagem no formulário |
| JWT inválido ou expirado | Formulário de login com aviso de sessão expirada ou inválida |
| JSON malformado ou com dados inesperados | Mensagem de resposta inválida |
| Falha ao ler, gravar ou apagar o token | Mensagem do armazenamento seguro |

## Por que usamos essas proteções

O `flutter_secure_storage` guarda o token usando a proteção do sistema operacional. No Android, as chaves ficam protegidas pelo Keystore. O `SharedPreferences` serve para dados simples, como tema, última aba ou uma pesquisa recente que não tenha informação privada. Como um token permite fazer requisições em nome de quem fez login, usamos o armazenamento seguro e evitamos guardar a senha.

O HTTPS usa TLS para criptografar os dados em trânsito, ajudar a detectar alterações e validar a identidade do servidor pelo certificado. Usar HTTP direto entre o celular e a API deixaria credenciais e tokens expostos durante o tráfego. No Codespaces, o aplicativo conversa por HTTPS com o proxy. O HTTP fica entre o proxy e o processo local, na mesma máquina. Também é possível ativar TLS direto na API com um certificado aceito pelo Android.

O pacote `Encrypt` ficou de fora porque o HTTPS já protege o caminho até o servidor e o armazenamento seguro protege o token no aparelho. Uma camada a mais poderia ser útil para proteger campos que devam continuar criptografados quando passam por um intermediário ou são gravados no banco. A vantagem seria limitar quem pode ler esses campos. A desvantagem seria administrar chaves, rotações e recuperação, além de dificultar consultas. Uma chave fixa no app poderia ser extraída.

## Como rodar a API no GitHub Codespaces

Abra um Codespace na branch `Atividades` e rode no terminal Bash usando Node 20 ou superior.

```bash
read -rsp "Senha de teste para o usuário aluno: " CODICE_SENHA
echo
export CODICE_SENHA
export CODICE_JWT_SECRET="$(node -e 'process.stdout.write(require("node:crypto").randomBytes(32).toString("hex"))')"
node api/servidor.mjs
```

Na aba **Ports**, adicione a porta **8080**. Deixe o protocolo da porta como **HTTP**, pois é assim que o proxy conversa com o Node local. Para que o emulador acesse a API sem uma sessão do navegador no GitHub, marque a porta como **Public** e copie o endereço externo **HTTPS**. Use apenas a conta com senha de demonstração e os dados fictícios. Se o GitHub impedir a porta pública, use uma hospedagem HTTPS que você possa acessar. Ao terminar, torne a porta privada ou pare o Codespace.

A API lê `PORT` e `CODICE_TOKEN_TTL` do ambiente. O token dura 900 segundos por padrão. Em uma hospedagem com proxy TLS, mantenha o servidor HTTP local atrás do proxy. Para subir HTTPS direto, informe `CODICE_TLS_CERT` e `CODICE_TLS_KEY` com os caminhos dos arquivos PEM e use um certificado confiável correspondente ao endereço que o app vai acessar. O segredo JWT fica no servidor.

## Como rodar o Android

Na raiz do repositório, com o emulador aberto e JDK 17 configurado no Flutter:

```powershell
flutter pub get
flutter devices
flutter run -d emulator-5554 -t main.dart --dart-define=CODICE_API_URL=https://SEU-ENDERECO
```

Troque o endereço de exemplo pelo HTTPS da porta e o ID do emulador se necessário. Na tela inicial, toque em **já tenho um códice** e entre como **aluno**, com a senha definida no terminal. Depois da lista, **Ir para o Códice** abre o restante do app.

Os testes do servidor podem ser rodados separadamente com `node --test api/servidor.test.mjs`.

## Roteiro dos cinco prints

| Print | Como reproduzir |
| --- | --- |
| Login realizado | Entre e capture a mensagem de login realizado sem mostrar a senha. |
| Sessão recuperada | Feche o app, abra novamente, toque em **já tenho um códice** e capture o aviso de sessão recuperada. |
| Consulta protegida | Capture a lista de NAVIs mostrando ID, nome e descrição. |
| Sessão expirada | Reinicie a API com `CODICE_TOKEN_TTL=15 node api/servidor.mjs`, faça login novamente, espere 15 segundos e toque em **Atualizar lista**. |
| Falha de comunicação | Entre de novo, pare a API com `Ctrl+C` no Codespaces e toque em **Atualizar lista**. |

Na reprodução da expiração, saia da sessão antes do novo login para receber um token com a duração curta. Guarde apenas prints das telas, sem mostrar senha, JWT ou segredo.
