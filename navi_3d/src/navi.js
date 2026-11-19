// Visualizador VRM da NAVI. Roda dentro de uma WebView do app Flutter.
//
// Flutter -> JS:  window.navi.humor('feliz') | falar(true) | acenar() | pausar(true)
//                 (na web chega por postMessage: {naviComando, arg})
// JS -> Flutter:  JSON {tipo: 'progresso'|'pronto'|'retrato'|'toque'|'erro'}
//                 pelo canal "Navi" da WebView, ou postMessage para o app na web
//
// Arquivos: no celular vêm do servidor local (/modelo.vrm, /animacoes.json).
// Na web vêm na URL: ?modelo=<url>&animacoes={"aceno":{"url","formato"}}.
//
// Gerado com `npm run build` em navi_3d/ -> assets/navi_3d/navi.js

import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { VRMLoaderPlugin, VRMUtils } from '@pixiv/three-vrm';
import { VRMAnimationLoaderPlugin, createVRMAnimationClip } from '@pixiv/three-vrm-animation';
import { criarAnimador } from './animacoes.js';
import { carregarAnimacaoMixamo } from './mixamo.js';

const params = new URLSearchParams(location.search);
const enquadramento = params.get('enquadramento') ?? 'corpo'; // corpo | busto
const querRetrato = params.get('retrato') === '1';
const urlModelo = params.get('modelo') ?? '/modelo.vrm';
const listaAnimacoes = params.get('animacoes');

const canal = params.get('canal'); // só na web: identifica este iframe

function avisarFlutter(mensagem) {
  const texto = JSON.stringify(canal ? { ...mensagem, canal } : mensagem);
  if (window.Navi) window.Navi.postMessage(texto); // WebView
  else if (window.parent !== window) window.parent.postMessage(texto, location.origin); // iframe
}

// ------------------------------------------------------------------ cena

const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.outputColorSpace = THREE.SRGBColorSpace;
document.body.appendChild(renderer.domElement);

const cena = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(30, window.innerWidth / window.innerHeight, 0.1, 20);

const luz = new THREE.DirectionalLight(0xffffff, Math.PI);
luz.position.set(1, 1.5, 2).normalize();
cena.add(luz, new THREE.AmbientLight(0xffffff, 0.6));

/** Enquadra a câmera a partir da altura real da cabeça do modelo. */
function enquadrar(vrm, modo) {
  const cabeca = new THREE.Vector3();
  vrm.humanoid.getNormalizedBoneNode('head').getWorldPosition(cabeca);
  // O osso da cabeça fica na base do crânio: +0.2 cobre cabelo e enfeites.
  const altura = cabeca.y + 0.2;
  const tangente = Math.tan(THREE.MathUtils.degToRad(camera.fov / 2));
  if (modo === 'rosto') {
    camera.position.set(0, cabeca.y + 0.03, 0.75);
    camera.lookAt(0, cabeca.y + 0.02, 0);
  } else if (modo === 'busto') {
    // Da cintura até um respiro acima do cabelo, sem cortar a cabeça.
    const topo = cabeca.y + 0.26;
    const base = cabeca.y - 0.5;
    const centro = (topo + base) / 2;
    camera.position.set(0, centro, (topo - base) / 2 / tangente);
    camera.lookAt(0, centro, 0);
  } else {
    // Corpo inteiro, com os pés (y = 0) quase na borda de baixo: sem isso
    // sobra espaço embaixo e ela parece flutuar.
    const metade = altura * 0.53;
    const centro = metade - altura * 0.02;
    camera.position.set(0, centro, metade / tangente);
    camera.lookAt(0, centro, 0);
  }
}

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

// -------------------------------------------------------------- retrato

/** Foto do rosto em PNG (base64), usada nas fotos pequenas do app. */
function tirarRetrato(vrm) {
  const tamanhoOriginal = renderer.getSize(new THREE.Vector2());
  const aspectoOriginal = camera.aspect;
  const lado = 256 / renderer.getPixelRatio();

  renderer.setSize(lado, lado, false);
  camera.aspect = 1;
  camera.updateProjectionMatrix();
  enquadrar(vrm, 'rosto');
  renderer.render(cena, camera);
  const png = renderer.domElement.toDataURL('image/png');

  renderer.setSize(tamanhoOriginal.x, tamanhoOriginal.y);
  camera.aspect = aspectoOriginal;
  camera.updateProjectionMatrix();
  enquadrar(vrm, enquadramento);
  return png.substring(png.indexOf(',') + 1);
}

