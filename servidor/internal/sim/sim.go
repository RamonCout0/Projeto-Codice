// Package sim é o núcleo da simulação da NAVICity: puro, determinístico,
// sem I/O. Recebe "avance até o instante X" e devolve os fatos que aconteceram.
//
// Por enquanto roda numa goroutine só. A divisão em goroutines por área vem
// depois do benchmark: só vale a complexidade se uma goroutine não der conta.
// O desenho já ajuda: o que cruza áreas (uma chegada) é um evento, e eventos
// podem virar mensagens entre goroutines no futuro.
package sim

import (
	"container/heap"
	"fmt"
	"math"
	"math/rand/v2"
	"slices"

	"navicity/internal/dominio"
)

type Sim struct {
	agora Instante
	mapa  *Mapa

	navis     []*Navi // ordem de entrada: é a ordem usada em qualquer varredura
	porID     map[NaviID]*Navi
	presentes [][]NaviID // por área, na ordem de chegada

	fila     fila
	seq      uint64
	rng      *rand.Rand
	fatos    []Fato
	seqFatos uint64
}

// Nova cria a cidade. A mesma semente com as mesmas entradas produz
// exatamente os mesmos fatos: é o que permite reproduzir um bug.
func Nova(m *Mapa, semente uint64) *Sim {
	return &Sim{
		mapa:      m,
		porID:     make(map[NaviID]*Navi),
		presentes: make([][]NaviID, m.NumAreas()),
		// PCG é rápido, tem estado pequeno e é reproduzível entre versões do Go.
		rng: rand.New(rand.NewPCG(semente, semente^0x9E3779B97F4A7C15)),
	}
}

func (s *Sim) Agora() Instante { return s.agora }
func (s *Sim) Mapa() *Mapa     { return s.mapa }

// Navis devolve os NAVIs em ordem de entrada. São ponteiros internos: quem
// chama deve apenas ler (o executável e os testes).
func (s *Sim) Navis() []*Navi { return s.navis }

// Navi devolve o NAVI pelo id. É ponteiro interno: só leitura.
func (s *Sim) Navi(id NaviID) (*Navi, bool) {
	n, ok := s.porID[id]
	return n, ok
}

// AdicionarNavi coloca um NAVI na cidade. Valida o perfil porque, no futuro,
// ele chega pela rede vindo do app.
func (s *Sim) AdicionarNavi(id NaviID, p dominio.Perfil, area AreaID) error {
	if err := p.Validar(); err != nil {
		return fmt.Errorf("NAVI %d: %w", id, err)
	}
	if _, existe := s.porID[id]; existe {
		return fmt.Errorf("NAVI %d já está na cidade", id)
	}
	if !s.mapa.valida(area) {
		return fmt.Errorf("área inexistente: %d", area)
	}
	n := &Navi{
		ID:       id,
		Apelido:  Apelido(id),
		Perfil:   p,
		Area:     area,
		Estado:   Ocioso,
		Nec:      Necessidades{Social: 0.5, Novidade: 0.3},
		necEm:    s.agora,
		visitas:  make([]Instante, s.mapa.NumAreas()),
		relacoes: make(map[NaviID]*Relacao),
		recusas:  make(map[NaviID]Instante),
	}
	for i := range n.visitas {
		n.visitas[i] = -1
	}
	n.visitas[area] = s.agora
	s.navis = append(s.navis, n)
	s.porID[id] = n
	s.presentes[area] = append(s.presentes[area], id)
	s.registrar(Fato{Tipo: FatoEntrou, Importancia: Normal, Area: area, Navi: id})
	// Espalha a primeira decisão para todo mundo não pensar no mesmo segundo.
	s.agendar(n, evDecidir, s.agora+s.duracao(1*Minuto, 10*Minuto), 0)
	return nil
}

// Avancar processa todos os eventos até o instante "ate" (inclusive) e
// devolve os fatos gerados. O slice devolvido passa a ser de quem chamou.
func (s *Sim) Avancar(ate Instante) []Fato {
	for len(s.fila) > 0 && s.fila[0].quando <= ate {
		e := heap.Pop(&s.fila).(evento)
		s.agora = e.quando
		s.processar(e)
	}
	s.agora = max(s.agora, ate)
	out := s.fatos
	s.fatos = nil
	return out
}

func (s *Sim) agendar(n *Navi, t tipoEvento, quando Instante, outro NaviID) {
	s.seq++
	heap.Push(&s.fila, evento{quando: quando, seq: s.seq, tipo: t, navi: n.ID, outro: outro, gen: n.gen})
}

func (s *Sim) registrar(f Fato) {
	s.seqFatos++
	f.Seq = s.seqFatos
	f.Quando = s.agora
	s.fatos = append(s.fatos, f)
}

