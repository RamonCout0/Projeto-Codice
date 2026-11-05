# Códice para Android

Abra esta pasta no Android Studio com os plugins Flutter e Dart. Configure o caminho do SDK Flutter (3.32 ou superior) e o JDK 17. No terminal desta pasta:

```sh
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run
```

Selecione um emulador Android ou um aparelho com depuração USB. A entrada é `lib/main.dart`. Para gerar um APK de desenvolvimento, execute `flutter build apk --debug`.

## Organização

- `models/` representa lugares, memórias, NAVIs e ajustes.
- `services/` reúne as regras de contagem de palavras e sugestão de etiquetas.
- `controllers/` mantém os apelidos compartilhados entre Encontros e Detalhes com Provider.
- `views/` organiza as telas e suas interações. `widgets/` contém os componentes compartilhados.
- `app/` define tema, rotas e histórico das abas. `data/` contém os lugares de demonstração.
- Os JPEGs em `assets/navis/` incluem corpo e rosto de Frost e Ekor e a prancha de referência. As telas da Frost usam os dois arquivos dela diretamente.

## Conferência manual

1. Entre no app, abra Diário e escreva cinco palavras. Confirme o registro e consulte a memória.
2. Escreva outro texto, segure o botão de apagar e use Desfazer.
3. Em Encontros, abra Pixel, altere o apelido e volte à lista. Confira o mesmo apelido nas duas telas.
4. Abra um lugar na Cidade, troque de aba e retorne. Confira se o mesmo lugar continua aberto.

Esta versão acadêmica usa dados em memória durante a sessão. Bluetooth, localização real e evolução autônoma da NAVICity fazem parte da proposta descrita no README da raiz.
