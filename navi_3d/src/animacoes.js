// Animação da NAVI em camadas, recalculadas a cada quadro:
//   1. corpo: animações prontas (.vrma) quando importadas; sem elas, uma
//      animação simples calculada aqui mesmo (respirar, balançar, acenar);
//   2. cabeça: inclinação do humor, somada por cima do corpo;
//   3. rosto: expressão do humor, piscar e boca falando.

import * as THREE from 'three';

/** Expressão (preset do VRM) e inclinação da cabeça para cada humor do app. */
const HUMORES = {
  esperando: { expressoes: {} },
  lendo: { expressoes: { relaxed: 0.25 }, cabeca: 0.12 },
  curiosa: { expressoes: { surprised: 0.35, happy: 0.2 }, cabeca: -0.05, inclinar: 0.18 },
  feliz: { expressoes: { happy: 0.85 }, cabeca: -0.06 },
  confusa: { expressoes: { sad: 0.3, surprised: 0.2 }, inclinar: -0.22 },
  pensando: { expressoes: { relaxed: 0.5 }, cabeca: -0.12, inclinar: 0.08 },
};
const NOMES_EXPRESSAO = ['happy', 'sad', 'relaxed', 'surprised', 'angry'];
const VOGAIS = ['aa', 'ih', 'ou', 'ee', 'oh'];
const ACENO_PROCEDURAL = 2.2; // segundos
const INTERVALO_ACENO = 8; // segundos sem acenar de novo, mesmo com toques

const suavizar = (atual, alvo, velocidade, delta) =>
  atual + (alvo - atual) * (1 - Math.exp(-velocidade * delta));

/**
 * @param vrm     modelo carregado
 * @param clipes  { parada?, aceno?, comemorar? } — THREE.AnimationClip de .vrma
 */
