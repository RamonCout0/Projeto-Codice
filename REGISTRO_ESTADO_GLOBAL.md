# Atividade — Implementação de Estado Global (Provider + ChangeNotifier) · Projeto Códice

**Arquivo principal:** `AtvNavegacao.dart` (versão atualizada com Provider)
**Gerenciador de estado:** Provider + ChangeNotifier
**Dupla:** Ramon Couto Santo e Aaron Guerra Goldberg

A implementação utiliza o pacote `provider` para compartilhar o estado dos NAVIs entre telas diferentes. A navegação, a aparência e as demais funcionalidades do aplicativo foram mantidas. A alteração foi concentrada no apelido dos NAVIs, que agora é controlado por uma classe de estado global.

## Como o estado está organizado

```
main()
  ChangeNotifierProvider<EstadoCodice>
    CodiceApp
      AppShell
        Navigator da aba Encontros
          MeetingsScreen  (lista de NAVIs)
          NaviScreen      (detalhes do NAVI)

EstadoCodice extends ChangeNotifier
  lista de NAVIs
  obterNavi(nome)
  alterarApelido(nome, novoApelido)
```

A classe `EstadoCodice` fica disponível para as telas abaixo da raiz do aplicativo. Assim, a lista e os apelidos não precisam ficar presos ao estado local de um único widget.

## Requisitos

| # | Requisito | Onde está |
|---|---|---|
| 1 | Classe separada para controlar o estado | `EstadoCodice`, que estende `ChangeNotifier` e mantém a lista de NAVIs |
| 2 | Interface consumindo o estado | `MeetingsScreen` e `NaviScreen`, usando `context.watch<EstadoCodice>()` |
| 3 | Dois widgets reagindo ao mesmo estado | A lista de Encontros e a tela de detalhes do NAVI consultam o mesmo `EstadoCodice` |
| 4 | Ação da interface que altera o estado | A ação de salvar/alterar apelido chama `context.read<EstadoCodice>().alterarApelido(...)` |
| 5 | Notificação das telas após a alteração | `alterarApelido` atualiza o apelido e chama `notifyListeners()` |
| 6 | Estado disponível globalmente | `ChangeNotifierProvider` envolve `CodiceApp` na função `main()` |

## Dependência

Foi utilizado o pacote `provider`. No projeto Flutter, ele precisa estar declarado no `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.5
```

Depois de incluir a dependência, executar `flutter pub get` para instalá-la.

## Funcionamento da implementação

### Classe `EstadoCodice`

A classe mantém a lista de objetos `NaviEncontrado` e oferece métodos para consultar um NAVI e alterar seu apelido. Ela estende `ChangeNotifier`, permitindo avisar aos widgets quando os dados mudarem.

O método `alterarApelido(nome, novoApelido)` procura o NAVI pelo nome, verifica se o novo apelido não está vazio, atualiza o valor e executa `notifyListeners()`.

### Consumo do estado

- **`MeetingsScreen`:** usa `context.watch<EstadoCodice>().navis` para obter a lista. Quando um apelido muda, a tela pode reconstruir e mostrar o nome atualizado.
- **`NaviScreen`:** usa `context.watch<EstadoCodice>()` e `obterNavi(...)` para consultar os dados do NAVI selecionado. Dessa forma, também recebe as alterações feitas na outra tela.
- **Ação de alteração:** usa `context.read<EstadoCodice>().alterarApelido(...)` para modificar o estado sem precisar acessar diretamente a lista dentro do widget.

## Fluxo da alteração

```
Pessoa altera o apelido na interface
              |
              v
context.read<EstadoCodice>()
              |
              v
alterarApelido(nome, novoApelido)
              |
              v
EstadoCodice atualiza o objeto NAVI
              |
              v
notifyListeners()
              |
       +------+------+
       |             |
       v             v
MeetingsScreen   NaviScreen
       |             |
       +------<------+
       As telas atualizam os dados exibidos
```

## Descrição

**Por que Provider + ChangeNotifier?**

O Provider permite disponibilizar um objeto de estado para várias partes da árvore de widgets sem precisar passar os dados manualmente por vários construtores. O `ChangeNotifier` concentra a lógica de alteração e avisa aos widgets que estão observando o estado quando alguma informação muda.

Neste projeto, o apelido de um NAVI é um dado compartilhado: ele pode ser alterado na tela de detalhes e precisa aparecer também na lista de Encontros. Por isso, esse dado foi retirado do estado local de `MeetingsScreen` e passou a ser mantido em `EstadoCodice`.

Os outros usos de `setState` foram preservados quando controlam informações locais de uma tela. Nem todo estado precisa ser global; o Provider foi aplicado ao dado que realmente é compartilhado entre widgets.

**Principal dificuldade técnica**

A principal dificuldade foi identificar qual informação precisava sair do estado local e passar a ser compartilhada. Também foi necessário centralizar a alteração do apelido na classe `EstadoCodice` e garantir que as duas telas observassem o mesmo objeto. Assim, depois da alteração, `notifyListeners()` informa aos widgets que utilizam `context.watch` que devem atualizar a interface.

**Vantagem da abordagem**

A principal vantagem é manter a lógica de estado separada da interface. As telas consultam ou solicitam alterações ao `EstadoCodice`, sem precisar controlar diretamente os dados compartilhados. Isso facilita a manutenção e evita duplicar a mesma informação em widgets diferentes.
