import { createServer } from './server.mjs';

const port = Number(process.env.PORT || 8080);
const host = process.env.HOST || '127.0.0.1';
createServer({ apiKey: process.env.GOOGLE_PLACES_API_KEY,
  origin: process.env.ALLOWED_ORIGIN || 'http://localhost:3000',
}).listen(port, host, () => console.log(`kinkin API listening on ${host}:${port}`));
