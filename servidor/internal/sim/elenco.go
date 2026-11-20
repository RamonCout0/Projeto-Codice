package sim

import (
	"math/rand/v2"

	"navicity/internal/dominio"
)

// MembroElenco é um NAVI pronto para entrar na cidade (testes e terminal).
type MembroElenco struct {
	ID     NaviID
	Perfil dominio.Perfil
	Area   AreaID
	// Apelido só vale para GMs (ex.: "Iris"); os demais derivam do id.
	Apelido string
	GM      bool
}

// roletaCom monta uma roleta com o dominante em pct% e o resto dividido igual.
func roletaCom(dom dominio.Elemento, pct float64) dominio.Roleta {
	var r dominio.Roleta
	resto := (100 - pct) / float64(dominio.NumElementos-1)
	for i := range r {
		r[i] = resto
	}
	r[dom] = pct
	return r
}

// ElencoDeTeste: cinco NAVIs com personalidades bem diferentes, para dar para
// ver no terminal se o comportamento combina com o temperamento.
// Traços: coragem, curiosidade, paciência, sociabilidade, agressividade.
func ElencoDeTeste() []MembroElenco {
	return []MembroElenco{
		{0x0A1, dominio.Perfil{Roleta: roletaCom(dominio.Gelo, 53), Tracos: dominio.Tracos{40, 70, 70, 45, 20}}, Praca, "", false},       // curiosa e calma
		{0x1B2, dominio.Perfil{Roleta: roletaCom(dominio.Fogo, 65), Tracos: dominio.Tracos{80, 50, 25, 75, 60}}, Praca, "", false},       // ousado e esquentado
		{0x2C3, dominio.Perfil{Roleta: roletaCom(dominio.Agua, 45), Tracos: dominio.Tracos{50, 40, 80, 60, 15}}, Cafe, "", false},        // acolhedor
		{0x3D4, dominio.Perfil{Roleta: roletaCom(dominio.Raio, 60), Tracos: dominio.Tracos{70, 85, 30, 55, 40}}, Biblioteca, "", false},  // inquieto
		{0x4E5, dominio.Perfil{Roleta: roletaCom(dominio.Terra, 50), Tracos: dominio.Tracos{30, 30, 90, 25, 10}}, Biblioteca, "", false}, // tímido
	}
}

// ElencoAleatorio gera n NAVIs com perfis variados (para o benchmark).
// Usa um gerador próprio, separado do da simulação.
func ElencoAleatorio(n int, numAreas int, semente uint64) []MembroElenco {
	r := rand.New(rand.NewPCG(semente, 0xC0D1CE))
	out := make([]MembroElenco, n)
	for i := range out {
		var t dominio.Tracos
		for j := range t {
			t[j] = 10 + r.IntN(81)
		}
		// Cyber é do GM: o último do enum fica de fora do sorteio.
		dom := dominio.Elemento(r.IntN(dominio.NumElementos - 1))
		out[i] = MembroElenco{
			ID:     NaviID(i + 1),
			Perfil: dominio.Perfil{Roleta: roletaCom(dom, 30+r.Float64()*45), Tracos: t},
			Area:   AreaID(r.IntN(numAreas)),
		}
	}
	return out
}

// IDIris é o id fixo da GM da casa.
const IDIris NaviID = 0x1815

// Iris é a game master da NAVICity: elemento Cyber, paciente e curiosa,
// sociável com todo mundo e sem agressividade. Ela mora na Biblioteca.
func Iris() MembroElenco {
	// coragem, curiosidade, paciência, sociabilidade, agressividade
	perfil, err := dominio.PerfilGM(dominio.Tracos{60, 85, 90, 70, 5})
	if err != nil {
		panic(err) // valores fixos do código: erro aqui é bug, não entrada
	}
	return MembroElenco{ID: IDIris, Perfil: perfil, Area: Biblioteca, Apelido: "Iris", GM: true}
}

// Residentes é quem já mora na cidade quando ela liga: a GM e os NAVIs de
// teste. Quando o Postgres chegar, só a GM continua sendo da casa.
func Residentes() []MembroElenco { return append([]MembroElenco{Iris()}, ElencoDeTeste()...) }

// Povoar põe os residentes na cidade.
func (s *Sim) Povoar(elenco []MembroElenco) error {
	for _, m := range elenco {
		var err error
		if m.GM {
			err = s.AdicionarGM(m.ID, m.Apelido, m.Perfil, m.Area)
		} else {
			err = s.AdicionarNavi(m.ID, m.Perfil, m.Area)
		}
		if err != nil {
			return err
		}
	}
	return nil
}