// duracao sorteia um tempo uniforme entre min e max.
func (s *Sim) duracao(min, max Instante) Instante {
	return min + Instante(s.rng.Int64N(int64(max-min)+1))
}

func (s *Sim) processar(e evento) {
	n, ok := s.porID[e.navi]
	if !ok || e.gen != n.gen {
		return // evento de um plano que já foi substituído
	}
	switch e.tipo {
	case evDecidir:
		s.decidir(n)
	case evChegar:
		s.chegar(n)
	case evFimConversa:
		s.fimConversa(n, s.porID[e.outro])
	}
}

func (s *Sim) decidir(n *Navi) {
	n.avancarNecessidades(s.agora)
	ops := s.opcoes(n)
	a := ops[escolher(s.rng, ops, temperatura(n.Perfil.Tracos))]

	switch a.tipo {
	case acaoFicar:
		n.Estado = Ocioso
		s.agendar(n, evDecidir, s.agora+s.duracao(10*Minuto, 30*Minuto), 0)
	case acaoAndar:
		s.removerPresente(n)
		n.Estado = Andando
		n.Destino = a.ligacao.Para
		s.registrar(Fato{Tipo: FatoPartiu, Importancia: Trivial, Area: n.Area, Navi: n.ID, Destino: n.Destino})
		s.agendar(n, evChegar, s.agora+a.ligacao.Duracao, 0)
	case acaoConversar:
		s.puxarConversa(n, s.porID[a.alvo])
	}
}

func (s *Sim) chegar(n *Navi) {
	n.avancarNecessidades(s.agora)
	// O alívio do tédio depende de quão nova a área é; calcular ANTES de
	// marcar a visita, senão toda área pareceria "acabei de vir aqui".
	n.Nec.Novidade *= 1 - 0.6*n.novidadeDe(n.Destino, s.agora)
	n.Area = n.Destino
	n.Estado = Ocioso
	n.visitas[n.Area] = s.agora
	s.presentes[n.Area] = append(s.presentes[n.Area], n.ID)
	s.registrar(Fato{Tipo: FatoChegou, Importancia: Trivial, Area: n.Area, Navi: n.ID})
	s.agendar(n, evDecidir, s.agora+Minuto, 0)
}

func (s *Sim) removerPresente(n *Navi) {
	p := s.presentes[n.Area]
	if i := slices.Index(p, n.ID); i >= 0 {
		s.presentes[n.Area] = slices.Delete(p, i, i+1)
	}
}

// puxarConversa: o alvo pode recusar. Aceitar depende do jeito DELE, não de
// quem chamou — outra fonte de assimetria.
func (s *Sim) puxarConversa(a, b *Navi) {
	b.avancarNecessidades(s.agora)
	tb := b.Perfil.Tracos
	aceita := 0.25 + 0.5*f(tb[dominio.Sociabilidade]) - 0.3*b.Nec.Cansaco
	if r, ok := b.relacoes[a.ID]; ok {
		aceita += (r.AfinidadeEm(s.agora) - 50) / 100
	} else {
		aceita += 0.2 * f(tb[dominio.Curiosidade])
	}
	aceita = min(max(aceita, 0.05), 0.95)

	if s.rng.Float64() >= aceita {
		s.registrar(Fato{Tipo: FatoRecusou, Importancia: Normal, Area: a.Area, Navi: a.ID, Outro: b.ID})
		a.recusas[b.ID] = s.agora
		// O não magoa um pouco, menos para quem é paciente. Só quem levou o
		// não sente isso: mais uma fonte de assimetria.
		if r, ok := a.relacoes[b.ID]; ok {
			r.Afinidade = max(r.AfinidadeEm(s.agora)-2*(1-f(a.Perfil.Tracos[dominio.Paciencia])), 0)
			r.Ultimo = s.agora
			s.talvezMudouTom(a, b, r)
		}
		a.Estado = Ocioso
		s.agendar(a, evDecidir, s.agora+s.duracao(2*Minuto, 5*Minuto), 0)
		return
	}

	// b tinha uma decisão agendada (estava ocioso); a conversa a invalida.
	b.gen++
	a.gen++
	a.Estado, b.Estado = Conversando, Conversando

	if _, conhece := a.relacoes[b.ID]; !conhece {
		// Primeiro encontro: a fórmula do app, simétrica, para os dois lados.
		v := dominio.PrimeiraImpressao(
			a.Perfil.Roleta.Dominante(), b.Perfil.Roleta.Dominante(),
			a.Perfil.Tracos, b.Perfil.Tracos)
		tom := dominio.ClassificarTom(v)
		a.relacoes[b.ID] = &Relacao{Afinidade: float64(v), Ultimo: s.agora, Tom: tom}
		b.relacoes[a.ID] = &Relacao{Afinidade: float64(v), Ultimo: s.agora, Tom: tom}
		s.registrar(Fato{Tipo: FatoConheceu, Importancia: Marcante, Area: a.Area,
			Navi: a.ID, Outro: b.ID, Afinidade: v, AfinidadeVolta: v, Tom: tom})
	}

	// Quem se gosta conversa mais tempo.
	media := (a.relacoes[b.ID].AfinidadeEm(s.agora) + b.relacoes[a.ID].AfinidadeEm(s.agora)) / 2
	dur := s.duracao(5*Minuto, 10*Minuto) + Instante(media/100*10)*Minuto
	s.agendar(a, evFimConversa, s.agora+dur, b.ID)
}

