import { createServer } from 'node:http';
import { createServer as createHttpsServer } from 'node:https';
import { createHmac, randomBytes, scrypt, timingSafeEqual } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { promisify } from 'node:util';

// ------------------------------------------------------------ configuração
//
// Nada é obrigatório: `node api/servidor.mjs` já sobe a API.
//   CODICE_DADOS       pasta das contas e do segredo (padrão: api/dados)
//   CODICE_JWT_SECRET  segredo do JWT; sem ele, um é gerado e guardado
//   CODICE_TOKEN_TTL   duração do token em segundos (padrão 900)
//   CODICE_SENHA       opcional: cria/atualiza a conta de demonstração "aluno"
//   CODICE_ORIGENS     origens extras do app web liberadas no CORS (vírgula)

const pastaDados = process.env.CODICE_DADOS ??
  join(fileURLToPath(new URL('.', import.meta.url)), 'dados');
mkdirSync(pastaDados, { recursive: true });

const ttl = Number(process.env.CODICE_TOKEN_TTL ?? 900);
if (!Number.isSafeInteger(ttl) || ttl < 1 || ttl > 3600) {
  throw new Error('CODICE_TOKEN_TTL precisa ficar entre 1 e 3600 segundos.');
}

function lerSegredo() {
  const doAmbiente = process.env.CODICE_JWT_SECRET;
  if (doAmbiente) {
    if (Buffer.byteLength(doAmbiente) < 32) {
      throw new Error('CODICE_JWT_SECRET precisa ter 32 bytes ou mais.');
    }
    return doAmbiente;
  }
  // Guardado em arquivo: as sessões continuam valendo se a API reiniciar.
  const arquivo = join(pastaDados, 'segredo-jwt.txt');
  if (existsSync(arquivo)) return readFileSync(arquivo, 'utf8').trim();
  const novo = randomBytes(32).toString('hex');
  writeFileSync(arquivo, novo, { mode: 0o600 });
  return novo;
}
const segredo = lerSegredo();

// ---------------------------------------------------------------- contas
//
// Senhas nunca são guardadas: só o hash scrypt com um sal aleatório.

const arquivoContas = join(pastaDados, 'usuarios.json');
const contas = new Map(
  existsSync(arquivoContas)
    ? Object.entries(JSON.parse(readFileSync(arquivoContas, 'utf8')))
    : [],
);
const salvarContas = () =>
  writeFileSync(arquivoContas, JSON.stringify(Object.fromEntries(contas), null, 2), { mode: 0o600 });

const derivar = promisify(scrypt);
async function gerarHash(senha) {
  const sal = randomBytes(16);
  const hash = await derivar(senha, sal, 64);
  return { sal: sal.toString('base64'), hash: hash.toString('base64') };
}
async function senhaConfere(conta, senha) {
  const esperado = Buffer.from(conta.hash, 'base64');
  const hash = await derivar(senha, Buffer.from(conta.sal, 'base64'), esperado.length);
  return timingSafeEqual(hash, esperado);
}
// Comparação contra um hash qualquer quando o usuário não existe: a resposta
// leva o mesmo tempo e não entrega quais usuários existem.
const contaFalsa = await gerarHash(randomBytes(16).toString('hex'));

const formatoUsuario = /^[a-z0-9_.-]{3,32}$/;
const senhaValida = (s) => typeof s === 'string' && s.length >= 8 && s.length <= 128;

if (process.env.CODICE_SENHA) {
  // Mantém o NAVI do aluno, se ele já tiver um.
  contas.set('aluno', { ...contas.get('aluno'), ...(await gerarHash(process.env.CODICE_SENHA)) });
  salvarContas();
}

// ------------------------------------------------------------------- JWT

