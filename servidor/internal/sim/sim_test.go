package sim

import (
	"container/heap"
	"math/rand/v2"
	"reflect"
	"testing"

	"navicity/internal/dominio"
)

func novaComElenco(t *testing.T, semente uint64) *Sim {
	t.Helper()
	s := Nova(MapaInicial(), semente)
	for _, m := range ElencoDeTeste() {
		if err := s.AdicionarNavi(m.ID, m.Perfil, m.Area); err != nil {
			t.Fatal(err)
		}
	}
	return s
}

func TestFilaOrdenaPorInstanteESeq(t *testing.T) {
	var f fila
	for _, e := range []evento{{quando: 10, seq: 2}, {quando: 5, seq: 3}, {quando: 10, seq: 1}, {quando: 1, seq: 4}} {
		heap.Push(&f, e)
	}
	var got [][2]int64
	for f.Len() > 0 {
		e := heap.Pop(&f).(evento)
		got = append(got, [2]int64{int64(e.quando), int64(e.seq)})
	}
	want := [][2]int64{{1, 4}, {5, 3}, {10, 1}, {10, 2}}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("ordem = %v, esperado %v", got, want)
	}
}

// O teste mais importante do núcleo: mesma semente, mesmos fatos.
func TestDeterminismo(t *testing.T) {
	a := novaComElenco(t, 42).Avancar(3 * Dia)
	b := novaComElenco(t, 42).Avancar(3 * Dia)
	if len(a) == 0 {
		t.Fatal("nenhum fato em 3 dias")
	}
	if !reflect.DeepEqual(a, b) {
		t.Fatal("mesma semente gerou fatos diferentes")
	}
	c := novaComElenco(t, 7).Avancar(3 * Dia)
	if reflect.DeepEqual(a, c) {
		t.Fatal("sementes diferentes geraram exatamente os mesmos fatos")
	}
}

// Avançar em passos pequenos ou de uma vez tem que dar o mesmo resultado:
// o servidor real vai avançar aos pouquinhos, o teste de uma vez só.
func TestAvancarEmPassosEquivaleAUmSalto(t *testing.T) {
	inteiro := novaComElenco(t, 99).Avancar(2 * Dia)
	s := novaComElenco(t, 99)
	var aos_poucos []Fato
	for h := Instante(1); h <= 48; h++ {
		aos_poucos = append(aos_poucos, s.Avancar(h*Hora)...)
	}
	if !reflect.DeepEqual(inteiro, aos_poucos) {
		t.Fatal("avançar em passos mudou o resultado")
	}
}

func TestPrimeiroEncontroUsaFormulaDoApp(t *testing.T) {
	s := novaComElenco(t, 42)
	fatos := s.Avancar(2 * Dia)
	vistos := 0
	for _, f := range fatos {
		if f.Tipo != FatoConheceu {
			continue
		}
		vistos++
		if f.Afinidade != f.AfinidadeVolta {
			t.Fatalf("primeira impressão assimétrica: %d vs %d", f.Afinidade, f.AfinidadeVolta)
		}
	}
	if vistos == 0 {
		t.Fatal("ninguém se conheceu em 2 dias")
	}
}

// Depois de vários encontros, ao menos um par deve sentir coisas diferentes
// um pelo outro: a assimetria precisa EMERGIR, não ser sorteada no início.
func TestAssimetriaEmerge(t *testing.T) {
	s := novaComElenco(t, 42)
	s.Avancar(7 * Dia)
	for _, a := range s.Navis() {
		for _, b := range s.Navis() {
			ra, ok1 := a.Relacao(b.ID)
			rb, ok2 := b.Relacao(a.ID)
			if ok1 && ok2 && ra.Encontros > 0 && ra.Afinidade != rb.Afinidade {
				return
			}
		}
	}
	t.Fatal("nenhuma relação assimétrica depois de 7 dias")
}

// Invariante: cada NAVI está em exatamente um lugar (numa área, ou andando).
func TestCadaNaviEmUmLugarSo(t *testing.T) {
	s := Nova(MapaInicial(), 3)
	for _, m := range ElencoAleatorio(60, 3, 3) {
		if err := s.AdicionarNavi(m.ID, m.Perfil, m.Area); err != nil {
			t.Fatal(err)
		}
	}
	for h := Instante(1); h <= 72; h++ {
		s.Avancar(h * Hora)
		contagem := map[NaviID]int{}
		for area, ids := range s.presentes {
			for _, id := range ids {
				contagem[id]++
				if n := s.porID[id]; n.Area != AreaID(area) || n.Estado == Andando {
					t.Fatalf("%s listado em %d mas está em %d (estado %d)", n.Apelido, area, n.Area, n.Estado)
				}
			}
		}
		for _, n := range s.Navis() {
			esperado := 1
			if n.Estado == Andando {
				esperado = 0
			}
			if contagem[n.ID] != esperado {
				t.Fatalf("hora %d: %s aparece %d vezes (estado %d)", h, n.Apelido, contagem[n.ID], n.Estado)
			}
		}
	}
}

