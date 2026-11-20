package api

import (
	"bytes"
	"context"
	"crypto/ed25519"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"navicity/internal/cidade"
	"navicity/internal/sim"
)

// ambiente sobe uma cidade de verdade (sem o elenco de teste) e um servidor
// HTTP de teste, com o relógio da API fixado.
type ambiente struct {
	t     *testing.T
	srv   *httptest.Server
	agora time.Time
}

func novoAmbiente(t *testing.T) *ambiente {
	t.Helper()
	c := cidade.Nova(sim.Nova(sim.MapaInicial(), 1), 1)
	ctx, cancelar := context.WithCancel(context.Background())
	feito := make(chan struct{})
	go func() { defer close(feito); c.Rodar(ctx, time.Now()) }()

	a := &ambiente{t: t, agora: time.Unix(1_800_000_000, 0)}
	s := &Servidor{Cidade: c, Agora: func() time.Time { return a.agora }}
	a.srv = httptest.NewServer(s.Handler())
	t.Cleanup(func() { a.srv.Close(); cancelar(); <-feito })
	return a
}

type cliente struct {
	pub  ed25519.PublicKey
	priv ed25519.PrivateKey
	id   string
}

func novoCliente(t *testing.T) *cliente {
	pub, priv, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	return &cliente{pub: pub, priv: priv}
}

// pedido monta e assina uma requisição como o app faria.
func (a *ambiente) pedido(c *cliente, metodo, destino string, corpo []byte) *http.Request {
	r, err := http.NewRequest(metodo, a.srv.URL+destino, bytes.NewReader(corpo))
	if err != nil {
		a.t.Fatal(err)
	}
	carimbo := a.agora.Unix()
	r.Header.Set("X-Carimbo", itoa(carimbo))
	r.Header.Set("X-Assinatura", AssinarPedido(c.priv, metodo, destino, carimbo, corpo))
	if c.id != "" {
		r.Header.Set("X-Navi", c.id)
	}
	return r
}

func itoa(n int64) string { b, _ := json.Marshal(n); return string(b) }

func (a *ambiente) enviar(r *http.Request) (int, map[string]any) {
	resp, err := http.DefaultClient.Do(r)
	if err != nil {
		a.t.Fatal(err)
	}
	defer resp.Body.Close()
	var out map[string]any
	_ = json.NewDecoder(resp.Body).Decode(&out)
	return resp.StatusCode, out
}

func (a *ambiente) registrar(c *cliente) (int, map[string]any) {
	corpo, _ := json.Marshal(map[string]any{
		"chave_publica": base64.StdEncoding.EncodeToString(c.pub),
		"perfil":        map[string]any{"elemento": "gelo", "tracos": []string{"curiosa", "carinhosa"}},
	})
	return a.enviar(a.pedido(c, "POST", "/navis", corpo))
}

func TestRegistroEConsultaAssinada(t *testing.T) {
	a := novoAmbiente(t)
	c := novoCliente(t)

	status, corpo := a.registrar(c)
	if status != http.StatusCreated {
		t.Fatalf("registro: %d %v", status, corpo)
	}
	c.id = itoa(int64(corpo["id"].(float64)))
	if corpo["area"] != "Praça dos Bipes" {
		t.Fatalf("deveria nascer na praça: %v", corpo["area"])
	}

	if status, corpo := a.enviar(a.pedido(c, "GET", "/cidade", nil)); status != http.StatusOK || corpo["apelido"] == "" {
		t.Fatalf("/cidade: %d %v", status, corpo)
	}

	// O próprio registro gerou o fato "entrou", visto só pelo dono.
	status, corpo = a.enviar(a.pedido(c, "GET", "/fatos?desde=0", nil))
	if status != http.StatusOK {
		t.Fatalf("/fatos: %d %v", status, corpo)
	}
	if _, ok := corpo["fatos"].([]any); !ok {
		t.Fatalf("fatos deveria ser uma lista, veio %T", corpo["fatos"])
	}
}

func TestRegistroDuplicadoDaConflito(t *testing.T) {
	a := novoAmbiente(t)
	c := novoCliente(t)
	if status, _ := a.registrar(c); status != http.StatusCreated {
		t.Fatalf("primeiro registro: %d", status)
	}
	if status, _ := a.registrar(c); status != http.StatusConflict {
		t.Fatalf("segundo registro deveria dar 409, deu %d", status)
	}
}

func TestRegistroRecusaPerfilInvalido(t *testing.T) {
	a := novoAmbiente(t)
	c := novoCliente(t)
	corpo, _ := json.Marshal(map[string]any{
		"chave_publica": base64.StdEncoding.EncodeToString(c.pub),
		"perfil":        map[string]any{"elemento": "plasma", "tracos": []string{"calma"}},
	})
	if status, _ := a.enviar(a.pedido(c, "POST", "/navis", corpo)); status != http.StatusBadRequest {
		t.Fatalf("elemento inválido deveria dar 400, deu %d", status)
	}
}

func TestAssinaturaDeOutraChaveEhRecusada(t *testing.T) {
	a := novoAmbiente(t)
	dono, intruso := novoCliente(t), novoCliente(t)
	_, corpo := a.registrar(dono)
	dono.id = itoa(int64(corpo["id"].(float64)))

	// O intruso diz ser o dono, mas assina com a chave dele.
	intruso.id = dono.id
	if status, _ := a.enviar(a.pedido(intruso, "GET", "/fatos?desde=0", nil)); status != http.StatusUnauthorized {
		t.Fatalf("deveria dar 401, deu %d", status)
	}
}

func TestPedidoAdulteradoEhRecusado(t *testing.T) {
	a := novoAmbiente(t)
	c := novoCliente(t)
	_, corpo := a.registrar(c)
	c.id = itoa(int64(corpo["id"].(float64)))

	r := a.pedido(c, "GET", "/fatos?desde=0", nil)
	r.URL.RawQuery = "desde=999" // muda o que foi assinado
	if status, _ := a.enviar(r); status != http.StatusUnauthorized {
		t.Fatalf("query adulterada deveria dar 401, deu %d", status)
	}
}

func TestCarimboVelhoEhRecusado(t *testing.T) {
	a := novoAmbiente(t)
	c := novoCliente(t)
	_, corpo := a.registrar(c)
	c.id = itoa(int64(corpo["id"].(float64)))

	r := a.pedido(c, "GET", "/cidade", nil)
	a.agora = a.agora.Add(5 * time.Minute) // o servidor "avança" e o pedido envelhece
	if status, _ := a.enviar(r); status != http.StatusUnauthorized {
		t.Fatalf("carimbo fora da janela deveria dar 401, deu %d", status)
	}
}

func TestIdDesconhecidoEhIgualAAssinaturaErrada(t *testing.T) {
	a := novoAmbiente(t)
	c := novoCliente(t)
	c.id = "12345"
	status, corpo := a.enviar(a.pedido(c, "GET", "/cidade", nil))
	if status != http.StatusUnauthorized || !strings.Contains(corpo["erro"].(string), "assinatura") {
		t.Fatalf("id desconhecido deveria dar 401 genérico: %d %v", status, corpo)
	}
}

func TestSemAssinaturaNaoPassa(t *testing.T) {
	a := novoAmbiente(t)
	resp, err := http.Get(a.srv.URL + "/fatos")
	if err != nil {
		t.Fatal(err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("deveria dar 401, deu %d", resp.StatusCode)
	}
}
