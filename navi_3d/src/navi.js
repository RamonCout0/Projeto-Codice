// Visualizador VRM da NAVI. Roda dentro de uma WebView do app Flutter.
//
// Flutter -> JS:  window.navi.humor('feliz') | falar(true) | acenar() | pausar(true)
// JS -> Flutter:  canal "Navi" com JSON {tipo: 'progresso'|'pronto'|'retrato'|'toque'|'erro'}
//
// Gerado com `npm run build` em navi_3d/ -> assets/navi_3d/navi.js

import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { VRMLoaderPlugin, VRMUtils } from '@pixiv/three-vrm';
import { VRMAnimationLoaderPlugin, createVRMAnimationClip } from '@pixiv/three-vrm-animation';
import { criarAnimador } from './animacoes.js';

const params = new URLSearchParams(location.search);
const enquadramento = params.get('enquadramento') ?? 'corpo'; // corpo | busto
const querRetrato = params.get('retrato') === '1';

function avisarFlutter(mensagem) {
  window.Navi?.postMessage(JSON.stringify(mensagem));
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
  const altura = cabeca.y + 0.12;
  if (modo === 'rosto') {
    camera.position.set(0, cabeca.y + 0.03, 0.75);
    camera.lookAt(0, cabeca.y + 0.02, 0);
  } else if (modo === 'busto') {
    camera.position.set(0, cabeca.y - 0.02, 1.25);
    camera.lookAt(0, cabeca.y - 0.12, 0);
  } else {
    // Distância para caber o corpo inteiro na vertical.
    const distancia = (altura * 0.62) / Math.tan(THREE.MathUtils.degToRad(camera.fov / 2));
    camera.position.set(0, altura * 0.55, distancia);
    camera.lookAt(0, altura * 0.5, 0);
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

/** Carrega as animações .vrma importadas no app ({parada, aceno, comemorar}). */
async function carregarClipes(vrm) {
  const lista = await fetch('/animacoes.json').then((r) => r.json()).catch(() => ({}));
  const clipes = {};
  for (const [nome, url] of Object.entries(lista)) {
    try {
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
  const gltf = await loader.loadAsync('/modelo.vrm', (p) =>
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
