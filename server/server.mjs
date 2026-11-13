import http from 'node:http';

const allowedTypes = new Set(['thai_restaurant', 'japanese_restaurant',
  'korean_restaurant', 'chinese_restaurant', 'italian_restaurant',
  'seafood_restaurant', 'vegetarian_restaurant', 'cafe']);

export function searchBody(params) {
  const number = (name, min, max) => {
    const raw = params.get(name);
    const value = raw === null || raw.trim() === '' ? NaN : Number(raw);
    if (!Number.isFinite(value) || value < min || value > max) throw new Error(`Invalid ${name}`);
    return value;
  };
  const latitude = number('lat', -90, 90);
  const longitude = number('lng', -180, 180);
  const radius = number('radius', 1000, 10000);
  const types = [...new Set((params.get('types') || '').split(',').filter(Boolean))];
  if (types.some(type => !allowedTypes.has(type))) throw new Error('Invalid cuisine');
  return { includedTypes: types.length ? types : ['restaurant', 'cafe'],
    maxResultCount: 20, rankPreference: 'DISTANCE', languageCode: 'th',
    locationRestriction: { circle: { center: { latitude, longitude }, radius } } };
}

export function createServer({ apiKey,
  origin = 'http://localhost:3000', fetchImpl = fetch } = {}) {
  return http.createServer(async (req, res) => {
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.setHeader('Cache-Control', 'no-store');
    if (req.headers.origin === origin) {
      res.setHeader('Access-Control-Allow-Origin', origin);
      res.setHeader('Vary', 'Origin');
    }
    const send = (status, data) => { res.writeHead(status); res.end(JSON.stringify(data)); };
    if (req.method !== 'GET') return send(405, { error: 'Method not allowed' });
    const url = new URL(req.url, 'http://localhost');
    if (url.pathname === '/health') return send(200, { status: 'ok' });
    if (url.pathname === '/restaurant') {
      const id = url.searchParams.get('id') || '';
      if (!/^[A-Za-z0-9_-]{1,256}$/.test(id)) return send(400, { error: 'Invalid place id' });
      if (!apiKey) return send(503, { error: 'Places API key is not configured' });
      try {
        const detail = await fetchImpl(`https://places.googleapis.com/v1/places/${id}?languageCode=th`, {
          headers: { 'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask': 'id,displayName,formattedAddress,location,types,rating,currentOpeningHours,regularOpeningHours,nationalPhoneNumber,websiteUri,priceLevel,googleMapsUri,photos' },
          signal: AbortSignal.timeout(12000),
        });
        if (!detail.ok) return send(detail.status === 404 ? 404 : 502, { error: 'Details unavailable' });
        return send(200, await detail.json());
      } catch { return send(502, { error: 'Details unavailable' }); }
    }
    if (url.pathname === '/photo') {
      const name = url.searchParams.get('name') || '';
      if (name.length > 4096 || !/^places\/[A-Za-z0-9_-]+\/photos\/[A-Za-z0-9_-]+$/.test(name)) {
        return send(400, { error: 'Invalid photo name' });
      }
      if (!apiKey) return send(503, { error: 'Places API key is not configured' });
      try {
        const metadata = await fetchImpl(`https://places.googleapis.com/v1/${name}/media?maxWidthPx=400&maxHeightPx=400&skipHttpRedirect=true`, {
          headers: { 'X-Goog-Api-Key': apiKey }, signal: AbortSignal.timeout(12000),
        });
        if (!metadata.ok) return send(502, { error: 'Photo unavailable' });
        const { photoUri } = await metadata.json();
        const photoUrl = new URL(photoUri);
        if (photoUrl.protocol !== 'https:' || !['googleusercontent.com', 'ggpht.com', 'google.com', 'googleapis.com'].some(
          host => photoUrl.hostname === host || photoUrl.hostname.endsWith(`.${host}`))) {
          return send(502, { error: 'Photo unavailable' });
        }
        // Never forward the server key to the image host.
        const photo = await fetchImpl(photoUrl.href, { signal: AbortSignal.timeout(12000) });
        const contentType = photo.headers.get('content-type') || '';
        if (!photo.ok || !/^image\/(jpeg|png|webp)(;|$)/i.test(contentType)) return send(502, { error: 'Photo unavailable' });
        const bytes = Buffer.from(await photo.arrayBuffer());
        res.setHeader('Content-Type', contentType);
        res.writeHead(200);
        return res.end(bytes);
      } catch { return send(502, { error: 'Photo unavailable' }); }
    }
    const isLocation = url.pathname === '/locations';
    if (url.pathname !== '/restaurants' && !isLocation) return send(404, { error: 'Not found' });
    let body;
    try {
      if (isLocation) {
        const query = (url.searchParams.get('q') || '').trim();
        if (query.length < 2 || query.length > 200) throw new Error('Invalid location query');
        body = { textQuery: query, languageCode: 'th', regionCode: 'TH', pageSize: 8 };
      } else { body = searchBody(url.searchParams); }
    }
    catch (error) { return send(400, { error: error.message }); }
    if (!apiKey) return send(503, { error: 'Places API key is not configured' });
    try {
      const upstream = await fetchImpl(`https://places.googleapis.com/v1/places:${isLocation ? 'searchText' : 'searchNearby'}`, {
        method: 'POST', signal: AbortSignal.timeout(12000),
        headers: { 'Content-Type': 'application/json', 'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': isLocation ? 'places.id,places.displayName,places.formattedAddress,places.location' : 'places.id,places.displayName,places.formattedAddress,places.location,places.types,places.rating,places.currentOpeningHours,places.googleMapsUri,places.photos,places.priceLevel' },
        body: JSON.stringify(body),
      });
      if (!upstream.ok) return send(502, { error: 'Places service unavailable' });
      const data = await upstream.json();
      return send(200, { places: data.places || [] });
    } catch { return send(502, { error: 'Places service unavailable' }); }
  });
}

