// Package cidade liga a simulação (pura, uma goroutine só) ao mundo de fora.
//
// A regra de ouro do núcleo é que UMA goroutine toca no *sim.Sim. A API HTTP
// atende cada pedido numa goroutine diferente, então ela nunca chama a
// simulação direto: manda uma função por um canal e a goroutine da cidade a
// executa entre as batidas do relógio. Sem mutex, sem corrida.
package cidade

import (
	"context"
	"crypto/ed25519"
	"crypto/rand"
	"encoding/binary"
	"errors"
	"fmt"
	"time"

	"navicity/internal/dominio"
	"navicity/internal/sim"
)

// maxFatosGuardados limita o registro em memória. Quando o Postgres chegar,
// é ele quem guarda tudo; aqui só precisa caber o que o app ainda não leu.
// O cursor (Seq) continua válido porque nunca é reaproveitado.
const maxFatosGuardados = 50_000

var ErroChaveJaRegistrada = errors.New("esta chave já tem um NAVI na cidade")

type Cidade struct {
	sim    *sim.Sim
	escala float64
	cmds   chan func()

	// Os três campos abaixo só são tocados pela goroutine de Rodar.
	fatos    []sim.Fato
	chaves   map[sim.NaviID]ed25519.PublicKey
	porChave map[string]sim.NaviID
}

func Nova(s *sim.Sim, escala float64) *Cidade {
	return &Cidade{
		sim:      s,
		escala:   escala,
		cmds:     make(chan func()),
		chaves:   make(map[sim.NaviID]ed25519.PublicKey),
		porChave: make(map[string]sim.NaviID),
	}
}

// Rodar é o laço da cidade: relógio real → simulação, e atende a API. Volta
// quando o ctx é cancelado.
func (c *Cidade) Rodar(ctx context.Context, inicio time.Time) {
	batida := time.NewTicker(time.Second)
	defer batida.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case fn := <-c.cmds:
			fn()
		case agora := <-batida.C:
			// Alvo medido desde o INÍCIO (não somando 1 s por batida): se uma
			// batida atrasar, o relógio simulado não fica para trás.
			alvo := sim.Instante(agora.Sub(inicio).Seconds() * c.escala)
			for _, f := range c.sim.Avancar(alvo) {
				c.guardar(f)
				if f.Importancia > sim.Trivial {
					fmt.Println(c.sim.Descrever(f))
				}
			}
		}
	}
}

func (c *Cidade) guardar(f sim.Fato) {
	c.fatos = append(c.fatos, f)
	if len(c.fatos) > maxFatosGuardados {
		// Copia para um slice novo: reslice seguraria o array antigo inteiro.
		c.fatos = append([]sim.Fato(nil), c.fatos[len(c.fatos)-maxFatosGuardados/2:]...)
	}
}