const agora = () => Math.floor(Date.now() / 1000);
const codificar = (valor) => Buffer.from(JSON.stringify(valor)).toString('base64url');
const assinar = (dados) => createHmac('sha256', segredo).update(dados).digest('base64url');
function iguais(a, b) {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
}
const cabecalho = codificar({ alg: 'HS256', typ: 'JWT' });
function gerarToken(usuario) {
  const dados = cabecalho + '.' + codificar({ sub: usuario, exp: agora() + ttl });
  return dados + '.' + assinar(dados);
}
/** Dono do token, ou null se ele for inválido ou estiver vencido. */
function usuarioDoToken(valor = '') {
  const partes = /^Bearer ([\w-]+)\.([\w-]+)\.([\w-]+)$/.exec(valor);
  if (!partes) return null;
  const [, header, payload, assinatura] = partes;
  if (header !== cabecalho || !iguais(assinatura, assinar(header + '.' + payload))) return null;
  try {
    const dados = JSON.parse(Buffer.from(payload, 'base64url'));
    const valido = contas.has(dados.sub) && Number.isSafeInteger(dados.exp) && dados.exp > agora();
    return valido ? dados.sub : null;
  } catch {
    return null;
  }
}

// ------------------------------------------------------------------ dados

const navis = [
  { id: 1, nome: 'Frost', descricao: 'Companheira do diário' },
  { id: 2, nome: 'Pixel', descricao: 'NAVI encontrado na cidade' },
];

// ------------------------------------------------------------ perfil do NAVI
//
// Cada conta guarda o seu NAVI: nome, elemento, traços e gostos. O app usa
// isso para montar a personalidade que o Gemma interpreta.

const ELEMENTOS = ['gelo', 'fogo', 'agua', 'terra', 'ar', 'luz', 'sombra', 'eletrico'];
const TRACOS = [
  'curiosa', 'timida', 'brincalhona', 'carinhosa', 'teimosa',
  'corajosa', 'sonhadora', 'organizada', 'dramatica', 'calma',
];
const textoLimpo = (valor, maximo) =>
  typeof valor === 'string' && valor.length <= maximo && !/[\u0000-\u001f]/.test(valor)
    ? valor.trim()
    : null;

function validarPerfil(dados) {
  const nome = textoLimpo(dados?.nome, 20);
  if (!nome) return 'Dê um nome de até 20 caracteres ao NAVI.';
  if (!ELEMENTOS.includes(dados.elemento)) return 'Escolha um elemento válido.';
  const tracos = dados.tracos;
  if (!Array.isArray(tracos) || tracos.length < 1 || tracos.length > 3 ||
      new Set(tracos).size !== tracos.length || !tracos.every((t) => TRACOS.includes(t))) {
    return 'Escolha de 1 a 3 traços de personalidade.';
  }
  const gostos = dados.gostos ?? '';
  if (textoLimpo(gostos, 140) === null) return 'Os gostos podem ter até 140 caracteres, numa linha.';
  return null;
}

// ------------------------------------------------------------------- HTTP

// O app web roda em outra porta (ex.: localhost:8090), então o navegador
// pede permissão (CORS). Só origens locais e as de CODICE_ORIGENS passam.
const origensExtras = (process.env.CODICE_ORIGENS ?? '').split(',').filter(Boolean);
const origemLocal = /^https?:\/\/(localhost|127\.0\.0\.1|\[::1\])(:\d+)?$/;
function cabecalhosCors(req) {
  const origem = req.headers?.origin;
  if (!origem || !(origemLocal.test(origem) || origensExtras.includes(origem))) return {};
  return {
    'Access-Control-Allow-Origin': origem,
    'Access-Control-Allow-Methods': 'GET, POST, PUT, OPTIONS',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type, Accept',
    'Access-Control-Max-Age': '600',
    Vary: 'Origin',
  };
}

function json(res, cors, status, dados) {
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    ...cors,
    ...(status === 401 ? { 'WWW-Authenticate': 'Bearer' } : {}),
  });
  res.end(JSON.stringify(dados));
}

class CorpoInvalido extends Error {
  constructor(status, erro) {
    super(erro);
    this.status = status;
  }
}
async function lerCorpo(req) {
  let tamanho = 0;
  const blocos = [];
  for await (const bloco of req) {
    tamanho += bloco.length;
    if (tamanho > 8192) throw new CorpoInvalido(413, 'Requisição muito grande');
    blocos.push(bloco);
  }
  try {
    return JSON.parse(Buffer.concat(blocos));
  } catch {
    throw new CorpoInvalido(400, 'JSON inválido');
  }
}

