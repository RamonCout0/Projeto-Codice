// Package gm guarda a configuração dos game masters da cidade (hoje, a Iris):
// os traços que movem o comportamento dela e um texto de personalidade, que
// o modelo de linguagem usará para narrar. Fica num arquivo JSON simples.
package gm

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sync"

	"navicity/internal/dominio"
	"navicity/internal/sim"
)

const MaxPersonalidade = 800

// Tracos é o formato de JSON dos cinco traços (0 a 100).
type Tracos struct {
	Coragem       int `json:"coragem"`
	Curiosidade   int `json:"curiosidade"`
	Paciencia     int `json:"paciencia"`
	Sociabilidade int `json:"sociabilidade"`
	Agressividade int `json:"agressividade"`
}

func (t Tracos) Dominio() dominio.Tracos {
	return dominio.Tracos{t.Coragem, t.Curiosidade, t.Paciencia, t.Sociabilidade, t.Agressividade}
}

func DeDominio(t dominio.Tracos) Tracos {
	return Tracos{t[0], t[1], t[2], t[3], t[4]}
}

// Iris é o que o dono configura.
type Iris struct {
	Tracos        Tracos `json:"tracos"`
	Personalidade string `json:"personalidade"`
}

// Padrao é a Iris de fábrica.
func Padrao() Iris {
	return Iris{
		Tracos: DeDominio(sim.TracosPadraoIris),
		Personalidade: "Iris é a game master da NAVICity: calma, curiosa e paciente. " +
			"Observa a cidade de cima e fala pouco, com um toque de ironia.",
	}
}

// Validar recusa traços fora de 0..100 e textos longos ou com caracteres de
// controle (a mensagem vai para dentro de um prompt).
func (i Iris) Validar() error {
	if err := i.Tracos.Dominio().Validar(); err != nil {
		return err
	}
	if len([]rune(i.Personalidade)) > MaxPersonalidade {
		return fmt.Errorf("a personalidade pode ter até %d caracteres", MaxPersonalidade)
	}
	for _, r := range i.Personalidade {
		if r < 0x20 && r != '\n' && r != '\t' {
			return errors.New("a personalidade tem caracteres inválidos")
		}
	}
	return nil
}

// Loja lê e grava a configuração num arquivo.
type Loja struct {
	caminho string
	mu      sync.Mutex
}

// NovaLoja usa dir/iris.json. Sem dir, nada é gravado (modo só memória).
func NovaLoja(dir string) *Loja {
	if dir == "" {
		return &Loja{}
	}
	return &Loja{caminho: filepath.Join(dir, "iris.json")}
}

// Carregar devolve a configuração gravada, ou a de fábrica se não houver.
func (l *Loja) Carregar() (Iris, error) {
	l.mu.Lock()
	defer l.mu.Unlock()
	if l.caminho == "" {
		return Padrao(), nil
	}
	b, err := os.ReadFile(l.caminho)
	if errors.Is(err, os.ErrNotExist) {
		return Padrao(), nil
	}
	if err != nil {
		return Iris{}, err
	}
	var i Iris
	if err := json.Unmarshal(b, &i); err != nil {
		return Iris{}, fmt.Errorf("iris.json inválido: %w", err)
	}
	return i, i.Validar()
}

// Salvar grava de forma atômica (arquivo temporário + rename).
func (l *Loja) Salvar(i Iris) error {
	if err := i.Validar(); err != nil {
		return err
	}
	l.mu.Lock()
	defer l.mu.Unlock()
	if l.caminho == "" {
		return nil
	}
	if err := os.MkdirAll(filepath.Dir(l.caminho), 0o755); err != nil {
		return err
	}
	b, err := json.MarshalIndent(i, "", "  ")
	if err != nil {
		return err
	}
	tmp := l.caminho + ".tmp"
	if err := os.WriteFile(tmp, b, 0o600); err != nil {
		return err
	}
	return os.Rename(tmp, l.caminho)
}
