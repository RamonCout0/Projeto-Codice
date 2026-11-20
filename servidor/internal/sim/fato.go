package sim

import (
	"fmt"

	"navicity/internal/dominio"
)

// Fato é a unidade do registro append-only. Tudo que acontece na cidade vira
// um fato estruturado; quem transforma isso em frase bonita é o modelo de
// linguagem no celular. O Descrever daqui é só para o terminal e os testes.
type Fato struct {
	Seq         uint64
	Quando      Instante
	Tipo        TipoFato
	Importancia Importancia
	Area        AreaID
	Navi        NaviID
	Outro       NaviID // conversa, recusa, mudança de tom
	Destino     AreaID // partida

	// Afinidade é Navi→Outro e AfinidadeVolta é Outro→Navi, depois do fato.
	// Os deltas mostram quanto cada lado mudou. São campos separados porque
	// a mesma conversa pode aproximar um e afastar o outro.
	Afinidade, AfinidadeVolta int
	Delta, DeltaVolta         int
	Tom                       dominio.Tom
}

type TipoFato uint8

const (
	FatoEntrou    TipoFato = iota // NAVI entrou na cidade
	FatoPartiu                    // saiu de uma área rumo a outra
	FatoChegou                    // chegou numa área
	FatoConheceu                  // primeiro encontro de um par
	FatoConversou                 // conversa de quem já se conhecia
	FatoRecusou                   // Outro recusou a conversa de Navi
	FatoMudouTom                  // o que Navi sente por Outro mudou de faixa
)

// Importancia guia a retenção: triviais podem ser resumidos ou ir para o HD;
// marcantes ficam guardados por mais tempo.
type Importancia uint8

const (
	Trivial Importancia = iota
	Normal
	Marcante
)

// tomRelacao concorda com "relação" (feminino), evitando adivinhar o gênero
// dos NAVIs.
func tomRelacao(t dominio.Tom) string {
	switch t {
	case dominio.Hostil:
		return "hostil"
	case dominio.Amistoso:
		return "amistosa"
	default:
		return "indiferente"
	}
}

// Descrever transforma o fato em uma linha legível (sem I/O: só devolve texto).
func (s *Sim) Descrever(f Fato) string {
	nome := func(id NaviID) string {
		if n, ok := s.porID[id]; ok {
			return n.Apelido
		}
		return fmt.Sprintf("NAVI#%d", id)
	}
	area := func(a AreaID) string { return s.mapa.Area(a).Nome }
	quem, outro := nome(f.Navi), nome(f.Outro)

	var txt string
	switch f.Tipo {
	case FatoEntrou:
		txt = fmt.Sprintf("%s entrou na cidade", quem)
	case FatoPartiu:
		txt = fmt.Sprintf("%s partiu rumo a %s", quem, area(f.Destino))
	case FatoChegou:
		txt = fmt.Sprintf("%s chegou", quem)
	case FatoConheceu:
		txt = fmt.Sprintf("%s puxou conversa e conheceu %s · primeira impressão %d (%s)",
			quem, outro, f.Afinidade, f.Tom)
	case FatoConversou:
		txt = fmt.Sprintf("%s e %s conversaram · %s→%s %d (%+d), %s→%s %d (%+d)",
			quem, outro, quem, outro, f.Afinidade, f.Delta, outro, quem, f.AfinidadeVolta, f.DeltaVolta)
	case FatoRecusou:
		txt = fmt.Sprintf("%s recusou a conversa de %s", outro, quem)
	case FatoMudouTom:
		txt = fmt.Sprintf("a relação de %s com %s ficou %s (%d)", quem, outro, tomRelacao(f.Tom), f.Afinidade)
	default:
		txt = fmt.Sprintf("fato desconhecido %d", f.Tipo)
	}
	return fmt.Sprintf("%s [%s] %s", f.Quando, area(f.Area), txt)
}