async function registrar(dados) {
  const usuario = typeof dados?.usuario === 'string' ? dados.usuario.trim().toLowerCase() : '';
  if (!formatoUsuario.test(usuario)) {
    return [400, { erro: 'Use de 3 a 32 letras, números, ponto, hífen ou sublinhado no usuário.' }];
  }
  if (!senhaValida(dados.senha)) {
    return [400, { erro: 'A senha precisa ter de 8 a 128 caracteres.' }];
  }
  if (contas.has(usuario)) return [409, { erro: 'Esse usuário já existe.' }];
  contas.set(usuario, await gerarHash(dados.senha));
  salvarContas();
  return [201, { access_token: gerarToken(usuario) }];
}

async function entrar(dados) {
  const usuario = typeof dados?.usuario === 'string' ? dados.usuario.trim().toLowerCase() : '';
  const senha = typeof dados?.senha === 'string' ? dados.senha : '';
  const conta = contas.get(usuario);
  const confere = await senhaConfere(conta ?? contaFalsa, senha);
  if (!conta || !confere) return [401, { erro: 'Credenciais inválidas' }];
  return [200, { access_token: gerarToken(usuario) }];
}

export async function atender(req, res) {
  const cors = cabecalhosCors(req);
  if (req.method === 'OPTIONS') {
    res.writeHead(204, cors);
    res.end();
    return;
  }
  const rotas = { '/auth/login': entrar, '/auth/registro': registrar };
  if (req.method === 'POST' && rotas[req.url]) {
    try {
      const [status, dados] = await rotas[req.url](await lerCorpo(req));
      json(res, cors, status, dados);
    } catch (erro) {
      if (res.headersSent || res.destroyed) return;
      if (erro instanceof CorpoInvalido) json(res, cors, erro.status, { erro: erro.message });
      else json(res, cors, 500, { erro: 'Erro interno' });
    }
    return;
  }
  if (req.url === '/perfil' && (req.method === 'GET' || req.method === 'PUT')) {
    const usuario = usuarioDoToken(req.headers?.authorization);
    if (!usuario) {
      json(res, cors, 401, { erro: 'Sessão inválida ou expirada' });
      return;
    }
    const conta = contas.get(usuario);
    if (req.method === 'GET') {
      if (!conta.navi) json(res, cors, 404, { erro: 'Essa conta ainda não tem NAVI.', usuario });
      else json(res, cors, 200, { usuario, navi: conta.navi });
      return;
    }
    try {
      const dados = await lerCorpo(req);
      const erro = validarPerfil(dados);
      if (erro) {
        json(res, cors, 400, { erro });
        return;
      }
      conta.navi = {
        nome: dados.nome.trim(),
        elemento: dados.elemento,
        tracos: dados.tracos,
        gostos: (dados.gostos ?? '').trim(),
      };
      salvarContas();
      json(res, cors, 200, { usuario, navi: conta.navi });
    } catch (erro) {
      if (res.headersSent || res.destroyed) return;
      if (erro instanceof CorpoInvalido) json(res, cors, erro.status, { erro: erro.message });
      else json(res, cors, 500, { erro: 'Erro interno' });
    }
    return;
  }
  if (req.method === 'GET' && req.url === '/navis') {
    if (!usuarioDoToken(req.headers?.authorization)) {
      json(res, cors, 401, { erro: 'Sessão inválida ou expirada' });
      return;
    }
    json(res, cors, 200, navis);
    return;
  }
  json(res, cors, 404, { erro: 'Rota não encontrada' });
}

function iniciarServidor() {
  const { CODICE_TLS_CERT: certificado, CODICE_TLS_KEY: chave } = process.env;
  if (Boolean(certificado) !== Boolean(chave)) {
    throw new Error('Informe o certificado e a chave TLS juntos.');
  }

  const servidor = certificado
    ? createHttpsServer({
        cert: readFileSync(certificado),
        key: readFileSync(chave),
      }, atender)
    : createServer(atender);

  const host = process.env.CODICE_HOST ?? '127.0.0.1';
  if (!certificado && host !== '127.0.0.1' && host !== '::1') {
    throw new Error('Sem TLS, a API só pode ouvir no endereço local.');
  }
  servidor.listen(Number(process.env.PORT ?? 8080), host, () => {
    const { port } = servidor.address();
    console.log(`API do Códice em ${certificado ? 'https' : 'http'}://localhost:${port}`);
    console.log(`${contas.size} conta(s) em ${arquivoContas}`);
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  iniciarServidor();
}
