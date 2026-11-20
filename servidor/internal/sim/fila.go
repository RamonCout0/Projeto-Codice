package sim

// A fila de eventos é o coração do motor: em vez de "atualizar todo mundo a
// cada tick", cada NAVI agenda o próximo momento em que precisa pensar.
// Com 10 mil NAVIs parados num café, nada roda até alguém ter algo a fazer.

type tipoEvento uint8

const (
	evDecidir     tipoEvento = iota // o NAVI escolhe a próxima ação
	evChegar                        // termina uma caminhada
	evFimConversa                   // termina uma conversa (evento de quem puxou)
)

type evento struct {
	quando Instante
	// seq desempata eventos no mesmo instante pela ordem de agendamento.
	// Sem ele, o heap poderia sair em ordens diferentes e o determinismo iria
	// embora sem nenhum erro aparente.
	seq   uint64
	tipo  tipoEvento
	navi  NaviID
	outro NaviID
	// gen é a "geração" do NAVI quando o evento foi agendado. Se o plano dele
	// mudar no meio (alguém puxou conversa enquanto ele descansava), a geração
	// sobe e o evento antigo é ignorado ao sair da fila. É mais barato que
	// procurar e remover o evento do heap.
	gen uint64
}

// fila implementa container/heap.Interface: um min-heap por (quando, seq).
type fila []evento

func (f fila) Len() int { return len(f) }
func (f fila) Less(i, j int) bool {
	if f[i].quando != f[j].quando {
		return f[i].quando < f[j].quando
	}
	return f[i].seq < f[j].seq
}
func (f fila) Swap(i, j int) { f[i], f[j] = f[j], f[i] }
func (f *fila) Push(x any)   { *f = append(*f, x.(evento)) }
func (f *fila) Pop() any {
	velha := *f
	n := len(velha)
	e := velha[n-1]
	*f = velha[:n-1]
	return e
}
