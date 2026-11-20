package gm

import (
	"strings"
	"testing"
)

func TestSalvarECarregar(t *testing.T) {
	l := NovaLoja(t.TempDir())
	if i, err := l.Carregar(); err != nil || i.Tracos.Paciencia != 90 {
		t.Fatalf("sem arquivo deveria vir a Iris de fábrica: %+v %v", i, err)
	}
	novo := Iris{Tracos: Tracos{10, 20, 30, 40, 50}, Personalidade: "Fala em rimas."}
	if err := l.Salvar(novo); err != nil {
		t.Fatal(err)
	}
	got, err := NovaLoja(l.caminho[:len(l.caminho)-len("/iris.json")]).Carregar()
	if err != nil || got != novo {
		t.Fatalf("voltou %+v, esperado %+v (%v)", got, novo, err)
	}
}

func TestValidar(t *testing.T) {
	casos := map[string]Iris{
		"traço alto":     {Tracos: Tracos{101, 0, 0, 0, 0}},
		"traço negativo": {Tracos: Tracos{0, -1, 0, 0, 0}},
		"texto longo":    {Personalidade: strings.Repeat("a", MaxPersonalidade+1)},
		"controle":       {Personalidade: "oi\x07"},
	}
	for nome, i := range casos {
		if err := i.Validar(); err == nil {
			t.Errorf("%s: esperava erro", nome)
		}
	}
}
