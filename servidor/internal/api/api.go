// Package api é a porta HTTP da NAVICity para o app.
//
// Autenticação (decisão de projeto): Ed25519 por instalação, requisição
// assinada, verificação SEMPRE no servidor. Não há senha nem token: o app
// gera um par de chaves, manda a pública no registro e assina cada pedido
// com a privada. Por isso o tráfego não carrega segredo, e HTTP puro dentro
// da rede privada (Tailscale) não expõe credencial alguma.
//
// O que é assinado (um texto, uma linha por campo):
//
//	MÉTODO
//	caminho?query
//	carimbo (segundos Unix, o mesmo do cabeçalho X-Carimbo)
//	sha256 do corpo, em hexadecimal
//
// Cabeçalhos: X-Navi (id, só depois do registro), X-Carimbo, X-Assinatura
// (Ed25519 em base64 padrão). O carimbo só vale numa janela curta; dentro
// dela um pedido GET repetido é inofensivo (só lê) e um POST /navis repetido
// bate na chave já registrada (409).
package api

import (
	"bytes"
	"context"
	"crypto/ed25519"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"slices"
	"strconv"
	"strings"
	"time"

	"navicity/internal/cidade"
	"navicity/internal/dominio"
	"navicity/internal/gm"
	"navicity/internal/sim"
)

const (
	janelaCarimbo  = 60 * time.Second
	maxCorpo       = 4 << 10 // um perfil cabe folgado em 4 KB
	maxFatosPagina = 200
)

type Servidor struct {
	Cidade *cidade.Cidade

	// TokenAdmin libera as rotas /gm/*. Vazio = rotas desligadas (404).
	// Quem configura a Iris é o dono da cidade, nunca um jogador.
	TokenAdmin string
	Iris       *gm.Loja

	// Origens extras liberadas no CORS (o app web); localhost e a rede do
	// Tailscale já passam.
	Origens []string
	// Agora existe para os testes fixarem o relógio.
	Agora func() time.Time
}

func (s *Servidor) agora() time.Time {
	if s.Agora != nil {
		return s.Agora()
	}
	return time.Now()
}

func (s *Servidor) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /saude", func(w http.ResponseWriter, _ *http.Request) {
		escrever(w, http.StatusOK, map[string]string{"estado": "ok"})
	})
	mux.HandleFunc("POST /navis", s.registrar)
	mux.HandleFunc("GET /cidade", s.autenticado(s.situacao))
	mux.HandleFunc("GET /fatos", s.autenticado(s.fatos))
	mux.HandleFunc("GET /gm/iris", s.admin(s.lerIris))
	mux.HandleFunc("PUT /gm/iris", s.admin(s.salvarIris))
	return s.comCORS(mux)
}

// Servir sobe o servidor HTTP e desliga com o ctx.
func (s *Servidor) Servir(ctx context.Context, endereco string) error {
	srv := &http.Server{
		Addr:              endereco,
		Handler:           s.Handler(),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
		BaseContext:       func(_ net.Listener) context.Context { return ctx },
	}
	erro := make(chan error, 1)
	go func() { erro <- srv.ListenAndServe() }()
	select {
	case err := <-erro:
		return err
	case <-ctx.Done():
		parar, cancelar := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancelar()
		return srv.Shutdown(parar)
	}
}

// ---------------------------------------------------------------- assinatura

func mensagemAssinada(metodo, destino string, carimbo int64, corpo []byte) []byte {
	h := sha256.Sum256(corpo)
	return fmt.Appendf(nil, "%s\n%s\n%d\n%s", metodo, destino, carimbo, hex.EncodeToString(h[:]))
}

// AssinarPedido é o lado do cliente. Fica aqui (e não só nos testes) porque é
// a especificação executável: o app em Dart precisa produzir os mesmos bytes.
func AssinarPedido(priv ed25519.PrivateKey, metodo, destino string, carimbo int64, corpo []byte) string {
	return base64.StdEncoding.EncodeToString(ed25519.Sign(priv, mensagemAssinada(metodo, destino, carimbo, corpo)))
}

var errAssinatura = errors.New("assinatura inválida")

// conferir valida carimbo e assinatura contra a chave. Qualquer defeito vira
// o MESMO erro: quem testa o servidor não aprende o que errou.
func (s *Servidor) conferir(r *http.Request, chave ed25519.PublicKey, corpo []byte) error {
	carimbo, err := strconv.ParseInt(r.Header.Get("X-Carimbo"), 10, 64)
	if err != nil {
		return errAssinatura
	}
	if d := s.agora().Sub(time.Unix(carimbo, 0)); d > janelaCarimbo || d < -janelaCarimbo {
		return errAssinatura
	}
	assinatura, err := base64.StdEncoding.DecodeString(r.Header.Get("X-Assinatura"))
	if err != nil || len(assinatura) != ed25519.SignatureSize {
		return errAssinatura
	}
	if !ed25519.Verify(chave, mensagemAssinada(r.Method, r.URL.RequestURI(), carimbo, corpo), assinatura) {
		return errAssinatura
	}
	return nil
}

