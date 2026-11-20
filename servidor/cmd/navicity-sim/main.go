// navicity-sim roda a cidade no terminal, em tempo simulado acelerado,
// e imprime os fatos. Serve para ver se o comportamento faz sentido.
//
//	./dgo run ./cmd/navicity-sim                 # 5 NAVIs, 1 dia
//	./dgo run ./cmd/navicity-sim -horas 72 -tudo # 3 dias, inclusive triviais
//	./dgo run ./cmd/navicity-sim -semente 7      # outra história
package main

import (
	"flag"
	"fmt"
	"os"

	"navicity/internal/sim"
)

func main() {
	semente := flag.Uint64("semente", 42, "semente da aleatoriedade (mesma semente = mesma história)")
	horas := flag.Int("horas", 24, "quantas horas simuladas rodar")
	tudo := flag.Bool("tudo", false, "mostrar também fatos triviais (partidas e chegadas)")
	flag.Parse()

	if err := rodar(*semente, *horas, *tudo); err != nil {
		fmt.Fprintln(os.Stderr, "erro:", err)
		os.Exit(1)
	}
}

func rodar(semente uint64, horas int, tudo bool) error {
	s := sim.Nova(sim.MapaInicial(), semente)
	for _, m := range sim.ElencoDeTeste() {
		if err := s.AdicionarNavi(m.ID, m.Perfil, m.Area); err != nil {
			return err
		}
	}

	contagem := map[sim.TipoFato]int{}
	for h := 1; h <= horas; h++ {
		for _, f := range s.Avancar(sim.Instante(h) * sim.Hora) {
			contagem[f.Tipo]++
			if tudo || f.Importancia > sim.Trivial {
				fmt.Println(s.Descrever(f))
			}
		}
	}

	fmt.Printf("\n== %d h simuladas · %d conversas, %d recusas, %d primeiros encontros, %d mudanças de tom\n",
		horas, contagem[sim.FatoConversou], contagem[sim.FatoRecusou],
		contagem[sim.FatoConheceu], contagem[sim.FatoMudouTom])
	imprimirMatriz(s)
	return nil
}

// imprimirMatriz mostra quanto cada NAVI (linha) gosta de cada outro (coluna).
// A matriz NÃO é simétrica: é a rede social assimétrica aparecendo.
func imprimirMatriz(s *sim.Sim) {
	navis := s.Navis()
	fmt.Printf("\nAfinidade (linha → coluna), agora:\n%-9s", "")
	for _, n := range navis {
		fmt.Printf("%9s", n.Apelido)
	}
	fmt.Println()
	for _, a := range navis {
		fmt.Printf("%-9s", a.Apelido)
		for _, b := range navis {
			r, ok := a.Relacao(b.ID)
			switch {
			case a.ID == b.ID:
				fmt.Printf("%9s", "·")
			case !ok:
				fmt.Printf("%9s", "-")
			default:
				fmt.Printf("%9.0f", r.AfinidadeEm(s.Agora()))
			}
		}
		fmt.Printf("   (%s)\n", s.Mapa().Area(a.Area).Nome)
	}
}
