import { test } from 'node:test';
import assert from 'node:assert/strict';
import { searchBody, createServer } from './server.mjs';

test('location search uses Text Search and validates query', async (t) => {
  let sentUrl, sentBody;
  const places = [{ displayName: { text: 'Test' }, location: { latitude: 18, longitude: 99 } }];
  const server = createServer({ apiKey: 'test', fetchImpl: async (url, options) => {
    sentUrl = url; sentBody = JSON.parse(options.body);
    return { ok: true, json: async () => ({ places }) };
  } });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}`;
  assert.equal((await fetch(`${base}/locations?q=x`)).status, 400);
  assert.equal((await fetch(`${base}/locations?q=${'x'.repeat(201)}`)).status, 400);
  const response = await fetch(`${base}/locations?q=Chiang%20Mai`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { places });
  assert.ok(sentUrl.endsWith('places:searchText'));
  assert.equal(sentBody.textQuery, 'Chiang Mai');
  assert.equal(sentBody.pageSize, 8);
});

test('validates coordinates, radius and allowed cuisines', () => {
  const params = new URLSearchParams('lat=13.7&lng=100.5&radius=3000&types=thai_restaurant,cafe');
  assert.deepEqual(searchBody(params).includedTypes, ['thai_restaurant', 'cafe']);
  for (const [key, value] of [['lat', ''], ['lng', '181'], ['radius', '50001'], ['types', 'invalid']]) {
    const invalid = new URLSearchParams(params); invalid.set(key, value);
    assert.throws(() => searchBody(invalid));
  }
  assert.throws(() => searchBody(new URLSearchParams()));
});

test('proxy forwards cuisine and normalizes empty response', async (t) => {
  let sent;
  const server = createServer({ apiKey: 'test-key', fetchImpl: async (_, options) => {
    sent = options;
    return { ok: true, json: async () => ({}) };
  } });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}`;
  const response = await fetch(`${base}/restaurants?lat=13&lng=100&radius=3000&types=cafe`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { places: [] });
  assert.deepEqual(JSON.parse(sent.body).includedTypes, ['cafe']);
  assert.equal(sent.headers['X-Goog-Api-Key'], 'test-key');
  assert.equal((await fetch(`${base}/restaurants?lat=bad`)).status, 400);
});

test('upstream errors do not expose credentials or raw provider errors', async (t) => {
  const server = createServer({ apiKey: 'secret', fetchImpl: async () => { throw Error('secret'); } });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  const response = await fetch(`http://127.0.0.1:${server.address().port}/restaurants?lat=13&lng=100&radius=3000`);
  assert.equal(response.status, 502);
  assert.equal((await response.text()).includes('secret'), false);
});

test('photo proxy validates names and keeps credentials off image host', async (t) => {
  const calls = [];
  const server = createServer({apiKey: 'secret', fetchImpl: async (url, options) => {
    calls.push({url, options});
    if (calls.length === 1) return {ok: true, json: async () => ({photoUri: 'https://lh3.googleusercontent.com/test'})};
    return {ok: true, headers: new Headers({'content-type': 'image/jpeg'}), arrayBuffer: async () => new Uint8Array([1,2,3]).buffer};
  }});
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  t.after(() => new Promise(r => server.close(r)));
  const base = `http://127.0.0.1:${server.address().port}`;
  assert.equal((await fetch(`${base}/photo?name=../../secret`)).status, 400);
  assert.equal(calls.length, 0);
  const response = await fetch(`${base}/photo?name=places/abc/photos/xyz`, {headers: {Origin: 'http://localhost:3000'}});
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('content-type'), 'image/jpeg');
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.equal(response.headers.get('access-control-allow-origin'), 'http://localhost:3000');
  assert.deepEqual([...new Uint8Array(await response.arrayBuffer())], [1,2,3]);
  assert.equal(calls[0].options.headers['X-Goog-Api-Key'], 'secret');
  assert.equal(calls[1].options.headers, undefined);
});
