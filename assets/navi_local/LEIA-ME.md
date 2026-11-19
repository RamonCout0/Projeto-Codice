# NAVI da apresentação

Coloque aqui o modelo e as animações que o app deve carregar sozinho, sem
precisar importar (útil no `flutter run -d edge`, que abre um navegador
limpo toda vez). Nada desta pasta vai para o Git além deste arquivo: cada
modelo e animação tem a sua licença.

| Arquivo | O que é |
| --- | --- |
| `modelo.vrm` | o modelo da NAVI (VRoid etc.) |
| `parada.fbx` ou `parada.vrma` | repete o tempo todo |
| `aceno.fbx` ou `aceno.vrma` | quando você toca nela |
| `comemorar.fbx` ou `comemorar.vrma` | quando ela fica feliz |

Animações `.fbx` vêm do [Mixamo](https://www.mixamo.com): baixe em
**FBX Binary (.fbx)**, com **Without Skin**. Todas as animações são opcionais.

Depois de trocar um arquivo aqui, pare e rode `flutter run` de novo (os assets
entram no app na hora do build). O que for importado pela tela
"Importar NAVI" tem prioridade sobre esta pasta.