// ------------------------------------------------------------ carregar

let animador = null;
let pausado = false;
const relogio = new THREE.Clock();

const loader = new GLTFLoader();
loader.register((parser) => new VRMLoaderPlugin(parser));
loader.register((parser) => new VRMAnimationLoaderPlugin(parser));

/**
 * Carrega as animações importadas no app ({parada, aceno, comemorar}):
 * .vrma (VRM Animation) ou .fbx exportado do Mixamo.
 */
async function carregarClipes(vrm) {
  const lista = listaAnimacoes
    ? JSON.parse(listaAnimacoes)
    : await fetch('/animacoes.json').then((r) => r.json()).catch(() => ({}));
  const clipes = {};
  for (const [nome, item] of Object.entries(lista)) {
    // "/anim/aceno.fbx" (celular) ou {url: "blob:...", formato: "fbx"} (web)
    const url = typeof item === 'string' ? item : item.url;
    const formato = typeof item === 'string' ? url.split('.').pop() : item.formato;
    try {
      if (formato === 'fbx') {
        clipes[nome] = await carregarAnimacaoMixamo(url, vrm);
        continue;
      }
      const gltf = await loader.loadAsync(url);
      const animacao = gltf.userData.vrmAnimations?.[0];
      if (animacao) clipes[nome] = createVRMAnimationClip(animacao, vrm);
    } catch (erro) {
      avisarFlutter({ tipo: 'erro', mensagem: `animação "${nome}": ${erro?.message ?? erro}` });
    }
  }
  return clipes;
}

async function iniciar() {
  const gltf = await loader.loadAsync(urlModelo, (p) =>
    p.total && avisarFlutter({ tipo: 'progresso', valor: p.loaded / p.total }),
  );
  const vrm = gltf.userData.vrm;
  if (!vrm) throw new Error('o arquivo não é um VRM');

  VRMUtils.removeUnnecessaryVertices(gltf.scene);
  VRMUtils.combineSkeletons(gltf.scene);
  VRMUtils.rotateVRM0(vrm); // modelos VRM 0.x olham para o outro lado
  vrm.scene.traverse((o) => (o.frustumCulled = false));
  cena.add(vrm.scene);

  vrm.lookAt.target = camera;
  animador = criarAnimador(vrm, await carregarClipes(vrm));
  animador.atualizar(0);
  vrm.update(0);
  enquadrar(vrm, enquadramento);

  if (querRetrato) avisarFlutter({ tipo: 'retrato', png: tirarRetrato(vrm) });
  avisarFlutter({ tipo: 'pronto', animacoesProntas: animador.temAnimacoesProntas });
  relogio.start();
  renderer.setAnimationLoop(() => {
    if (pausado) return;
    const delta = Math.min(relogio.getDelta(), 0.1);
    animador.atualizar(delta);
    vrm.update(delta); // expressões, olhar e física do cabelo/roupa
    renderer.render(cena, camera);
  });
}

iniciar().catch((erro) => avisarFlutter({ tipo: 'erro', mensagem: String(erro?.message ?? erro) }));

renderer.domElement.addEventListener('click', () => {
  animador?.acenar();
  avisarFlutter({ tipo: 'toque' });
});

// ------------------------------------------------- API para o Flutter

window.navi = {
  humor: (nome) => animador?.humor(nome),
  falar: (sim) => animador?.falar(sim),
  acenar: () => animador?.acenar(),
  pausar: (sim) => {
    pausado = sim;
    if (!sim) relogio.getDelta(); // descarta o tempo parado
  },
};

// Na web os comandos do Flutter chegam do app que abriu o iframe.
window.addEventListener('message', (e) => {
  if (e.source !== window.parent || e.origin !== location.origin) return;
  let dados;
  try {
    dados = JSON.parse(e.data);
  } catch {
    return;
  }
  const comando = window.navi[dados?.naviComando];
  if (typeof comando === 'function') comando(dados.arg);
});
