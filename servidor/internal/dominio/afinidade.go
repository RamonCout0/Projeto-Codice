package dominio

import "math"

// Tom é como o NAVI resume o que sentiu. É relato, não medição exibida.
type Tom uint8

const (
	Hostil Tom = iota
	Indiferente
	Amistoso
)

func (t Tom) String() string {
	switch t {
	case Hostil:
		return "hostil"
	case Amistoso:
		return "amistoso"
	default:
		return "indiferente"
	}
}

// ClassificarTom usa as mesmas fronteiras do app: < 35 hostil, > 65 amistoso.
func ClassificarTom(v int) Tom {
	switch {
	case v < 35:
		return Hostil
	case v > 65:
		return Amistoso
	default:
		return Indiferente
	}
}

// Constantes copiadas do nucleo.dart. Ficam juntas porque são as que mais
// mudam no ajuste, e mudar aqui sem mudar lá quebra o contrato com o app.
const (
	// distanciaEsperada é a distância média de traços medida na simulação
	// do app. É o ponto neutro: mais distante que isso, a afinidade cai.
	distanciaEsperada = 20.0
	pesoSemelhanca    = 1.2
	pesoSocial        = 0.35
)

// PrimeiraImpressao é a afinidade do PRIMEIRO encontro entre dois NAVIs.
// É a porta exata de calcularAfinidade do app, e é SIMÉTRICA: trocar a e b dá
// o mesmo número. Isso é intencional: um encontro BLE e um encontro na cidade
// precisam dar a mesma primeira impressão, e o app depende da simetria para
// os dois celulares dançarem no mesmo humor sem trocar mensagem.
//
// A assimetria (A gosta mais de B do que B de A) nasce DEPOIS, na evolução
// da relação dentro da simulação, não aqui.
func PrimeiraImpressao(meu, dele Elemento, meus, deles Tracos) int {
	v := 50.0

	// Química de elemento. O oposto no anel (distância 3) não é rivalidade:
	// é desinteresse cordial, por isso ganha um empurrão pequeno e positivo.
	switch {
	case meu == dele:
		v += 20
	case Vence(meu, dele) || Vence(dele, meu):
		v -= 18
	default:
		v += 4
	}

	// Semelhança de temperamento, centrada na distância esperada (não no
	// zero, que na prática nunca acontece).
	soma := 0
	for i := range meus {
		d := meus[i] - deles[i]
		if d < 0 {
			d = -d
		}
		soma += d
	}
	distanciaMedia := float64(soma) / float64(NumTracos)
	v += (distanciaEsperada - distanciaMedia) * pesoSemelhanca

	// Química social: sociabilidade alta dos dois aproxima, agressividade
	// afasta. São os dois traços que decidem se uma conversa começa.
	soc := float64(meus[Sociabilidade]+deles[Sociabilidade]) / 2
	agr := float64(meus[Agressividade]+deles[Agressividade]) / 2
	v += (soc-50)*pesoSocial - (agr-50)*pesoSocial

	// math.Round arredonda .5 para longe do zero, igual ao round() do Dart.
	n := int(math.Round(v))
	return min(max(n, 0), 100)
}