// faz executa fn na goroutine da cidade e espera. Se o ctx acabar antes, o
// chamador desiste; fn só escreve em variáveis que ele não lê mais.
func (c *Cidade) faz(ctx context.Context, fn func()) error {
	feito := make(chan struct{})
	envio := func() { fn(); close(feito) }
	select {
	case c.cmds <- envio:
	case <-ctx.Done():
		return ctx.Err()
	}
	select {
	case <-feito:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}

// Registrar põe um NAVI novo na Praça. O id é sorteado pelo servidor: o app
// não escolhe quem é na cidade, só prova que é dono da chave.
func (c *Cidade) Registrar(ctx context.Context, chave ed25519.PublicKey, perfil dominio.Perfil) (Situacao, error) {
	var (
		out Situacao
		err error
	)
	if e := c.faz(ctx, func() {
		if _, existe := c.porChave[string(chave)]; existe {
			err = ErroChaveJaRegistrada
			return
		}
		id, e := c.novoID()
		if e != nil {
			err = e
			return
		}
		if e := c.sim.AdicionarNavi(id, perfil, sim.Praca); e != nil {
			err = e
			return
		}
		c.chaves[id] = append(ed25519.PublicKey(nil), chave...)
		c.porChave[string(chave)] = id
		out, _ = c.situacao(id)
	}); e != nil {
		return Situacao{}, e
	}
	return out, err
}

// novoID sorteia um id de 32 bits que ainda não existe (o id viaja em 32
// bits no anúncio BLE do app).
func (c *Cidade) novoID() (sim.NaviID, error) {
	for range 16 {
		var b [4]byte
		if _, err := rand.Read(b[:]); err != nil {
			return 0, err
		}
		id := sim.NaviID(binary.BigEndian.Uint32(b[:]))
		if _, existe := c.sim.Navi(id); !existe {
			return id, nil
		}
	}
	return 0, errors.New("não consegui sortear um id livre")
}

// Chave devolve a chave pública do NAVI, para a API conferir assinaturas.
func (c *Cidade) Chave(ctx context.Context, id sim.NaviID) (ed25519.PublicKey, bool) {
	var (
		k  ed25519.PublicKey
		ok bool
	)
	if err := c.faz(ctx, func() { k, ok = c.chaves[id] }); err != nil {
		return nil, false
	}
	return k, ok
}

// Situacao é onde o NAVI está agora.
type Situacao struct {
	ID      sim.NaviID
	Apelido string
	Area    string
	Estado  string
	Areas   []string
}

func (c *Cidade) situacao(id sim.NaviID) (Situacao, bool) {
	n, ok := c.sim.Navi(id)
	if !ok {
		return Situacao{}, false
	}
	m := c.sim.Mapa()
	areas := make([]string, m.NumAreas())
	for i := range areas {
		areas[i] = m.Area(sim.AreaID(i)).Nome
	}
	estado := "ocioso"
	switch n.Estado {
	case sim.Andando:
		estado = "andando"
	case sim.Conversando:
		estado = "conversando"
	}
	return Situacao{ID: id, Apelido: n.Apelido, Area: m.Area(n.Area).Nome, Estado: estado, Areas: areas}, true
}

func (c *Cidade) Situacao(ctx context.Context, id sim.NaviID) (Situacao, bool) {
	var (
		s  Situacao
		ok bool
	)
	if err := c.faz(ctx, func() { s, ok = c.situacao(id) }); err != nil {
		return Situacao{}, false
	}
	return s, ok
}

// VistaFato é um fato contado do ponto de vista de UM NAVI (o dono que
// pergunta). Só traz apelidos e nomes de lugar: nada que identifique gente.
type VistaFato struct {
	Seq         uint64 `json:"seq"`
	QuandoSeg   int64  `json:"quando_s"` // segundos desde o nascimento da cidade
	Tipo        string `json:"tipo"`
	Importancia string `json:"importancia"`
	Area        string `json:"area"`
	Destino     string `json:"destino,omitempty"`
	Outro       string `json:"outro,omitempty"` // apelido do outro NAVI
	// Lado diz se o NAVI do dono puxou o fato ("origem") ou o sofreu ("alvo").
	Lado string `json:"lado,omitempty"`
	// Afinidade e Delta são sempre do ponto de vista do NAVI do dono.
	Afinidade *int   `json:"afinidade,omitempty"`
	Delta     *int   `json:"delta,omitempty"`
	Tom       string `json:"tom,omitempty"`
}

// Fatos devolve, em ordem, os fatos com Seq > desde que envolvem o NAVI, até
// limite. O app guarda o maior Seq recebido e pede "desde" ele da próxima vez.
// ProximoCursor é o Seq do último fato VISTO na varredura (mesmo os que não
// interessam ao NAVI), para o app não reler o mesmo trecho à toa.
func (c *Cidade) Fatos(ctx context.Context, id sim.NaviID, desde uint64, limite int) (vistos []VistaFato, proximoCursor uint64, err error) {
	proximoCursor = desde
	err = c.faz(ctx, func() {
		m := c.sim.Mapa()
		apelido := func(o sim.NaviID) string {
			if n, ok := c.sim.Navi(o); ok {
				return n.Apelido
			}
			return ""
		}
		for _, f := range c.fatos {
			if f.Seq <= desde {
				continue
			}
			if len(vistos) >= limite {
				break
			}
			proximoCursor = f.Seq
			v, ok := vista(f, id, m, apelido)
			if ok {
				vistos = append(vistos, v)
			}
		}
	})
	return vistos, proximoCursor, err
}

func vista(f sim.Fato, eu sim.NaviID, m *sim.Mapa, apelido func(sim.NaviID) string) (VistaFato, bool) {
	sou := func(a sim.NaviID) bool { return a == eu }
	if !sou(f.Navi) && !sou(f.Outro) {
		return VistaFato{}, false
	}
	v := VistaFato{
		Seq:         f.Seq,
		QuandoSeg:   int64(f.Quando),
		Importancia: nomeImportancia(f.Importancia),
		Area:        m.Area(f.Area).Nome,
	}
	origem := sou(f.Navi)
	if origem {
		v.Lado = "origem"
		v.Outro = apelido(f.Outro)
	} else {
		v.Lado = "alvo"
		v.Outro = apelido(f.Navi)
	}
	inteiro := func(x int) *int { return &x }

	switch f.Tipo {
	case sim.FatoEntrou, sim.FatoChegou:
		if !origem {
			return VistaFato{}, false
		}
		v.Tipo, v.Outro, v.Lado = map[sim.TipoFato]string{sim.FatoEntrou: "entrou", sim.FatoChegou: "chegou"}[f.Tipo], "", ""
	case sim.FatoPartiu:
		if !origem {
			return VistaFato{}, false
		}
		v.Tipo, v.Outro, v.Lado = "partiu", "", ""
		v.Destino = m.Area(f.Destino).Nome
	case sim.FatoConheceu, sim.FatoConversou:
		v.Tipo = map[sim.TipoFato]string{sim.FatoConheceu: "conheceu", sim.FatoConversou: "conversou"}[f.Tipo]
		af, delta := f.Afinidade, f.Delta
		if !origem {
			af, delta = f.AfinidadeVolta, f.DeltaVolta
		}
		v.Afinidade, v.Delta = inteiro(af), inteiro(delta)
		if f.Tipo == sim.FatoConheceu {
			v.Tom = f.Tom.String()
			v.Delta = nil
		}
	case sim.FatoRecusou:
		v.Tipo = "recusou"
	case sim.FatoMudouTom:
		// O que o NAVI sente pelo outro é só dele: o alvo não fica sabendo.
		if !origem {
			return VistaFato{}, false
		}
		v.Tipo, v.Tom = "mudou_tom", f.Tom.String()
		v.Afinidade = inteiro(f.Afinidade)
	default:
		return VistaFato{}, false
	}
	return v, true
}

func nomeImportancia(i sim.Importancia) string {
	switch i {
	case sim.Marcante:
		return "marcante"
	case sim.Normal:
		return "normal"
	default:
		return "trivial"
	}
}