func lerCorpo(w http.ResponseWriter, r *http.Request) ([]byte, bool) {
	corpo, err := io.ReadAll(http.MaxBytesReader(w, r.Body, maxCorpo))
	if err != nil {
		erroJSON(w, http.StatusRequestEntityTooLarge, "corpo grande demais")
		return nil, false
	}
	return corpo, true
}

// autenticado confere a assinatura do NAVI dono do X-Navi e entrega o id ao
// handler. Falha de qualquer tipo (id ausente, desconhecido, assinatura
// errada) responde 401 igual, para não revelar quais ids existem.
func (s *Servidor) autenticado(h func(http.ResponseWriter, *http.Request, sim.NaviID)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		corpo, ok := lerCorpo(w, r)
		if !ok {
			return
		}
		n, err := strconv.ParseUint(r.Header.Get("X-Navi"), 10, 32)
		if err != nil {
			erroJSON(w, http.StatusUnauthorized, "assinatura inválida")
			return
		}
		id := sim.NaviID(n)
		chave, existe := s.Cidade.Chave(r.Context(), id)
		if !existe || s.conferir(r, chave, corpo) != nil {
			erroJSON(w, http.StatusUnauthorized, "assinatura inválida")
			return
		}
		h(w, r, id)
	}
}

// ------------------------------------------------------------------ handlers

type pedidoRegistro struct {
	ChavePublica string `json:"chave_publica"`
	Perfil       struct {
		Elemento string   `json:"elemento"`
		Tracos   []string `json:"tracos"`
	} `json:"perfil"`
}

// registrar entra na cidade. O pedido é assinado com a chave que ele mesmo
// traz: prova que quem registra tem a chave privada (e não só a pública).
func (s *Servidor) registrar(w http.ResponseWriter, r *http.Request) {
	corpo, ok := lerCorpo(w, r)
	if !ok {
		return
	}
	var p pedidoRegistro
	dec := json.NewDecoder(bytes.NewReader(corpo))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&p); err != nil {
		erroJSON(w, http.StatusBadRequest, "JSON inválido")
		return
	}
	bruta, err := base64.StdEncoding.DecodeString(p.ChavePublica)
	if err != nil || len(bruta) != ed25519.PublicKeySize {
		erroJSON(w, http.StatusBadRequest, "chave_publica precisa ser uma chave Ed25519 de 32 bytes em base64")
		return
	}
	chave := ed25519.PublicKey(bruta)
	if s.conferir(r, chave, corpo) != nil {
		erroJSON(w, http.StatusUnauthorized, "assinatura inválida")
		return
	}
	perfil, err := dominio.PerfilDoApp(p.Perfil.Elemento, p.Perfil.Tracos)
	if err != nil {
		erroJSON(w, http.StatusBadRequest, err.Error())
		return
	}
	sit, err := s.Cidade.Registrar(r.Context(), chave, perfil)
	switch {
	case errors.Is(err, cidade.ErroChaveJaRegistrada):
		erroJSON(w, http.StatusConflict, err.Error())
	case err != nil:
		erroJSON(w, http.StatusInternalServerError, "não foi possível entrar na cidade")
	default:
		escrever(w, http.StatusCreated, jsonSituacao(sit))
	}
}

func jsonSituacao(sit cidade.Situacao) map[string]any {
	return map[string]any{
		"id":      sit.ID,
		"apelido": sit.Apelido,
		"area":    sit.Area,
		"estado":  sit.Estado,
		"areas":   sit.Areas,
		"agora_s": sit.AgoraSeg,
	}
}

func (s *Servidor) situacao(w http.ResponseWriter, r *http.Request, id sim.NaviID) {
	sit, ok := s.Cidade.Situacao(r.Context(), id)
	if !ok {
		erroJSON(w, http.StatusNotFound, "NAVI não está na cidade")
		return
	}
	escrever(w, http.StatusOK, jsonSituacao(sit))
}