func TestEsquecimentoVoltaParaNeutro(t *testing.T) {
	r := Relacao{Afinidade: 90, Ultimo: 0}
	if got := r.AfinidadeEm(meiaVidaEsquecimento); got < 69.9 || got > 70.1 {
		t.Fatalf("depois de uma meia-vida: %.2f, esperado 70", got)
	}
	if got := r.AfinidadeEm(0); got != 90 {
		t.Fatalf("sem tempo passado: %.2f", got)
	}
}

func TestSoftmaxComTemperaturaBaixaEscolheAMelhor(t *testing.T) {
	r := rand.New(rand.NewPCG(1, 2))
	ops := []acao{{utilidade: 0.2}, {utilidade: 0.9}, {utilidade: 0.5}}
	for range 1000 {
		if i := escolher(r, ops, 0.01); i != 1 {
			t.Fatalf("escolheu %d com temperatura mínima", i)
		}
	}
}

func TestAdicionarNaviRecusaLixo(t *testing.T) {
	s := Nova(MapaInicial(), 1)
	m := ElencoDeTeste()[0]
	if err := s.AdicionarNavi(m.ID, m.Perfil, 99); err == nil {
		t.Fatal("área inexistente aceita")
	}
	ruim := m.Perfil
	ruim.Tracos[0] = 150
	if err := s.AdicionarNavi(m.ID, ruim, Praca); err == nil {
		t.Fatal("traço 150 aceito")
	}
	if err := s.AdicionarNavi(m.ID, m.Perfil, Praca); err != nil {
		t.Fatal(err)
	}
	if err := s.AdicionarNavi(m.ID, m.Perfil, Praca); err == nil {
		t.Fatal("NAVI duplicado aceito")
	}
}

func TestApelidoIgualAoApp(t *testing.T) {
	// id 0x123 → sílabas 1, 2, 3 → "ro" "vi" "lu"
	if got := Apelido(0x123); got != "Rovilu" {
		t.Fatalf("Apelido = %q", got)
	}
}

func TestTomTemHisterese(t *testing.T) {
	ind, hos, ami := dominio.Indiferente, dominio.Hostil, dominio.Amistoso
	casos := []struct {
		atual dominio.Tom
		af    float64
		quer  dominio.Tom
	}{
		{ind, 34, ind}, // cruzou 35 por pouco: continua indiferente
		{ind, 32, hos}, // cruzou com folga: vira hostil
		{hos, 36, hos}, // voltou por pouco: continua hostil
		{hos, 38, ind},
		{ind, 66, ind},
		{ind, 68, ami},
		{ami, 64, ami},
		{ami, 62, ind},
		{hos, 70, ami}, // salto grande atravessa direto
	}
	for _, c := range casos {
		if got := novoTom(c.atual, c.af); got != c.quer {
			t.Errorf("novoTom(%s, %.0f) = %s, esperado %s", c.atual, c.af, got, c.quer)
		}
	}
}

func TestDeltaTemRetornoDecrescente(t *testing.T) {
	if got := aplicarDelta(90, 10); got != 92 {
		t.Fatalf("+10 em 90 = %.1f, esperado 92", got)
	}
	if got := aplicarDelta(40, 10); got != 50 {
		t.Fatalf("+10 em 40 = %.1f, esperado 50 (sem freio no meio)", got)
	}
	if got := aplicarDelta(10, -10); got != 8 {
		t.Fatalf("-10 em 10 = %.1f, esperado 8", got)
	}
}

func TestIrisEhGMDaBiblioteca(t *testing.T) {
	s := Nova(MapaInicial(), 1)
	if err := s.Povoar(Residentes()); err != nil {
		t.Fatal(err)
	}
	iris, ok := s.Navi(IDIris)
	if !ok || !iris.GM || iris.Apelido != "Iris" || iris.Area != Biblioteca {
		t.Fatalf("Iris mal configurada: %+v", iris)
	}
	if iris.Perfil.Roleta.Dominante() != dominio.Cyber {
		t.Fatal("a GM é de elemento Cyber")
	}
	if got := s.Presentes(Biblioteca); got < 1 {
		t.Fatalf("a Biblioteca deveria ter ao menos a Iris, tem %d", got)
	}
	// A cidade com a GM continua determinística.
	a := Nova(MapaInicial(), 7)
	b := Nova(MapaInicial(), 7)
	_ = a.Povoar(Residentes())
	_ = b.Povoar(Residentes())
	fa, fb := a.Avancar(3*Dia), b.Avancar(3*Dia)
	if len(fa) == 0 || len(fa) != len(fb) {
		t.Fatalf("mesma semente deveria dar os mesmos fatos: %d x %d", len(fa), len(fb))
	}
}
