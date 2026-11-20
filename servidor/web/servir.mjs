// Serve o app web do Códice (build/web) e repassa a conversa ao Ollama.
//
// Por que o repasse: o navegador só deixa uma página falar com outro endereço
// se esse endereço liberar (CORS), e o Ollama só libera o próprio localhost.
// Aqui o app pede /api/chat à mesma origem que o serviu, e este servidor
// leva o pedido ao Ollama (streaming incluído). Só duas rotas passam.
//
//   CODICE_WEB_PASTA   pasta do build (padrão ./build/web)
//   CODICE_WEB_HOST    endereço de escuta (padrão 127.0.0.1)
//   CODICE_WEB_PORTA   porta (padrão 8090)
//   OLLAMA_ALVO        onde está o Ollama (padrão http://127.0.0.1:11434)
import { createServer, request as pedir } from 'node:http';
import { createReadStream, existsSync, statSync } from 'node:fs';
import { extname, join, normalize, resolve, sep } from 'node:path';

const pasta = resolve(process.env.CODICE_WEB_PASTA ?? 'build/web');
const host = process.env.CODICE_WEB_HOST ?? '127.0.0.1';
const porta = Number(process.env.CODICE_WEB_PORTA ?? 8090);
const alvo = new URL(process.env.OLLAMA_ALVO ?? 'http://127.0.0.1:11434');

const tipos = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8', '.png': 'image/png', '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml', '.ico': 'image/x-icon', '.ttf': 'font/ttf', '.otf': 'font/otf',
  '.woff2': 'font/woff2', '.wasm': 'application/wasm', '.webmanifest': 'application/manifest+json',
};

// Só o que a conversa usa. Qualquer outra rota do Ollama (apagar modelo,
// baixar modelo...) fica de fora.
const rotasOllama = new Set(['POST /api/chat', 'GET /api/tags']);

function repassar(req, res) {
  const saida = pedir(
    { host: alvo.hostname, port: alvo.port, path: req.url, method: req.method,
      headers: { 'content-type': req.headers['content-type'] ?? 'application/json' } },
    (resp) => {
      res.writeHead(resp.statusCode ?? 502, { 'content-type': resp.headers['content-type'] ?? 'application/json' });
      resp.pipe(res);
    },
  );
  saida.on('error', () => {
    if (!res.headersSent) res.writeHead(502, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ error: 'Ollama indisponível' }));
  });
  req.pipe(saida);
}

function arquivo(req, res) {
  const caminho = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  let alvoArq = normalize(join(pasta, caminho));
  // Nunca sair da pasta do build.
  if (alvoArq !== pasta && !alvoArq.startsWith(pasta + sep)) {
    res.writeHead(403).end();
    return;
  }
  if (!existsSync(alvoArq) || statSync(alvoArq).isDirectory()) {
    // Rota do app (sem extensão): entrega o index e deixa o Flutter decidir.
    alvoArq = extname(caminho) ? '' : join(pasta, 'index.html');
  }
  if (!alvoArq || !existsSync(alvoArq)) {
    res.writeHead(404).end('não encontrado');
    return;
  }
  const ext = extname(alvoArq);
  res.writeHead(200, {
    'content-type': tipos[ext] ?? 'application/octet-stream',
    // O app se atualiza ao abrir: nada de versão velha presa no cache.
    'cache-control': ext === '.html' || alvoArq.endsWith('flutter_service_worker.js') ? 'no-cache' : 'public, max-age=3600',
  });
  createReadStream(alvoArq).pipe(res);
}

createServer((req, res) => {
  const rota = `${req.method} ${new URL(req.url, 'http://x').pathname}`;
  if (rotasOllama.has(rota)) return repassar(req, res);
  if (req.method !== 'GET' && req.method !== 'HEAD') return void res.writeHead(405).end();
  return arquivo(req, res);
}).listen(porta, host, () => console.log(`app web em http://${host}:${porta} (pasta ${pasta})`));
