package sim

import "fmt"

// AreaID indexa um slice, não um map: iterar map em Go tem ordem aleatória,
// e ordem aleatória quebraria o determinismo da simulação.
type AreaID uint16

type Area struct {
	ID   AreaID
	Nome string
	// Tipo é o identificador estável do lugar ("praca", "biblioteca",
	// "cafe"). O app escolhe o desenho pelo tipo, não pelo nome.
	Tipo string
}

// Ligacao é uma passagem de mão única; Ligar cria as duas direções.
type Ligacao struct {
	Para    AreaID
	Duracao Instante
}

// Mapa é o grafo da cidade, como a Net de Battle Network: áreas ligadas por
// passagens com tempo de caminhada.
type Mapa struct {
	areas    []Area
	ligacoes [][]Ligacao
}

func NovoMapa() *Mapa { return &Mapa{} }

func (m *Mapa) AdicionarArea(nome string) AreaID { return m.AdicionarAreaDoTipo(nome, "") }

func (m *Mapa) AdicionarAreaDoTipo(nome, tipo string) AreaID {
	id := AreaID(len(m.areas))
	m.areas = append(m.areas, Area{ID: id, Nome: nome, Tipo: tipo})
	m.ligacoes = append(m.ligacoes, nil)
	return id
}

func (m *Mapa) valida(id AreaID) bool { return int(id) < len(m.areas) }

// Ligar cria a passagem nos dois sentidos com o mesmo tempo de caminhada.
func (m *Mapa) Ligar(a, b AreaID, d Instante) error {
	if !m.valida(a) || !m.valida(b) || a == b {
		return fmt.Errorf("ligação inválida: %d ↔ %d", a, b)
	}
	if d <= 0 {
		return fmt.Errorf("duração precisa ser positiva: %d", d)
	}
	m.ligacoes[a] = append(m.ligacoes[a], Ligacao{Para: b, Duracao: d})
	m.ligacoes[b] = append(m.ligacoes[b], Ligacao{Para: a, Duracao: d})
	return nil
}

func (m *Mapa) NumAreas() int                { return len(m.areas) }
func (m *Mapa) Area(id AreaID) Area          { return m.areas[id] }
func (m *Mapa) Vizinhos(id AreaID) []Ligacao { return m.ligacoes[id] }

// Áreas do mapa inicial, na ordem em que MapaInicial as cria.
const (
	Praca AreaID = iota
	Biblioteca
	Cafe
)

// MapaInicial é a cidade que o app já mostra mockada.
func MapaInicial() *Mapa {
	m := NovoMapa()
	m.AdicionarAreaDoTipo("Praça dos Bipes", "praca")
	m.AdicionarAreaDoTipo("Biblioteca Velha", "biblioteca")
	m.AdicionarAreaDoTipo("Café da Esquina", "cafe")
	// Erros aqui seriam bug no próprio código, não entrada externa: por isso
	// o panic é aceitável (falha alto e cedo, na inicialização).
	for _, l := range []struct {
		a, b AreaID
		min  Instante
	}{{Praca, Biblioteca, 4}, {Praca, Cafe, 3}, {Biblioteca, Cafe, 6}} {
		if err := m.Ligar(l.a, l.b, l.min*Minuto); err != nil {
			panic(err)
		}
	}
	return m
}
