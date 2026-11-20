package sim

import (
	"math"
	"strings"

	"navicity/internal/dominio"
)

// NaviID é o identificador do NAVI dentro da cidade.
type NaviID uint32

type Estado uint8

const (
	Ocioso      Estado = iota // parado numa área, aberto a conversa
	Andando                   // numa passagem entre áreas
	Conversando               // ocupado com outro NAVI
)

// Necessidades vão de 0 (satisfeita) a 1 (urgente). São elas que movem o
// NAVI: ninguém escreve "às 15h vá ao café"; o café acontece porque a
// novidade e a vontade social cresceram.
type Necessidades struct {
	Social   float64 // vontade de conversar
	Novidade float64 // tédio do lugar atual
	Cansaco  float64
}

// Relacao é o que UM NAVI sente sobre outro. A→B e B→A são objetos
// diferentes: é aqui que mora a assimetria.
type Relacao struct {
	Afinidade float64 // 0..100
	Encontros int
	Ultimo    Instante
	// Tom é o rótulo que o NAVI dá à relação. Não é recalculado a cada
	// conversa: só muda ao cruzar a fronteira com folga (ver novoTom).
	Tom dominio.Tom
}

// folgaTom é a histerese do tom. Sem ela, uma afinidade oscilando entre 34 e
// 36 gerava um fato "marcante" a cada conversa (hostil, indiferente, hostil…),
// e o dono do NAVI receberia notícia de uma mudança que não existiu.
const folgaTom = 3

// novoTom decide o tom com histerese: para sair de uma faixa é preciso
// passar da fronteira por pelo menos folgaTom pontos.
func novoTom(atual dominio.Tom, af float64) dominio.Tom {
	bruto := dominio.ClassificarTom(int(math.Round(af)))
	if bruto == atual {
		return atual
	}
	switch {
	case bruto == dominio.Hostil && af <= 35-folgaTom:
		return dominio.Hostil
	case bruto == dominio.Amistoso && af >= 65+folgaTom:
		return dominio.Amistoso
	case bruto == dominio.Indiferente && af >= 35+folgaTom && af <= 65-folgaTom:
		return dominio.Indiferente
	}
	return atual
}

// meiaVidaEsquecimento: sem se ver, a afinidade volta para o neutro (50).
// Uma relação forte de 90 vira 70 em uma semana sem contato.
const meiaVidaEsquecimento = 7 * Dia

// tempoMagoado: depois de um "não", quanto tempo o NAVI evita chamar de novo.
const tempoMagoado = 2 * Hora

// AfinidadeEm aplica o esquecimento de forma preguiçosa: em vez de atualizar
// todas as relações a cada minuto, calcula o valor só quando alguém pergunta.
func (r Relacao) AfinidadeEm(agora Instante) float64 {
	dt := float64(agora - r.Ultimo)
	if dt <= 0 {
		return r.Afinidade
	}
	fator := math.Exp2(-dt / float64(meiaVidaEsquecimento))
	return 50 + (r.Afinidade-50)*fator
}

type Navi struct {
	ID      NaviID
	Apelido string
	// GM marca os game masters (como a Iris): NAVIs da casa, de elemento
	// Cyber, que o app mostra com um selo próprio.
	GM     bool
	Perfil dominio.Perfil

	Area    AreaID // onde está (ou de onde saiu, se Andando)
	Destino AreaID // só vale se Andando
	Estado  Estado
	Nec     Necessidades

	necEm    Instante            // quando Nec foi atualizada pela última vez
	visitas  []Instante          // última visita por área; -1 = nunca
	relacoes map[NaviID]*Relacao // map é ok: nunca é iterado para gerar fatos
	recusas  map[NaviID]Instante // quem recusou conversa com ele, e quando
	gen      uint64
}

// Relacao devolve uma cópia do que este NAVI sente pelo outro.
func (n *Navi) Relacao(outro NaviID) (Relacao, bool) {
	r, ok := n.relacoes[outro]
	if !ok {
		return Relacao{}, false
	}
	return *r, true
}

// f normaliza um traço 0..100 para 0..1.
func f(v int) float64 { return float64(v) / 100 }

// Taxas por hora. Ficam juntas porque são os números que mais vão mudar no
// ajuste fino (a mesma ideia do RegrasCidade no app).
const (
	taxaSocial    = 0.15 // por hora, multiplicada por (0,5 + sociabilidade)
	taxaNovidade  = 0.10 // por hora parado, multiplicada por (0,5 + curiosidade)
	taxaDescanso  = 0.25 // cansaço que some por hora ocioso
	taxaCaminhada = 0.30 // cansaço que cresce por hora andando
	taxaConversa  = 0.05 // conversar cansa um pouco
)

// avancarNecessidades aplica o tempo que passou desde a última atualização,
// usando as taxas do estado ATUAL. Por isso precisa ser chamada ANTES de
// trocar o estado: senão a caminhada seria cobrada como descanso.
func (n *Navi) avancarNecessidades(agora Instante) {
	h := (agora - n.necEm).horas()
	if h <= 0 {
		return
	}
	t := n.Perfil.Tracos
	n.Nec.Social += h * taxaSocial * (0.5 + f(t[dominio.Sociabilidade]))
	switch n.Estado {
	case Ocioso:
		n.Nec.Novidade += h * taxaNovidade * (0.5 + f(t[dominio.Curiosidade]))
		n.Nec.Cansaco -= h * taxaDescanso
	case Andando:
		n.Nec.Cansaco += h * taxaCaminhada
	case Conversando:
		n.Nec.Novidade += h * taxaNovidade * 0.5 * (0.5 + f(t[dominio.Curiosidade]))
		n.Nec.Cansaco += h * taxaConversa
	}
	n.Nec.Social = limitar01(n.Nec.Social)
	n.Nec.Novidade = limitar01(n.Nec.Novidade)
	n.Nec.Cansaco = limitar01(n.Nec.Cansaco)
	n.necEm = agora
}

// novidadeDe diz o quanto uma área é "nova" para o NAVI: 1 se nunca foi,
// perto de 0 se acabou de sair de lá.
func (n *Navi) novidadeDe(a AreaID, agora Instante) float64 {
	v := n.visitas[a]
	if v < 0 {
		return 1
	}
	return 1 - math.Exp(-(agora-v).horas()/6)
}

func limitar01(x float64) float64 { return min(max(x, 0), 1) }

// Apelido deriva um nome do identificador, igual ao app: sem nome real
// trafegando, o apelido nasce do número.
func Apelido(id NaviID) string {
	silabas := [16]string{"ka", "ro", "vi", "lu", "ne", "sa", "to", "mi",
		"ze", "ba", "ru", "fe", "no", "ky", "ta", "el"}
	s := silabas[(id>>8)&0xF] + silabas[(id>>4)&0xF] + silabas[id&0xF]
	return strings.ToUpper(s[:1]) + s[1:]
}
