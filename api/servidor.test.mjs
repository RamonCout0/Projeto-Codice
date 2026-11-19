import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { Readable } from 'node:stream';
import { after, test } from 'node:test';

const pasta = mkdtempSync(join(tmpdir(), 'codice-api-'));
after(() => rmSync(pasta, { recursive: true, force: true }));
process.env.CODICE_DADOS = pasta;
process.env.CODICE_SENHA = 'senha-de-teste';
process.env.CODICE_JWT_SECRET = 'segredo-descartavel-apenas-para-testes';
process.env.CODICE_TOKEN_TTL = '30';
const { atender } = await import('./servidor.mjs');

async function chamar(method, url, { corpo, token, origem } = {}) {
  const req = Readable.from(corpo === undefined ? [] : [Buffer.from(corpo)]);
  req.method = method;
  req.url = url;
  req.headers = {
    ...(token ? { authorization: 'Bearer ' + token } : {}),
    ...(origem ? { origin: origem } : {}),
  };
  const resultado = {};
  await atender(req, {
    writeHead(status, cabecalhos) {
      resultado.status = status;
      resultado.cabecalhos = cabecalhos;
    },
    end(texto) {
      if (texto) resultado.dados = JSON.parse(texto);
    },
  });
  return resultado;
}

function login(senha, usuario = 'aluno') {
  return chamar('POST', '/auth/login', {
    corpo: JSON.stringify({ usuario, senha }),
  });
}

function registro(usuario, senha) {
  return chamar('POST', '/auth/registro', {
    corpo: JSON.stringify({ usuario, senha }),
  });
}

test('rejeita senha incorreta e JSON inválido', async () => {
  assert.equal((await login('errada')).status, 401);
  assert.equal((await chamar('POST', '/auth/login', { corpo: '{' })).status, 400);
});

test('entrega três atributos por NAVI apenas com JWT autorizado', async () => {
  assert.equal((await chamar('GET', '/navis')).status, 401);
  const sessao = await login('senha-de-teste');
  assert.equal(sessao.status, 200);
  const token = sessao.dados.access_token;
  assert.equal((await chamar('GET', '/navis', { token: token + 'X' })).status, 401);
  const consulta = await chamar('GET', '/navis', { token });
  assert.equal(consulta.status, 200);
  assert.deepEqual(consulta.dados[0], {
    id: 1, nome: 'Frost', descricao: 'Companheira do diário',
  });
});

test('rejeita JWT expirado', async (t) => {
  t.mock.method(Date, 'now', () => 1_000_000);
  const sessao = await login('senha-de-teste');
  Date.now.mock.mockImplementation(() => 1_030_000);
  const consulta = await chamar('GET', '/navis', { token: sessao.dados.access_token });
  assert.equal(consulta.status, 401);
});

test('registro cria a conta, já entrega o token e permite login', async () => {
  const criado = await registro('Ramon', 'minha-senha-123');
  assert.equal(criado.status, 201);
  const consulta = await chamar('GET', '/navis', { token: criado.dados.access_token });
  assert.equal(consulta.status, 200);

  // Usuário vira minúsculo; o login aceita do mesmo jeito.
  assert.equal((await login('minha-senha-123', 'RAMON')).status, 200);
  assert.equal((await login('outra-senha-123', 'ramon')).status, 401);

  // A senha não fica no arquivo, só o hash.
  const arquivo = readFileSync(join(pasta, 'usuarios.json'), 'utf8');
  assert.ok(arquivo.includes('"ramon"'));
  assert.ok(!arquivo.includes('minha-senha-123'));
});

test('registro recusa usuário repetido e dados fracos', async () => {
  assert.equal((await registro('ana', 'senha-boa-123')).status, 201);
  assert.equal((await registro('ana', 'outra-senha-123')).status, 409);
  assert.equal((await registro('ab', 'senha-boa-123')).status, 400);
  assert.equal((await registro('bia com espaço', 'senha-boa-123')).status, 400);
  assert.equal((await registro('bia', 'curta')).status, 400);
  assert.equal((await registro('bia', 12345678)).status, 400);
});

test('usuário inexistente recebe a mesma resposta de senha errada', async () => {
  const resposta = await login('qualquer-coisa', 'ninguem');
  assert.equal(resposta.status, 401);
  assert.deepEqual(resposta.dados, { erro: 'Credenciais inválidas' });
});

test('cada conta guarda o próprio NAVI', async () => {
  const { dados: { access_token: token } } = await registro('dono', 'senha-boa-123');
  assert.equal((await chamar('GET', '/perfil')).status, 401);
  assert.equal((await chamar('GET', '/perfil', { token })).status, 404);

  const navi = { nome: 'Faísca', elemento: 'eletrico', tracos: ['curiosa', 'brincalhona'], gostos: 'jogos' };
  const salvo = await chamar('PUT', '/perfil', { token, corpo: JSON.stringify(navi) });
  assert.equal(salvo.status, 200);
  const lido = await chamar('GET', '/perfil', { token });
  assert.deepEqual(lido.dados, { usuario: 'dono', navi });

  // Outra conta não vê esse NAVI.
  const { dados: { access_token: outro } } = await registro('vizinho', 'senha-boa-123');
  assert.equal((await chamar('GET', '/perfil', { token: outro })).status, 404);
});

test('perfil inválido é recusado', async () => {
  const { dados: { access_token: token } } = await registro('exigente', 'senha-boa-123');
  const enviar = (navi) => chamar('PUT', '/perfil', { token, corpo: JSON.stringify(navi) });
  const base = { nome: 'Nimbus', elemento: 'ar', tracos: ['calma'], gostos: '' };
  assert.equal((await enviar(base)).status, 200);
  assert.equal((await enviar({ ...base, nome: '' })).status, 400);
  assert.equal((await enviar({ ...base, nome: 'x'.repeat(21) })).status, 400);
  assert.equal((await enviar({ ...base, elemento: 'plasma' })).status, 400);
  assert.equal((await enviar({ ...base, tracos: [] })).status, 400);
  assert.equal((await enviar({ ...base, tracos: ['calma', 'calma'] })).status, 400);
  assert.equal((await enviar({ ...base, tracos: ['a', 'b', 'c', 'd'] })).status, 400);
  assert.equal((await enviar({ ...base, gostos: 'linha 1\nlinha 2' })).status, 400);
});

test('CORS só libera o app web local', async () => {
  const local = await chamar('OPTIONS', '/auth/login', { origem: 'http://localhost:8090' });
  assert.equal(local.status, 204);
  assert.equal(local.cabecalhos['Access-Control-Allow-Origin'], 'http://localhost:8090');

  const estranho = await chamar('OPTIONS', '/auth/login', { origem: 'https://site-qualquer.com' });
  assert.equal(estranho.cabecalhos['Access-Control-Allow-Origin'], undefined);
});
