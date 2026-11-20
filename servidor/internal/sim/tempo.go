package sim

import "fmt"

// Instante é o tempo SIMULADO, em segundos desde o nascimento da cidade.
//
// O núcleo nunca chama time.Now(): quem decide quanto tempo passou é quem
// chama Avancar. É isso que torna a simulação determinística (mesma semente,
// mesmos fatos) e testável (um teste roda uma semana em milissegundos).
// O TIME_SCALE entra no executável que liga o relógio real ao simulado.
type Instante int64

const (
	Segundo Instante = 1
	Minuto           = 60 * Segundo
	Hora             = 60 * Minuto
	Dia              = 24 * Hora
)

func (t Instante) String() string {
	r := t % Dia
	return fmt.Sprintf("dia %d %02d:%02d", t/Dia+1, r/Hora, (r%Hora)/Minuto)
}

func (t Instante) horas() float64 { return float64(t) / float64(Hora) }
