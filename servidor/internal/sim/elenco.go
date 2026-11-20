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
		{0x0A1, dominio.Perfil{Roleta: roletaCom(dominio.Gelo, 53), Tracos: dominio.Tracos{40, 70, 70, 45, 20}}, Praca},       // curiosa e calma
		{0x1B2, dominio.Perfil{Roleta: roletaCom(dominio.Fogo, 65), Tracos: dominio.Tracos{80, 50, 25, 75, 60}}, Praca},       // ousado e esquentado
		{0x2C3, dominio.Perfil{Roleta: roletaCom(dominio.Agua, 45), Tracos: dominio.Tracos{50, 40, 80, 60, 15}}, Cafe},        // acolhedor
		{0x3D4, dominio.Perfil{Roleta: roletaCom(dominio.Raio, 60), Tracos: dominio.Tracos{70, 85, 30, 55, 40}}, Biblioteca},  // inquieto
		{0x4E5, dominio.Perfil{Roleta: roletaCom(dominio.Terra, 50), Tracos: dominio.Tracos{30, 30, 90, 25, 10}}, Biblioteca}, // tímido
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
		dom := dominio.Elemento(r.IntN(dominio.NumElementos))
		out[i] = MembroElenco{
			ID:     NaviID(i + 1),
			Perfil: dominio.Perfil{Roleta: roletaCom(dom, 30+r.Float64()*45), Tracos: t},
			Area:   AreaID(r.IntN(numAreas)),
		}
	}
	return out
}
