const express = require('express');
const path = require('path');
const client = require('prom-client');

const app = express();
const port = process.env.PORT || 8080;

// Metrics
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics({ prefix: 'snake_app_' });

const httpRequestDurationMicroseconds = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'code'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.3, 0.5, 1, 2]
});

const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Count of HTTP requests',
  labelNames: ['method', 'route', 'code']
});

// Business metric example: games played
const gamesPlayedTotal = new client.Counter({
  name: 'snake_games_played_total',
  help: 'Number of snake games finished',
  labelNames: ['result']
});

// Serve static files (use the already-built Angular output in dist)
const staticPath = path.join(__dirname, '..', 'dist', 'snake-app', 'browser');
app.use(express.json());
app.use(express.static(staticPath));

// Metrics middleware
app.use((req, res, next) => {
  const end = httpRequestDurationMicroseconds.startTimer();
  res.on('finish', () => {
    const route = req.route && req.route.path ? req.route.path : req.path;
    httpRequestsTotal.inc({ method: req.method, route, code: res.statusCode });
    end({ method: req.method, route, code: res.statusCode });
  });
  next();
});

// Business endpoint: frontend can POST here when a game ends
app.post('/api/game/end', (req, res) => {
  const { score, result } = req.body || {};
  const r = result || 'unknown';
  gamesPlayedTotal.inc({ result: r });
  // Expose last score as a gauge (optional)
  if (typeof score === 'number') {
    if (!global.lastScoreGauge) {
      global.lastScoreGauge = new client.Gauge({ name: 'snake_last_score', help: 'Last game score' });
    }
    global.lastScoreGauge.set(score);
  }
  res.json({ ok: true });
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', client.register.contentType);
    res.end(await client.register.metrics());
  } catch (ex) {
    res.status(500).end(ex);
  }
});

// Fallback to index.html for SPA
app.get('*', (req, res) => {
  res.sendFile(path.join(staticPath, 'index.html'));
});

app.listen(port, () => {
  console.log(`Snake app server listening on ${port}`);
});
