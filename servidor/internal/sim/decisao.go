package sim

import (
	"math"
	"math/rand/v2"

	"navicity/internal/dominio"
)

// Utility AI: cada ação possível ganha uma nota a partir das necessidades e
// da personalidade, e o NAVI SORTEIA entre elas com softmax. Ele não escolhe
// sempre a melhor: a temperatura controla o quanto ele é imprevisível.

type tipoAcao uint8

const (
	acaoFicar tipoAcao = iota
	acaoAndar
	acaoConversar
)

type acao struct {
	tipo      tipoAcao
	ligacao   Ligacao // se acaoAndar
	alvo      NaviID  // se acaoConversar
	utilidade float64
}

// temperatura vem da personalidade: NAVI impaciente é mais impulsivo.
// Temperatura baixa → quase sempre a melhor nota; alta → quase aleatório.
func temperatura(t dominio.Tracos) float64 {
	return 0.08 + 0.15*(1-f(t[dominio.Paciencia]))
}

// opcoes lista as ações com nota. A ordem do slice é determinística
// (vizinhos na ordem do mapa, presentes na ordem de chegada), e isso importa:
// o sorteio percorre o slice.
func (s *Sim) opcoes(n *Navi) []acao {
	t := n.Perfil.Tracos
	nec := n.Nec
	ops := make([]acao, 0, 8)

	// Ficar: atrai quem está cansado ou é paciente; o tédio empurra para fora.
	ops = append(ops, acao{
		tipo:      acaoFicar,
		utilidade: 0.2 + 0.8*nec.Cansaco + 0.2*f(t[dominio.Paciencia]) - 0.3*nec.Novidade,
	})

	// Andar: novidade do destino e gente lá, menos o custo da caminhada.
	for _, l := range s.mapa.Vizinhos(n.Area) {
		u := nec.Novidade*(0.4+0.6*f(t[dominio.Curiosidade]))*n.novidadeDe(l.Para, s.agora) +
			nec.Social*f(t[dominio.Sociabilidade])*s.atracaoSocial(n, l.Para) -
			0.5*nec.Cansaco -
			0.02*float64(l.Duracao/Minuto)
		ops = append(ops, acao{tipo: acaoAndar, ligacao: l, utilidade: u})
	}

	// Conversar com cada NAVI ocioso na mesma área.
	for _, id := range s.presentes[n.Area] {
		outro := s.porID[id]
		if id == n.ID || outro.Estado != Ocioso {
			continue
		}
		// Levou um não há pouco: não insiste. Sem isso o NAVI virava chato,
		// chamando a mesma pessoa a cada três minutos.
		if quando, ok := n.recusas[id]; ok && s.agora-quando < tempoMagoado {
			continue
		}
		var vontade float64
		if r, ok := n.relacoes[id]; ok {
			// Centrado na fronteira do hostil (35): abaixo disso a vontade
			// fica NEGATIVA, e o NAVI passa a evitar quem não gosta.
			gosto := (r.AfinidadeEm(s.agora) - 35) / 65
			vontade = 0.2 + 1.2*gosto
			// Acabaram de conversar: o assunto esgotou por enquanto.
			if s.agora-r.Ultimo < Hora {
				vontade *= 0.4
			}
		} else {
			// Desconhecido: puxar conversa exige coragem.
			vontade = 0.4 + 0.4*f(t[dominio.Coragem])
		}
		u := nec.Social * (0.3 + 0.7*f(t[dominio.Sociabilidade])) * vontade
		ops = append(ops, acao{tipo: acaoConversar, alvo: id, utilidade: u})
	}
	return ops
}

// atracaoSocial: quanta gente há numa área e se há alguém querido lá.
// Por enquanto o NAVI "enxerga" a cidade toda; o boca a boca vai limitar isso.
func (s *Sim) atracaoSocial(n *Navi, a AreaID) float64 {
	pres := s.presentes[a]
	pop := min(float64(len(pres)), 3) / 3
	melhor := 0.0
	for _, id := range pres {
		if r, ok := n.relacoes[id]; ok {
			if af := r.AfinidadeEm(s.agora); af > 65 {
				melhor = max(melhor, (af-65)/35)
			}
		}
	}
	return 0.5*pop + 0.5*melhor
}

// escolher sorteia uma ação com softmax: peso = exp(utilidade / temperatura).
func escolher(r *rand.Rand, ops []acao, temp float64) int {
	temp = max(temp, 0.01)
	// Subtrair o máximo antes do exp evita estouro de float com notas altas
	// e não muda as proporções (é o mesmo que dividir todos por uma constante).
	maior := ops[0].utilidade
	for _, o := range ops[1:] {
		maior = max(maior, o.utilidade)
	}
	pesos := make([]float64, len(ops))
	total := 0.0
	for i, o := range ops {
		pesos[i] = math.Exp((o.utilidade - maior) / temp)
		total += pesos[i]
	}
	x := r.Float64() * total
	for i, p := range pesos {
		x -= p
		if x < 0 {
			return i
		}
	}
	return len(ops) - 1 // só por arredondamento de float
}
