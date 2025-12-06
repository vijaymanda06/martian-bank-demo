/**
 * Prometheus Metrics Middleware for ATM Locator Service
 * Collects HTTP request metrics for monitoring
 */

import client from 'prom-client';

// Create a Registry to register metrics
const register = new client.Registry();

// Add default metrics (CPU, memory, etc.)
client.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.001, 0.005, 0.015, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 1, 2, 5]
});

const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status']
});

const httpRequestsInProgress = new client.Gauge({
  name: 'http_requests_in_progress',
  help: 'Number of HTTP requests currently being processed',
  labelNames: ['method']
});

// ATM-specific metrics
const atmSearches = new client.Counter({
  name: 'atm_searches_total',
  help: 'Total ATM location searches',
  labelNames: ['city', 'status']
});

const atmSearchLatency = new client.Histogram({
  name: 'atm_search_duration_seconds',
  help: 'ATM search latency in seconds',
  labelNames: ['city'],
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5]
});

// Register custom metrics
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestsTotal);
register.registerMetric(httpRequestsInProgress);
register.registerMetric(atmSearches);
register.registerMetric(atmSearchLatency);

/**
 * Middleware to collect metrics for each request
 */
const metricsMiddleware = (req, res, next) => {
  if (req.path === '/metrics') {
    return next();
  }

  const start = process.hrtime.bigint();
  httpRequestsInProgress.inc({ method: req.method });

  res.on('finish', () => {
    const duration = Number(process.hrtime.bigint() - start) / 1e9;
    const route = req.route?.path || req.path || 'unknown';
    const labels = {
      method: req.method,
      route: route,
      status: res.statusCode
    };

    httpRequestDuration.observe(labels, duration);
    httpRequestsTotal.inc(labels);
    httpRequestsInProgress.dec({ method: req.method });
  });

  next();
};

/**
 * Track ATM search metrics
 */
const trackAtmSearch = (city, status, duration) => {
  atmSearches.inc({ city: city || 'unknown', status });
  if (duration) {
    atmSearchLatency.observe({ city: city || 'unknown' }, duration);
  }
};

/**
 * Endpoint handler for /metrics
 */
const metricsEndpoint = async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
};

export { metricsMiddleware, metricsEndpoint, trackAtmSearch, register };
