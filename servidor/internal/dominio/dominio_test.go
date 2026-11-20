package dominio

import (
	"encoding/json"
	"testing"
)

// Os valores esperados foram calculados à mão com a fórmula do nucleo.dart.
// Se um destes quebrar, o servidor e o app discordam sobre a afinidade.
func TestPrimeiraImpressaoReferencia(t *testing.T) {
	neutro := TracosNeutros()
	casos := []struct {
		nome        string
		meu, dele   Elemento
		meus, deles Tracos
		esperado    int
		tomEsperado Tom
	}{
		// mesmo elemento +20, distância 0 → +24
		{"iguais e neutros", Gelo, Gelo, neutro, neutro, 94, Amistoso},
		// água vence fogo → −18, +24
		{"anel: água vence fogo", Agua, Fogo, neutro, neutro, 56, Indiferente},
		// água e ar são opostos (distância 3) → +4, +24
		{"opostos no anel", Agua, Ar, neutro, neutro, 78, Amistoso},
		// normal fica fora do anel → +4
		{"normal é neutro", Normal, Fogo, neutro, neutro, 78, Amistoso},
		// fogo vence gelo −18; dist 28 → −9,6; soc 80 → +10,5; agr 20 → +10,5 = 43,4
		{"traços mistos", Fogo, Gelo,
			Tracos{80, 20, 50, 90, 10}, Tracos{30, 60, 40, 70, 30}, 43, Indiferente},
		// raio vence água −18; dist 60 → −48; soc 0 → −17,5; agr 100 → −17,5 → −51 → 0
		{"limite inferior", Raio, Agua,
			Tracos{0, 0, 0, 0, 100}, Tracos{100, 100, 100, 0, 100}, 0, Hostil},
	}
	for _, c := range casos {
		t.Run(c.nome, func(t *testing.T) {
			got := PrimeiraImpressao(c.meu, c.dele, c.meus, c.deles)
			if got != c.esperado {
				t.Fatalf("PrimeiraImpressao = %d, esperado %d", got, c.esperado)
			}
			if tom := ClassificarTom(got); tom != c.tomEsperado {
				t.Fatalf("tom = %s, esperado %s", tom, c.tomEsperado)
			}
			// Simetria: é dela que depende a dança sincronizada no app.
			if inv := PrimeiraImpressao(c.dele, c.meu, c.deles, c.meus); inv != got {
				t.Fatalf("não é simétrica: %d vs %d", got, inv)
			}
		})
	}
}

func TestAnelCadaUmVenceDois(t *testing.T) {
	for _, a := range anel {
		vitorias := 0
		for _, b := range anel {
			if Vence(a, b) {
				vitorias++
				if Vence(b, a) {
					t.Fatalf("%s e %s se vencem mutuamente", a, b)
				}
			}
		}
		if vitorias != alcanceAnel {
			t.Fatalf("%s vence %d, esperado %d", a, vitorias, alcanceAnel)
		}
	}
	if Vence(Normal, Fogo) || Vence(Fogo, Normal) {
		t.Fatal("Normal deveria ser neutro")
	}
}

func TestRoletaDaFrost(t *testing.T) {
	// Roleta real da Frost, gravada no app.
	frost := Roleta{Agua: 17, Fogo: 8, Gelo: 53, Ar: 3, Terra: 3, Raio: 13, Normal: 3}
	if err := frost.Validar(); err != nil {
		t.Fatal(err)
	}
	if d := frost.Dominante(); d != Gelo {
		t.Fatalf("dominante = %s, esperado Gelo", d)
	}
	if frost.Especialista() {
		t.Fatal("53% não é especialista (limite 60%)")
	}
}

func TestValidacoesRecusamLixo(t *testing.T) {
	if err := (Tracos{50, 50, 101, 50, 50}).Validar(); err == nil {
		t.Fatal("traço 101 deveria ser recusado")
	}
	if err := (Roleta{Agua: 50}).Validar(); err == nil {
		t.Fatal("roleta somando 50 deveria ser recusada")
	}
	if _, err := ElementoPorNome("plasma"); err == nil {
		t.Fatal("elemento desconhecido deveria dar erro")
	}
}

func TestElementoJSONUsaNomeDoDart(t *testing.T) {
	b, err := json.Marshal(map[string]Elemento{"e": Agua})
	if err != nil {
		t.Fatal(err)
	}
	if string(b) != `{"e":"agua"}` {
		t.Fatalf("json = %s", b)
	}
	var volta map[string]Elemento
	if err := json.Unmarshal([]byte(`{"e":"raio"}`), &volta); err != nil || volta["e"] != Raio {
		t.Fatalf("volta = %v, err = %v", volta, err)
	}
}

func TestPerfilDoApp(t *testing.T) {
	p, err := PerfilDoApp("eletrico", []string{"curiosa", "calma"})
	if err != nil {
		t.Fatal(err)
	}
	if p.Roleta.Dominante() != Raio {
		t.Fatalf("eletrico deveria virar raio, veio %s", p.Roleta.Dominante())
	}
	if !p.Roleta.Especialista() {
		t.Fatal("o elemento do app deveria ser dominante (>= 60%)")
	}
	// curiosa +25 em curiosidade; calma +25 paciência e -15 agressividade.
	esperado := Tracos{50, 75, 75, 50, 35}
	if p.Tracos != esperado {
		t.Fatalf("traços = %v, esperado %v", p.Tracos, esperado)
	}

	if l, err := PerfilDoApp("luz", []string{"corajosa"}); err != nil || l.Roleta.Dominante() != Luz {
		t.Fatalf("luz deveria ser aceita: %v", err)
	}
}

func TestPerfilDoAppRecusaEntradaInvalida(t *testing.T) {
	casos := []struct {
		nome     string
		elemento string
		tracos   []string
	}{
		{"elemento desconhecido", "plasma", []string{"calma"}},
		{"normal não existe no app", "normal", []string{"calma"}},
		{"sem traços", "gelo", nil},
		{"traços demais", "gelo", []string{"calma", "curiosa", "timida", "corajosa"}},
		{"traço desconhecido", "gelo", []string{"valente"}},
		{"traço repetido", "gelo", []string{"calma", "calma"}},
	}
	for _, c := range casos {
		if _, err := PerfilDoApp(c.elemento, c.tracos); err == nil {
			t.Errorf("%s: esperava erro", c.nome)
		}
	}
}

func TestLuzESombraSaoNeutras(t *testing.T) {
	if Vence(Luz, Fogo) || Vence(Fogo, Sombra) || Vence(Luz, Sombra) {
		t.Fatal("Luz e Sombra ficam fora do anel e não vencem ninguém")
	}
	if Luz.Nome() != "luz" || Sombra.Nome() != "sombra" {
		t.Fatal("nomes de Luz/Sombra devem bater com o enum do app")
	}
}

func TestCyberEhReservadoAoGM(t *testing.T) {
	if _, err := PerfilDoApp("cyber", []string{"calma"}); err == nil {
		t.Fatal("um cliente comum não pode escolher o elemento dos GMs")
	}
	p, err := PerfilGM(Tracos{60, 85, 90, 70, 5})
	if err != nil {
		t.Fatal(err)
	}
	if p.Roleta.Dominante() != Cyber || !p.Roleta.Especialista() {
		t.Fatalf("GM deveria ser Cyber especialista, veio %s", p.Roleta.Dominante())
	}
	if Vence(Cyber, Fogo) || Vence(Agua, Cyber) {
		t.Fatal("Cyber fica fora do anel")
	}
}
