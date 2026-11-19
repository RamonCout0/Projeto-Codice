// Converte uma animação do Mixamo (.fbx) para o esqueleto do VRM.
//
// O Mixamo usa o rig "mixamorig" com poses de descanso próprias. Para cada
// osso: tira a rotação de descanso do Mixamo, leva para o espaço do osso
// "normalizado" do VRM (descanso = identidade) e ajusta a altura do quadril
// à altura do modelo. Baseado no exemplo oficial do three-vrm.
//
// No Mixamo: escolha a animação, Download > Format "FBX Binary (.fbx)",
// Skin "Without Skin". Para andar/correr, marque "In Place".

import * as THREE from 'three';
import { FBXLoader } from 'three/examples/jsm/loaders/FBXLoader.js';

/** Osso do Mixamo (sem o prefixo "mixamorig") -> osso humanoide do VRM. */
const OSSOS = {
  Hips: 'hips',
  Spine: 'spine',
  Spine1: 'chest',
  Spine2: 'upperChest',
  Neck: 'neck',
  Head: 'head',
  LeftShoulder: 'leftShoulder',
  LeftArm: 'leftUpperArm',
  LeftForeArm: 'leftLowerArm',
  LeftHand: 'leftHand',
  LeftHandThumb1: 'leftThumbMetacarpal',
  LeftHandThumb2: 'leftThumbProximal',
  LeftHandThumb3: 'leftThumbDistal',
  LeftHandIndex1: 'leftIndexProximal',
  LeftHandIndex2: 'leftIndexIntermediate',
  LeftHandIndex3: 'leftIndexDistal',
  LeftHandMiddle1: 'leftMiddleProximal',
  LeftHandMiddle2: 'leftMiddleIntermediate',
  LeftHandMiddle3: 'leftMiddleDistal',
  LeftHandRing1: 'leftRingProximal',
  LeftHandRing2: 'leftRingIntermediate',
  LeftHandRing3: 'leftRingDistal',
  LeftHandPinky1: 'leftLittleProximal',
  LeftHandPinky2: 'leftLittleIntermediate',
  LeftHandPinky3: 'leftLittleDistal',
  RightShoulder: 'rightShoulder',
  RightArm: 'rightUpperArm',
  RightForeArm: 'rightLowerArm',
  RightHand: 'rightHand',
  RightHandThumb1: 'rightThumbMetacarpal',
  RightHandThumb2: 'rightThumbProximal',
  RightHandThumb3: 'rightThumbDistal',
  RightHandIndex1: 'rightIndexProximal',
  RightHandIndex2: 'rightIndexIntermediate',
  RightHandIndex3: 'rightIndexDistal',
  RightHandMiddle1: 'rightMiddleProximal',
  RightHandMiddle2: 'rightMiddleIntermediate',
  RightHandMiddle3: 'rightMiddleDistal',
  RightHandRing1: 'rightRingProximal',
  RightHandRing2: 'rightRingIntermediate',
  RightHandRing3: 'rightRingDistal',
  RightHandPinky1: 'rightLittleProximal',
  RightHandPinky2: 'rightLittleIntermediate',
  RightHandPinky3: 'rightLittleDistal',
  LeftUpLeg: 'leftUpperLeg',
  LeftLeg: 'leftLowerLeg',
  LeftFoot: 'leftFoot',
  LeftToeBase: 'leftToes',
  RightUpLeg: 'rightUpperLeg',
  RightLeg: 'rightLowerLeg',
  RightFoot: 'rightFoot',
  RightToeBase: 'rightToes',
};

// Alguns downloads vêm como "mixamorig1:Hips"; o FBXLoader tira o ":".
const PREFIXO = /^mixamorig\d*:?/;

const loader = new FBXLoader();

/**
 * @param url  endereço do .fbx exportado do Mixamo
 * @param vrm  modelo VRM já carregado e na pose de descanso
 * @returns    THREE.AnimationClip pronto para o AnimationMixer do vrm.scene
 */
export async function carregarAnimacaoMixamo(url, vrm) {
  const fbx = await loader.loadAsync(url);
  const clipe =
    THREE.AnimationClip.findByName(fbx.animations, 'mixamo.com') ?? fbx.animations[0];
  if (!clipe) throw new Error('o .fbx não tem animação');

  // Nome do nó no FBX para cada osso do Mixamo, seja qual for o prefixo.
  const nos = {};
  fbx.traverse((no) => {
    if (PREFIXO.test(no.name)) nos[no.name.replace(PREFIXO, '')] = no;
  });
  if (!nos.Hips) throw new Error('esse .fbx não usa o esqueleto do Mixamo');

  fbx.updateMatrixWorld(true);
  vrm.scene.updateMatrixWorld(true);
  const v = new THREE.Vector3();
  const alturaVrm = Math.abs(
    vrm.humanoid.getNormalizedBoneNode('hips').getWorldPosition(v).y -
      vrm.scene.getWorldPosition(v).y,
  );
  const escala = alturaVrm / nos.Hips.position.y;
  const vrm0 = vrm.meta?.metaVersion === '0'; // VRM 0.x olha para o lado oposto

  const descansoInverso = new THREE.Quaternion();
  const descansoPai = new THREE.Quaternion();
  const q = new THREE.Quaternion();
  const trilhas = [];

  for (const trilha of clipe.tracks) {
    const [nomeNo, propriedade] = trilha.name.split('.');
    const nomeMixamo = nomeNo.replace(PREFIXO, '');
    const alvo = vrm.humanoid.getNormalizedBoneNode(OSSOS[nomeMixamo])?.name;
    const no = nos[nomeMixamo];
    if (!alvo || !no) continue;

    if (trilha instanceof THREE.QuaternionKeyframeTrack) {
      no.getWorldQuaternion(descansoInverso).invert();
      no.parent.getWorldQuaternion(descansoPai);
      const valores = trilha.values.slice();
      for (let i = 0; i < valores.length; i += 4) {
        q.fromArray(valores, i).premultiply(descansoPai).multiply(descansoInverso);
        q.toArray(valores, i);
      }
      if (vrm0) for (let i = 0; i < valores.length; i += 2) valores[i] = -valores[i];
      trilhas.push(new THREE.QuaternionKeyframeTrack(`${alvo}.${propriedade}`, trilha.times, valores));
    } else if (trilha instanceof THREE.VectorKeyframeTrack && nomeMixamo === 'Hips') {
      // Só o quadril se desloca. Trava X/Z no primeiro quadro para a NAVI
      // não sair do enquadramento (equivale ao "In Place" do Mixamo).
      const valores = trilha.values.slice();
      const [x0, , z0] = valores;
      for (let i = 0; i < valores.length; i += 3) {
        valores[i] = x0;
        valores[i + 2] = z0;
      }
      const ajustados = valores.map((n, i) => (vrm0 && i % 3 !== 1 ? -n : n) * escala);
      trilhas.push(new THREE.VectorKeyframeTrack(`${alvo}.${propriedade}`, trilha.times, ajustados));
    }
  }
  return new THREE.AnimationClip('mixamo', clipe.duration, trilhas);
}
