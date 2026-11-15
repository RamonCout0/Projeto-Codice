import assert from 'node:assert/strict';
import { Readable } from 'node:stream';
import { test } from 'node:test';

process.env.CODICE_SENHA = 'senha-de-teste';
process.env.CODICE_JWT_SECRET = 'segredo-descartavel-apenas-para-testes';
process.env.CODICE_TOKEN_TTL = '30';
const { atender } = await import('./servidor.mjs');

async function chamar(method, url, { corpo, token } = {}) {
  const req = Readable.from(corpo === undefined ? [] : [Buffer.from(corpo)]);
  req.method = method;
  req.url = url;
  req.headers = token ? { authorization: 'Bearer ' + token } : {};
  const resultado = {};
  await atender(req, {
    writeHead(status) { resultado.status = status; },
    end(texto) { resultado.dados = JSON.parse(texto); },
  });
  return resultado;
}

function login(senha) {
  return chamar('POST', '/auth/login', {
    corpo: JSON.stringify({ usuario: 'aluno', senha }),
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