func (s *Sim) fimConversa(a, b *Navi) {
	a.avancarNecessidades(s.agora)
	b.avancarNecessidades(s.agora)
	ra, rb := a.relacoes[b.ID], b.relacoes[a.ID]

	// O esquecimento é aplicado agora, de vez, antes de somar a conversa.
	antesA, antesB := ra.AfinidadeEm(s.agora), rb.AfinidadeEm(s.agora)

	// q é a "qualidade" da conversa, compartilhada pelos dois: relações boas
	// tendem a conversas boas, mas o acaso sempre participa. O +0,15 é o
	// efeito da convivência: conversar, em média, aproxima. Sem ele, quem
	// começava abaixo de 50 só afundava (a primeira versão fazia isso).
	q := 0.15 + (antesA+antesB-100)/200 + (s.rng.Float64() - 0.5)
	ra.Afinidade = aplicarDelta(antesA, s.impacto(a, b, q))
	rb.Afinidade = aplicarDelta(antesB, s.impacto(b, a, q))
	ra.Encontros++
	rb.Encontros++
	ra.Ultimo, rb.Ultimo = s.agora, s.agora

	alivio := 0.5
	a.Nec.Social = limitar01(a.Nec.Social - alivio)
	b.Nec.Social = limitar01(b.Nec.Social - alivio)

	va, vb := int(math.Round(ra.Afinidade)), int(math.Round(rb.Afinidade))
	s.registrar(Fato{Tipo: FatoConversou, Importancia: Normal, Area: a.Area, Navi: a.ID, Outro: b.ID,
		Afinidade: va, AfinidadeVolta: vb,
		Delta: va - int(math.Round(antesA)), DeltaVolta: vb - int(math.Round(antesB))})

	s.talvezMudouTom(a, b, ra)
	s.talvezMudouTom(b, a, rb)

	a.Estado, b.Estado = Ocioso, Ocioso
	// Horários diferentes para os dois não decidirem em sincronia eterna.
	s.agendar(a, evDecidir, s.agora+Minuto, 0)
	s.agendar(b, evDecidir, s.agora+2*Minuto, 0)
}

// impacto: quanto a conversa muda o que "quem" sente por "outro". Cada lado
// sente a mesma conversa do seu jeito:
//   - sociáveis se deixam levar mais pelo clima da conversa;
//   - agressividade do outro incomoda, mas paciência amortece;
//   - um pouco de ruído subjetivo, porque ninguém é uma fórmula.
func (s *Sim) impacto(quem, outro *Navi, q float64) float64 {
	tq, to := quem.Perfil.Tracos, outro.Perfil.Tracos
	d := 6 * q * (0.5 + f(tq[dominio.Sociabilidade]))
	if agr := to[dominio.Agressividade]; agr > 50 {
		d -= 4 * float64(agr-50) / 50 * (1 - f(tq[dominio.Paciencia]))
	}
	return d + (s.rng.Float64()-0.5)*2
}

// aplicarDelta tem retorno decrescente perto dos extremos: ganhar pontos de
// quem já é melhor amigo (ou perder de quem já é desafeto) fica difícil.
// Sem isso, em uma semana toda amizade batia 100 e virava teto.
func aplicarDelta(antes, d float64) float64 {
	if d > 0 {
		d *= min((100-antes)/50, 1)
	} else {
		d *= min(antes/50, 1)
	}
	return min(max(antes+d, 0), 100)
}

func (s *Sim) talvezMudouTom(quem, outro *Navi, r *Relacao) {
	tom := novoTom(r.Tom, r.Afinidade)
	if tom == r.Tom {
		return
	}
	r.Tom = tom
	s.registrar(Fato{Tipo: FatoMudouTom, Importancia: Marcante, Area: quem.Area,
		Navi: quem.ID, Outro: outro.ID, Afinidade: int(math.Round(r.Afinidade)), Tom: tom})
}
