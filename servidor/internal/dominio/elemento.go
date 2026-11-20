// Package dominio espelha as regras de domínio do app (lib/nucleo.dart).
//
// O app é a fonte da verdade: se um número mudar lá, muda aqui junto, e os
// testes de referência em afinidade_test.go precisam continuar batendo com o
// que o Dart calcula. Tudo aqui é função pura, sem I/O.
package dominio

import "fmt"

// Elemento segue a MESMA ordem do enum do Dart. Não reordene: o índice viaja
// no pacote BLE de 14 bytes (byte 5), e o app e o servidor precisam concordar
// sobre o que o número 2 significa.
type Elemento uint8

const (
	Agua Elemento = iota
	Fogo
	Gelo
	Ar
	Terra
	Raio
	Normal
	// Luz e Sombra existem no app da dev (que tem 8 elementos, não os 7 do
	// nucleo.dart). Vêm DEPOIS de Normal para não mudar o índice de ninguém,
	// e ficam fora do anel: são neutros, como Normal.
	Luz
	Sombra

	NumElementos = int(Sombra) + 1
)

// Nomes iguais ao `.name` do Dart, usados no JSON trocado com o app.
var nomesElemento = [NumElementos]string{"agua", "fogo", "gelo", "ar", "terra", "raio", "normal", "luz", "sombra"}

var rotulosElemento = [NumElementos]string{"Água", "Fogo", "Gelo", "Ar", "Terra", "Raio", "Normal", "Luz", "Sombra"}

// Valido diz se o número cabe no enum. Tudo que vem de fora (rede, banco)
// passa por aqui antes de virar índice de array.
func (e Elemento) Valido() bool { return int(e) < NumElementos }

// Nome é o identificador estável (o mesmo do Dart).
func (e Elemento) Nome() string {
	if !e.Valido() {
		return fmt.Sprintf("elemento(%d)", e)
	}
	return nomesElemento[e]
}

// String devolve o rótulo para humanos ("Água").
func (e Elemento) String() string {
	if !e.Valido() {
		return e.Nome()
	}
	return rotulosElemento[e]
}

// ElementoPorNome converte o nome do Dart de volta. O erro existe porque o
// texto vem de fora; nunca se confia no que chega.
func ElementoPorNome(s string) (Elemento, error) {
	for i, n := range nomesElemento {
		if n == s {
			return Elemento(i), nil
		}
	}
	return 0, fmt.Errorf("elemento desconhecido: %q", s)
}

func (e Elemento) MarshalText() ([]byte, error) {
	if !e.Valido() {
		return nil, fmt.Errorf("elemento inválido: %d", e)
	}
	return []byte(nomesElemento[e]), nil
}

func (e *Elemento) UnmarshalText(b []byte) error {
	v, err := ElementoPorNome(string(b))
	if err != nil {
		return err
	}
	*e = v
	return nil
}

// anel de vantagens: cada elemento vence os DOIS seguintes. Com alcance 1, a
// simulação do app (30 mil confrontos) deixava 66% das disputas neutras.
// Normal fica fora do anel: é neutro com todo mundo.
var anel = [...]Elemento{Agua, Fogo, Gelo, Ar, Terra, Raio}

const alcanceAnel = 2

// posicaoNoAnel devolve -1 para quem está fora (Normal).
func posicaoNoAnel(e Elemento) int {
	for i, x := range anel {
		if x == e {
			return i
		}
	}
	return -1
}

// Vence diz se a vence b no anel. Na Etapa 1 isso não é combate: só pesa na
// química da afinidade.
func Vence(a, b Elemento) bool {
	ia, ib := posicaoNoAnel(a), posicaoNoAnel(b)
	if ia < 0 || ib < 0 {
		return false
	}
	for d := 1; d <= alcanceAnel; d++ {
		if ib == (ia+d)%len(anel) {
			return true
		}
	}
	return false
}