export function criarAnimador(vrm, clipes = {}) {
  const osso = (nome) => vrm.humanoid.getNormalizedBoneNode(nome);
  const expressoes = vrm.expressionManager;
  const mixer = new THREE.AnimationMixer(vrm.scene);
  const acoes = {};
  for (const [nome, clipe] of Object.entries(clipes)) {
    if (!clipe) continue;
    const acao = mixer.clipAction(clipe);
    if (nome !== 'parada') {
      acao.setLoop(THREE.LoopOnce, 1);
      acao.clampWhenFinished = false;
    }
    acoes[nome] = acao;
  }
  acoes.parada?.play();

  let t = 0;
  let humorAtual = HUMORES.esperando;
  const pesos = Object.fromEntries(NOMES_EXPRESSAO.map((n) => [n, 0]));
  let cabecaX = 0;
  let cabecaZ = 0;
  let proximaPiscada = 2;
  let piscando = 0;
  let falando = false;
  let abertura = 0;
  let vogal = 'aa';
  let proximaSilaba = 0;
  let acenoProcedural = -1;
  let gestoAtual = null;
  let proximoAceno = 0;

  // Volta para a "parada" quando um gesto pronto termina.
  mixer.addEventListener('finished', (e) => {
    if (e.action !== gestoAtual) return;
    gestoAtual = null;
    acoes.parada?.reset().fadeIn(0.4).play();
    e.action.fadeOut(0.4);
  });

  /** Toca um gesto pronto (.vrma). Retorna false se ele não foi importado. */
  function tocarGesto(nome) {
    const acao = acoes[nome];
    if (!acao) return false;
    if (gestoAtual === acao) return true;
    gestoAtual?.fadeOut(0.3);
    acao.reset().fadeIn(0.3).play();
    acoes.parada?.fadeOut(0.3);
    gestoAtual = acao;
    return true;
  }

  // ------------------------------------------------ 1. corpo procedural

  function corpoProcedural(delta) {
    const respiracao = Math.sin(t * 2.2);
    osso('spine').rotation.set(respiracao * 0.015, 0, -Math.sin(t * 0.8) * 0.025);
    osso('chest')?.rotation.set(respiracao * 0.02, 0, 0);
    osso('hips').rotation.z = Math.sin(t * 0.8) * 0.02;
    osso('hips').position.y += respiracao * 0.003;

    // Sai da pose em T: braços descansam ao lado do corpo.
    const balanco = Math.sin(t * 1.1) * 0.03;
    osso('leftUpperArm').rotation.set(0, 0, -1.2 + balanco);
    osso('rightUpperArm').rotation.set(0, 0, 1.2 - balanco);
    osso('leftLowerArm').rotation.set(0, 0, -0.15);
    osso('rightLowerArm').rotation.set(0, 0, 0.15);

    if (acenoProcedural < 0) return;
    acenoProcedural += delta;
    const fase = acenoProcedural / ACENO_PROCEDURAL;
    if (fase >= 1) return void (acenoProcedural = -1);
    const subida = Math.min(fase * 5, 1, (1 - fase) * 5);
    osso('rightUpperArm').rotation.set(0, 0, THREE.MathUtils.lerp(1.2, -1.1, subida));
    osso('rightLowerArm').rotation.set(0, 0, -subida * (0.4 + Math.sin(acenoProcedural * 14) * 0.35));
  }

  // ----------------------------------------------------- 2. cabeça

  function cabeca(delta) {
    cabecaX = suavizar(cabecaX, humorAtual.cabeca ?? 0, 4, delta);
    cabecaZ = suavizar(cabecaZ, humorAtual.inclinar ?? 0, 4, delta);
    const concordar = falando ? Math.sin(t * 9) * 0.03 : 0;
    const pescoco = osso('neck');
    pescoco.rotation.x += cabecaX + concordar;
    pescoco.rotation.z += cabecaZ;
  }

  // ------------------------------------------------------- 3. rosto

  function rosto(delta) {
    for (const nome of NOMES_EXPRESSAO) {
      pesos[nome] = suavizar(pesos[nome], humorAtual.expressoes[nome] ?? 0, 6, delta);
      expressoes?.setValue(nome, pesos[nome]);
    }

    proximaPiscada -= delta;
    if (proximaPiscada <= 0) {
      piscando = 0.15;
      proximaPiscada = 2 + Math.random() * 4;
    }
    piscando = Math.max(0, piscando - delta);
    // Não pisca por cima do "feliz", que já fecha os olhos nos modelos VRoid.
    const piscar = piscando > 0 ? Math.sin((piscando / 0.15) * Math.PI) : 0;
    expressoes?.setValue('blink', piscar * (1 - pesos.happy));

    if (falando && t >= proximaSilaba) {
      vogal = VOGAIS[Math.floor(Math.random() * VOGAIS.length)];
      proximaSilaba = t + 0.09 + Math.random() * 0.1;
    }
    const alvoBoca = falando ? 0.35 + Math.abs(Math.sin(t * 16)) * 0.5 : 0;
    abertura = suavizar(abertura, alvoBoca, 18, delta);
    for (const v of VOGAIS) expressoes?.setValue(v, v === vogal ? abertura : 0);
  }

  return {
    temAnimacoesProntas: Object.keys(acoes).length > 0,
    atualizar(delta) {
      t += delta;
      // Zera os ossos a cada quadro: assim as camadas se somam sem acumular.
      vrm.humanoid.resetNormalizedPose();
      if (acoes.parada || gestoAtual) mixer.update(delta);
      else corpoProcedural(delta);
      cabeca(delta);
      rosto(delta);
    },
    humor(nome) {
      const anterior = humorAtual;
      humorAtual = HUMORES[nome] ?? HUMORES.esperando;
      if (humorAtual === HUMORES.feliz && anterior !== humorAtual) tocarGesto('comemorar');
    },
    falar(sim) {
      falando = sim;
    },
    acenar() {
      // Vários toques seguidos não viram vários acenos.
      if (t < proximoAceno) return;
      proximoAceno = t + INTERVALO_ACENO;
      if (!tocarGesto('aceno') && acenoProcedural < 0 && !acoes.parada) acenoProcedural = 0;
    },
  };
}
