package dominio

import "fmt"

// Este arquivo traduz o perfil do app da dev (PerfilNavi, em Dart) para o
// perfil numérico da cidade. O app descreve o NAVI para o Gemma: um elemento
// e de 1 a 3 traços em texto. A cidade precisa de números, então a tradução
// mora aqui, num lugar só, e é pura.

// MaxTracosApp é o limite do app (PerfilNavi.maxTracos).
const MaxTracosApp = 3

// dominanteDoApp: o app tem um elemento só, não uma roleta. Para o servidor
// ele vira a fatia dominante. 60% é o limiar de "especialista" do nucleo.dart:
// o NAVI escolhido pelo dono é, por definição, bem marcado por aquele elemento.
const dominanteDoApp = 60.0

// elementoDoApp converte o nome do enum do app. Só "eletrico" difere: no
// servidor ele se chama raio (o anel do nucleo.dart).
func elementoDoApp(nome string) (Elemento, error) {
	if nome == "eletrico" {
		return Raio, nil
	}
	e, err := ElementoPorNome(nome)
	if err != nil {
		return 0, err
	}
	// "normal" não existe no app; aceitar deixaria o cliente forjar um
	// elemento que a tela de criação nunca oferece.
	if e == Normal {
		return 0, fmt.Errorf("elemento desconhecido: %q", nome)
	}
	return e, nil
}

// deslocamento de um traço do app sobre os cinco números. Partem todos de 50
// (TracosNeutros) e os deslocamentos somam, então 3 traços empurram bastante
// mas nunca saem de 0..100 (limitado depois).
type deslocamento [NumTracos]int

var tracosDoApp = map[string]deslocamento{
	//                       coragem curiosidade paciência sociabilidade agressividade
	"curiosa":     {Curiosidade: +25},
	"timida":      {Coragem: -20, Sociabilidade: -15},
	"brincalhona": {Sociabilidade: +20, Paciencia: -5},
	"carinhosa":   {Sociabilidade: +15, Agressividade: -20},
	"teimosa":     {Paciencia: -20, Agressividade: +10},
	"corajosa":    {Coragem: +25},
	"sonhadora":   {Curiosidade: +15, Coragem: -5},
	"organizada":  {Paciencia: +20},
	"dramatica":   {Sociabilidade: +10, Paciencia: -15, Agressividade: +5},
	"calma":       {Paciencia: +25, Agressividade: -15},
}

// PerfilDoApp monta o perfil da cidade a partir do que o app envia. Tudo vem
// de fora, então tudo é conferido: elemento conhecido, de 1 a 3 traços
// conhecidos e sem repetição.
func PerfilDoApp(elemento string, tracos []string) (Perfil, error) {
	el, err := elementoDoApp(elemento)
	if err != nil {
		return Perfil{}, err
	}
	if len(tracos) == 0 || len(tracos) > MaxTracosApp {
		return Perfil{}, fmt.Errorf("o NAVI precisa de 1 a %d traços, veio %d", MaxTracosApp, len(tracos))
	}

	t := TracosNeutros()
	vistos := make(map[string]bool, len(tracos))
	for _, nome := range tracos {
		d, ok := tracosDoApp[nome]
		if !ok {
			return Perfil{}, fmt.Errorf("traço desconhecido: %q", nome)
		}
		if vistos[nome] {
			return Perfil{}, fmt.Errorf("traço repetido: %q", nome)
		}
		vistos[nome] = true
		for i, v := range d {
			t[i] = min(max(t[i]+v, 0), 100)
		}
	}

	// O resto da roleta é dividido igual: 40/8 = 5% cada, acima do piso de 3%.
	var r Roleta
	resto := (100 - dominanteDoApp) / float64(NumElementos-1)
	for i := range r {
		r[i] = resto
	}
	r[el] = dominanteDoApp

	p := Perfil{Roleta: r, Tracos: t}
	return p, p.Validar()
}
