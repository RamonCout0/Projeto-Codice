import { createServer } from 'node:http';
import { createServer as createHttpsServer } from 'node:https';
import { createHmac, timingSafeEqual } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const { CODICE_SENHA: senha, CODICE_JWT_SECRET: segredo } = process.env;
const ttl = Number(process.env.CODICE_TOKEN_TTL ?? 900);
if (!senha || !segredo || Buffer.byteLength(segredo) < 32 ||
    !Number.isSafeInteger(ttl) || ttl < 1 || ttl > 3600) {
  throw new Error('Configure CODICE_SENHA, CODICE_JWT_SECRET (32 bytes ou mais) e um TTL válido.');
}

const usuario = 'aluno';
const agora = () => Math.floor(Date.now() / 1000);
const codificar = valor => Buffer.from(JSON.stringify(valor)).toString('base64url');
const assinar = dados => createHmac('sha256', segredo).update(dados).digest('base64url');
function iguais(a, b) {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
}
const cabecalho = codificar({ alg: 'HS256', typ: 'JWT' });
function gerarToken() {
  const dados = cabecalho + '.' + codificar({ sub: usuario, exp: agora() + ttl });
  return dados + '.' + assinar(dados);
}
function autorizado(valor = '') {
  const partes = /^Bearer ([\w-]+)\.([\w-]+)\.([\w-]+)$/.exec(valor);
  if (!partes) return false;
  const [, header, payload, assinatura] = partes;
  if (header !== cabecalho || !iguais(assinatura, assinar(header + '.' + payload))) return false;
  try {
    const dados = JSON.parse(Buffer.from(payload, 'base64url'));
    return dados.sub === usuario && Number.isSafeInteger(dados.exp) && dados.exp > agora();
  } catch {
    return false;
  }
}

const navis = [
  { id: 1, nome: 'Frost', descricao: 'Companheira do diário' },
  { id: 2, nome: 'Pixel', descricao: 'NAVI encontrado na cidade' },
];

function json(res, status, dados) {
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    ...(status === 401 ? { 'WWW-Authenticate': 'Bearer' } : {}),
  });
  res.end(JSON.stringify(dados));
}

export async function atender(req, res) {
  if (req.method === 'POST' && req.url === '/auth/login') {
    let tamanho = 0;
    const blocos = [];
    try {
      for await (const bloco of req) {
        tamanho += bloco.length;
        if (tamanho > 8192) { json(res, 413, { erro: 'Requisição muito grande' }); return; }
        blocos.push(bloco);
      }
      const dados = JSON.parse(Buffer.concat(blocos));
      if (dados?.usuario !== usuario || typeof dados.senha !== 'string' ||
          !iguais(dados.senha, senha)) {
        json(res, 401, { erro: 'Credenciais inválidas' });
        return;
      }
      json(res, 200, { access_token: gerarToken() });
    } catch {
      if (!res.headersSent && !res.destroyed) json(res, 400, { erro: 'JSON inválido' });
    }
    return;
  }
  if (req.method === 'GET' && req.url === '/navis') {
    if (!autorizado(req.headers.authorization)) {
      json(res, 401, { erro: 'Sessão inválida ou expirada' });
      return;
    }
    json(res, 200, navis);
    return;
  }
  json(res, 404, { erro: 'Rota não encontrada' });
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
    console.log(`API do Códice na porta ${servidor.address().port}`);
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  iniciarServidor();
}
