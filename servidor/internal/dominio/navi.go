package dominio

import "fmt"

// Traco segue a ordem do enum do Dart: é a ordem dos bytes 7..11 do anúncio BLE.
type Traco uint8

const (
	Coragem Traco = iota
	Curiosidade
	Paciencia
	Sociabilidade
	Agressividade

	NumTracos = int(Agressividade) + 1
)

var rotulosTraco = [NumTracos]string{"Coragem", "Curiosidade", "Paciência", "Sociabilidade", "Agressividade"}

func (t Traco) String() string {
	if int(t) >= NumTracos {
		return fmt.Sprintf("traço(%d)", t)
	}
	return rotulosTraco[t]
}

// Tracos usa array, não map: tamanho fixo, sem alocação, comparável com ==,
// e impossível "faltar" um traço. No Dart, traço ausente valia 50; aqui ele
// simplesmente não pode faltar.
type Tracos [NumTracos]int

// TracosNeutros é o NAVI recém-nascido: tudo em 50.
func TracosNeutros() Tracos { return Tracos{50, 50, 50, 50, 50} }

// Validar recusa valores fora de 0..100. Não corrige em silêncio, porque um
// valor fora da faixa vindo do app é bug ou adulteração, e os dois merecem erro.
func (t Tracos) Validar() error {
	for i, v := range t {
		if v < 0 || v > 100 {
			return fmt.Errorf("%s fora da faixa 0..100: %d", Traco(i), v)
		}
	}
	return nil
}

// Roleta é a distribuição de elemento (em %) derivada das cores do VRM.
// O servidor guarda a roleta inteira, não só o dominante: são números
// abstratos (privacidade ok) e preservam a nuance especialista/generalista.
type Roleta [NumElementos]float64

// Dominante é a maior fatia. Em empate vence o primeiro na ordem do enum, que
// é a mesma ordem em que o app monta a roleta (roletaDeAmostras).
func (r Roleta) Dominante() Elemento {
	melhor := 0
	for i := 1; i < NumElementos; i++ {
		if r[i] > r[melhor] {
			melhor = i
		}
	}
	return Elemento(melhor)
}

// Concentracao é o tamanho da fatia dominante.
func (r Roleta) Concentracao() float64 { return r[r.Dominante()] }

// Especialista concentra numa cor só (≥ 60%): previsível, mas marcante.
func (r Roleta) Especialista() bool { return r.Concentracao() >= 60 }

// Validar exige fatias não negativas somando ~100 (o app arredonda em 0,1).
func (r Roleta) Validar() error {
	soma := 0.0
	for i, v := range r {
		if v < 0 {
			return fmt.Errorf("roleta: %s negativo (%.1f)", Elemento(i), v)
		}
		soma += v
	}
	if soma < 99.5 || soma > 100.5 {
		return fmt.Errorf("roleta soma %.1f, esperado 100", soma)
	}
	return nil
}

// Perfil é o que o servidor sabe de um NAVI: só números de personalidade.
// Nada de nome real, diário, áudio ou VRM.
type Perfil struct {
	Roleta Roleta
	Tracos Tracos
}

func (p Perfil) Validar() error {
	if err := p.Roleta.Validar(); err != nil {
		return err
	}
	return p.Tracos.Validar()
}
