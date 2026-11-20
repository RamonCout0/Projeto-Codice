// navicity-server mantém a cidade viva em tempo real, 24 horas por dia.
//
// Liga o relógio real ao núcleo, escreve os fatos no stdout (veja com
// `docker compose logs -f navicity`) e, com NAVICITY_ENDERECO, expõe a API
// assinada para o app. Postgres e WebSocket entram depois. Sem Postgres, a
// cidade RECOMEÇA do zero a cada reinício do container: os NAVIs registrados
// somem e o app precisa se registrar de novo.
//
// Configuração por variável de ambiente:
//
//	TIME_SCALE  quantos segundos simulados por segundo real (padrão 1)
//	SEMENTE     semente da aleatoriedade (padrão 42)
//	NAVICITY_DADOS         pasta onde a configuração da Iris é gravada
//	NAVICITY_ADMIN_TOKEN   chave de administrador (sem ela, /gm/* fica desligada)
//	NAVICITY_ENDERECO  onde a API escuta, ex.: 0.0.0.0:8080 (vazio = sem API)
package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"navicity/internal/api"
	"navicity/internal/cidade"
	"navicity/internal/gm"
	"navicity/internal/sim"
)

func main() {
	// Erro de configuração derruba o processo com código 1. Com
	// restart: unless-stopped o Docker tentaria de novo, e a mensagem fica
	// nos logs para dizer o que está errado.
	if err := rodar(); err != nil {
		fmt.Fprintln(os.Stderr, "erro:", err)
		os.Exit(1)
	}
}

type config struct {
	escala   float64
	semente  uint64
	endereco string // vazio = sem API

	// dados é a pasta do iris.json; tokenAdmin libera /gm/*.
	dados      string
	tokenAdmin string
}

func lerConfig() (config, error) {
	c := config{escala: 1, semente: 42, endereco: os.Getenv("NAVICITY_ENDERECO"), dados: os.Getenv("NAVICITY_DADOS"), tokenAdmin: os.Getenv("NAVICITY_ADMIN_TOKEN")}
	if v := os.Getenv("TIME_SCALE"); v != "" {
		e, err := strconv.ParseFloat(v, 64)
		if err != nil || e <= 0 {
			return c, fmt.Errorf("TIME_SCALE inválido %q: precisa ser um número maior que zero", v)
		}
		c.escala = e
	}
	if v := os.Getenv("SEMENTE"); v != "" {
		s, err := strconv.ParseUint(v, 10, 64)
		if err != nil {
			return c, fmt.Errorf("SEMENTE inválida %q: %w", v, err)
		}
		c.semente = s
	}
	return c, nil
}

func rodar() error {
	cfg, err := lerConfig()
	if err != nil {
		return err
	}

	s := sim.Nova(sim.MapaInicial(), cfg.semente)
	// A Iris nasce com a configuração que o dono gravou (ou a de fábrica).
	loja := gm.NovaLoja(cfg.dados)
	iris, err := loja.Carregar()
	if err != nil {
		return fmt.Errorf("configuração da Iris: %w", err)
	}
	if err := s.Povoar(sim.ResidentesCom(iris.Tracos.Dominio())); err != nil {
		return err
	}
	c := cidade.Nova(s, cfg.escala)

	// O ctx é cancelado quando chega SIGTERM (docker stop) ou Ctrl+C. Isso
	// importa mais dentro de container: o processo é o PID 1, e o PID 1 que
	// não trata sinais simplesmente não morre com SIGTERM. O Docker esperaria
	// o stop_grace_period e mataria na força (SIGKILL). Quando houver
	// Postgres, é nesse desligamento limpo que salvamos o snapshot.
	ctx, parar := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer parar()

	fmt.Printf("NAVICity no ar · %d NAVIs · TIME_SCALE=%g · semente %d\n",
		len(s.Navis()), cfg.escala, cfg.semente)

	// Uma goroutine só toca na simulação (cidade.Rodar). A API conversa com
	// ela por canal: veja o pacote cidade.
	feito := make(chan struct{})
	go func() {
		defer close(feito)
		c.Rodar(ctx, time.Now())
	}()

	if cfg.endereco == "" {
		fmt.Println("API desligada (defina NAVICITY_ENDERECO para ligar)")
		<-ctx.Done()
		<-feito
		return nil
	}
	fmt.Printf("API em http://%s\n", cfg.endereco)
	srv := &api.Servidor{Cidade: c, TokenAdmin: cfg.tokenAdmin, Iris: loja}
	if cfg.tokenAdmin == "" {
		fmt.Println("configuração da Iris desligada (defina NAVICITY_ADMIN_TOKEN para ligar)")
	}
	err = srv.Servir(ctx, cfg.endereco)
	parar()
	<-feito
	return err
}