func (s *Servidor) fatos(w http.ResponseWriter, r *http.Request, id sim.NaviID) {
	var desde uint64
	if v := r.URL.Query().Get("desde"); v != "" {
		n, err := strconv.ParseUint(v, 10, 64)
		if err != nil {
			erroJSON(w, http.StatusBadRequest, "desde precisa ser um número")
			return
		}
		desde = n
	}
	vistos, cursor, agora, err := s.Cidade.Fatos(r.Context(), id, desde, maxFatosPagina)
	if err != nil {
		erroJSON(w, http.StatusServiceUnavailable, "cidade indisponível")
		return
	}
	if vistos == nil {
		vistos = []cidade.VistaFato{} // [] e não null no JSON
	}
	escrever(w, http.StatusOK, map[string]any{"fatos": vistos, "cursor": cursor, "agora_s": agora})
}

// ------------------------------------------------------------------- helpers

func escrever(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

// erroJSON usa a chave "erro", a mesma que o app já lê da API de login.
func erroJSON(w http.ResponseWriter, status int, msg string) {
	escrever(w, status, map[string]string{"erro": msg})
}

// ------------------------------------------------------------------ admin

// admin exige "Authorization: Bearer <TokenAdmin>". A comparação é em tempo
// constante (sobre o hash, para não vazar nem o tamanho do token).
func (s *Servidor) admin(h http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if s.TokenAdmin == "" || s.Iris == nil {
			erroJSON(w, http.StatusNotFound, "rota não encontrada")
			return
		}
		recebido := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
		a, b := sha256.Sum256([]byte(recebido)), sha256.Sum256([]byte(s.TokenAdmin))
		if subtle.ConstantTimeCompare(a[:], b[:]) != 1 {
			erroJSON(w, http.StatusUnauthorized, "chave de administrador inválida")
			return
		}
		h(w, r)
	}
}

type respostaIris struct {
	Nome          string    `json:"nome"`
	Elemento      string    `json:"elemento"`
	Tracos        gm.Tracos `json:"tracos"`
	Personalidade string    `json:"personalidade"`
}

func jsonIris(i gm.Iris) respostaIris {
	return respostaIris{Nome: "Iris", Elemento: dominio.Cyber.Nome(), Tracos: i.Tracos, Personalidade: i.Personalidade}
}

func (s *Servidor) lerIris(w http.ResponseWriter, _ *http.Request) {
	i, err := s.Iris.Carregar()
	if err != nil {
		erroJSON(w, http.StatusInternalServerError, "não consegui ler a configuração da Iris")
		return
	}
	escrever(w, http.StatusOK, jsonIris(i))
}

func (s *Servidor) salvarIris(w http.ResponseWriter, r *http.Request) {
	corpo, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 16<<10))
	if err != nil {
		erroJSON(w, http.StatusRequestEntityTooLarge, "corpo grande demais")
		return
	}
	var i gm.Iris
	dec := json.NewDecoder(bytes.NewReader(corpo))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&i); err != nil {
		erroJSON(w, http.StatusBadRequest, "JSON inválido")
		return
	}
	if err := i.Validar(); err != nil {
		erroJSON(w, http.StatusBadRequest, err.Error())
		return
	}
	// Primeiro a cidade (ao vivo), depois o arquivo: se a cidade recusar,
	// nada é gravado.
	if err := s.Cidade.DefinirIris(r.Context(), i.Tracos.Dominio()); err != nil {
		erroJSON(w, http.StatusInternalServerError, "a cidade recusou os traços da Iris")
		return
	}
	if err := s.Iris.Salvar(i); err != nil {
		erroJSON(w, http.StatusInternalServerError, "não consegui gravar a configuração")
		return
	}
	escrever(w, http.StatusOK, jsonIris(i))
}

// ------------------------------------------------------------------- CORS

// origemPermitida: o app web roda em outra origem. Passam localhost, a rede
// do Tailscale (100.64.0.0/10) e as origens listadas em Origens.
func (s *Servidor) origemPermitida(origem string) bool {
	if slices.Contains(s.Origens, origem) {
		return true
	}
	u, err := url.Parse(origem)
	if err != nil || (u.Scheme != "http" && u.Scheme != "https") {
		return false
	}
	h := u.Hostname()
	if h == "localhost" || h == "127.0.0.1" || h == "::1" {
		return true
	}
	var a, b, c, d int
	if n, _ := fmt.Sscanf(h, "%d.%d.%d.%d", &a, &b, &c, &d); n == 4 && a == 100 && b >= 64 && b <= 127 {
		return true
	}
	return false
}

func (s *Servidor) comCORS(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if o := r.Header.Get("Origin"); o != "" && s.origemPermitida(o) {
			w.Header().Set("Access-Control-Allow-Origin", o)
			w.Header().Set("Vary", "Origin")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type, Accept, X-Navi, X-Carimbo, X-Assinatura")
			w.Header().Set("Access-Control-Max-Age", "600")
		}
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		h.ServeHTTP(w, r)
	})
}
