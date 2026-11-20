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
	"navicity/internal/gm"
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

func TestCidadeTrazAreasEOReloginho(t *testing.T) {
	a := novoAmbiente(t)
	c := novoCliente(t)
	_, corpo := a.registrar(c)
	c.id = itoa(int64(corpo["id"].(float64)))

	status, cid := a.enviar(a.pedido(c, "GET", "/cidade", nil))
	if status != http.StatusOK {
		t.Fatalf("/cidade: %d", status)
	}
	areas, ok := cid["areas"].([]any)
	if !ok || len(areas) != 3 {
		t.Fatalf("esperava 3 áreas, veio %v", cid["areas"])
	}
	praca := areas[0].(map[string]any)
	if praca["tipo"] != "praca" || praca["voce"] != true || praca["presentes"].(float64) < 1 {
		t.Fatalf("a praça deveria ter o NAVI do dono: %v", praca)
	}
	if _, ok := cid["agora_s"].(float64); !ok {
		t.Fatalf("faltou agora_s: %v", cid)
	}
}

func TestClienteNaoRegistraComoGM(t *testing.T) {
	a := novoAmbiente(t)
	c := novoCliente(t)
	corpo, _ := json.Marshal(map[string]any{
		"chave_publica": base64.StdEncoding.EncodeToString(c.pub),
		"perfil":        map[string]any{"elemento": "cyber", "tracos": []string{"calma"}},
	})
	if status, _ := a.enviar(a.pedido(c, "POST", "/navis", corpo)); status != http.StatusBadRequest {
		t.Fatalf("cyber deveria dar 400, deu %d", status)
	}
}

// ---------------------------------------------------------------- admin

const tokenTeste = "chave-de-teste-bem-longa-0123456789"

// ambienteAdmin sobe uma cidade com a Iris e as rotas /gm ligadas.
func ambienteAdmin(t *testing.T, comToken bool) (*httptest.Server, *gm.Loja) {
	t.Helper()
	s := sim.Nova(sim.MapaInicial(), 1)
	if err := s.Povoar([]sim.MembroElenco{sim.Iris()}); err != nil {
		t.Fatal(err)
	}
	c := cidade.Nova(s, 1)
	ctx, cancelar := context.WithCancel(context.Background())
	feito := make(chan struct{})
	go func() { defer close(feito); c.Rodar(ctx, time.Now()) }()
	loja := gm.NovaLoja(t.TempDir())
	srv := &Servidor{Cidade: c, Iris: loja}
	if comToken {
		srv.TokenAdmin = tokenTeste
	}
	h := httptest.NewServer(srv.Handler())
	t.Cleanup(func() { h.Close(); cancelar(); <-feito })
	return h, loja
}

func chamarAdmin(t *testing.T, base, metodo, token string, corpo any) (int, map[string]any) {
	t.Helper()
	var b []byte
	if corpo != nil {
		b, _ = json.Marshal(corpo)
	}
	r, _ := http.NewRequest(metodo, base+"/gm/iris", bytes.NewReader(b))
	if token != "" {
		r.Header.Set("Authorization", "Bearer "+token)
	}
	resp, err := http.DefaultClient.Do(r)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	var out map[string]any
	_ = json.NewDecoder(resp.Body).Decode(&out)
	return resp.StatusCode, out
}

func TestIrisDesligadaSemToken(t *testing.T) {
	h, _ := ambienteAdmin(t, false)
	if status, _ := chamarAdmin(t, h.URL, "GET", tokenTeste, nil); status != http.StatusNotFound {
		t.Fatalf("sem NAVICITY_ADMIN_TOKEN a rota deveria dar 404, deu %d", status)
	}
}

func TestIrisExigeAChaveDeAdministrador(t *testing.T) {
	h, _ := ambienteAdmin(t, true)
	for _, tok := range []string{"", "errada", tokenTeste + "x"} {
		if status, _ := chamarAdmin(t, h.URL, "GET", tok, nil); status != http.StatusUnauthorized {
			t.Fatalf("chave %q deveria dar 401, deu %d", tok, status)
		}
	}
}

func TestIrisLeEGravaConfiguracao(t *testing.T) {
	h, loja := ambienteAdmin(t, true)
	status, corpo := chamarAdmin(t, h.URL, "GET", tokenTeste, nil)
	if status != http.StatusOK || corpo["elemento"] != "cyber" || corpo["nome"] != "Iris" {
		t.Fatalf("GET: %d %v", status, corpo)
	}

	novo := map[string]any{
		"tracos":        map[string]int{"coragem": 11, "curiosidade": 22, "paciencia": 33, "sociabilidade": 44, "agressividade": 55},
		"personalidade": "Fala em rimas e adora a Biblioteca.",
	}
	if status, _ := chamarAdmin(t, h.URL, "PUT", tokenTeste, novo); status != http.StatusOK {
		t.Fatalf("PUT: %d", status)
	}
	gravada, err := loja.Carregar()
	if err != nil || gravada.Tracos.Sociabilidade != 44 || gravada.Personalidade != "Fala em rimas e adora a Biblioteca." {
		t.Fatalf("não gravou: %+v %v", gravada, err)
	}
}

func TestIrisRecusaConfiguracaoInvalida(t *testing.T) {
	h, loja := ambienteAdmin(t, true)
	ruim := map[string]any{"tracos": map[string]int{"coragem": 150}, "personalidade": ""}
	if status, _ := chamarAdmin(t, h.URL, "PUT", tokenTeste, ruim); status != http.StatusBadRequest {
		t.Fatalf("traço fora da faixa deveria dar 400, deu %d", status)
	}
	if status, _ := chamarAdmin(t, h.URL, "PUT", tokenTeste, map[string]any{"elemento": "fogo"}); status != http.StatusBadRequest {
		t.Fatalf("campo desconhecido deveria dar 400, deu %d", status)
	}
	if i, _ := loja.Carregar(); i.Tracos.Coragem == 150 {
		t.Fatal("configuração inválida não pode ser gravada")
	}
}

func TestCORSLiberaLocalETailscaleEBloqueiaOResto(t *testing.T) {
	h, _ := ambienteAdmin(t, true)
	cabecalhoCORS := func(origem string) string {
		r, _ := http.NewRequest("OPTIONS", h.URL+"/cidade", nil)
		r.Header.Set("Origin", origem)
		resp, err := http.DefaultClient.Do(r)
		if err != nil {
			t.Fatal(err)
		}
		resp.Body.Close()
		return resp.Header.Get("Access-Control-Allow-Origin")
	}
	for _, o := range []string{"http://localhost:8090", "http://100.98.182.120:8090"} {
		if got := cabecalhoCORS(o); got != o {
			t.Errorf("%s deveria ser liberada, veio %q", o, got)
		}
	}
	for _, o := range []string{"https://exemplo.com", "http://192.168.0.5:8090"} {
		if got := cabecalhoCORS(o); got != "" {
			t.Errorf("%s não deveria ser liberada, veio %q", o, got)
		}
	}
}
