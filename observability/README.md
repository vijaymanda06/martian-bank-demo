# Martian Bank Observability Stack

This directory contains the observability infrastructure for Martian Bank, including metrics collection, visualization, and alerting.

## Components

| Component | Purpose | Port | URL |
|-----------|---------|------|-----|
| Prometheus | Metrics collection & storage | 9090 | http://localhost:9090 |
| Grafana | Visualization & dashboards | 3001 | http://localhost:3001 |
| Alertmanager | Alert routing & notifications | 9093 | http://localhost:9093 |
| Node Exporter | Host metrics | 9100 | http://localhost:9100 |
| MongoDB Exporter | Database metrics | 9216 | http://localhost:9216 |

## Quick Start

### Start the Observability Stack

```bash
# Start main application + observability
docker-compose -f docker-compose.yaml -f observability/docker-compose.observability.yaml up -d

# Or start observability only (if app is already running)
docker-compose -f observability/docker-compose.observability.yaml up -d
```

### Access Dashboards

1. **Grafana**: http://localhost:3001
   - Username: `admin`
   - Password: `martianbank`

2. **Prometheus**: http://localhost:9090
   - Query metrics directly
   - Check target status at `/targets`

3. **Alertmanager**: http://localhost:9093
   - View active alerts
   - Silence alerts

## Dashboards

### Martian Bank Overview

Pre-configured dashboard showing:
- Service health status (UP/DOWN)
- Request rate by service
- Response time (p95) by service
- Requests by HTTP status code
- MongoDB connections
- CPU, Memory, and Disk usage

### Importing Additional Dashboards

1. Go to Grafana → Dashboards → Import
2. Use dashboard IDs from [Grafana.com](https://grafana.com/grafana/dashboards/):
   - Node Exporter: `1860`
   - MongoDB: `2583`
   - Docker: `893`

## Metrics

### Application Metrics

Each service exposes metrics at `/metrics`:

```
# HTTP request metrics
http_requests_total{method="GET", route="/api/users", status="200"}
http_request_duration_seconds_bucket{method="GET", route="/api/users", le="0.1"}

# Business metrics
transaction_total{type="transfer", status="success"}
loan_requests_total{type="personal", status="approved"}
account_operations_total{operation="create", status="success"}
```

### Infrastructure Metrics

```
# Node metrics
node_cpu_seconds_total
node_memory_MemAvailable_bytes
node_filesystem_avail_bytes

# MongoDB metrics
mongodb_ss_connections{conn_type="current"}
mongodb_ss_opcounters_total{type="query"}
```

## Alerts

### Configured Alerts

| Alert | Severity | Condition |
|-------|----------|-----------|
| ServiceDown | Critical | Service unreachable for 1 minute |
| HighErrorRate | Warning | Error rate > 5% for 5 minutes |
| HighLatency | Warning | p95 latency > 1s for 5 minutes |
| HighMemoryUsage | Warning | Memory > 85% for 5 minutes |
| HighCPUUsage | Warning | CPU > 80% for 5 minutes |
| MongoDBDown | Critical | MongoDB unreachable for 1 minute |
| HighTransactionFailureRate | Critical | Transaction failures > 1% |

### Configuring Alert Notifications

Edit `alertmanager/alertmanager.yml` to configure:

**Slack:**
```yaml
receivers:
  - name: 'slack-notifications'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        channel: '#alerts'
        send_resolved: true
```

**Email:**
```yaml
receivers:
  - name: 'email-notifications'
    email_configs:
      - to: 'team@example.com'
        from: 'alertmanager@example.com'
        smarthost: 'smtp.example.com:587'
        auth_username: 'alertmanager@example.com'
        auth_password: 'password'
```

**PagerDuty:**
```yaml
receivers:
  - name: 'pagerduty'
    pagerduty_configs:
      - service_key: 'YOUR_SERVICE_KEY'
```

## Adding Metrics to Services

### Node.js (Express)

```javascript
import { metricsMiddleware, metricsEndpoint } from './middleware/metricsMiddleware.js';

app.use(metricsMiddleware);
app.get('/metrics', metricsEndpoint);
```

### Python (Flask)

```python
from middleware.metrics import setup_metrics

app = Flask(__name__)
setup_metrics(app)
```

## Prometheus Queries

### Useful PromQL Queries

**Request Rate:**
```promql
sum(rate(http_requests_total[5m])) by (job)
```

**Error Rate:**
```promql
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))
```

**p95 Latency:**
```promql
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, job))
```

**Memory Usage:**
```promql
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100
```

## Troubleshooting

### Prometheus Not Scraping Targets

1. Check target status: http://localhost:9090/targets
2. Verify service is exposing `/metrics` endpoint
3. Check network connectivity between containers
4. Review Prometheus logs: `docker logs prometheus`

### Grafana Dashboard Not Loading

1. Verify Prometheus datasource is configured
2. Check datasource connectivity in Grafana
3. Review Grafana logs: `docker logs grafana`

### Alerts Not Firing

1. Check alert rules in Prometheus: http://localhost:9090/alerts
2. Verify Alertmanager is receiving alerts: http://localhost:9093
3. Check Alertmanager configuration syntax

## Production Considerations

1. **Persistent Storage**: Use external volumes for Prometheus and Grafana data
2. **High Availability**: Deploy Prometheus with Thanos or Cortex for HA
3. **Retention**: Configure appropriate retention periods
4. **Security**: Enable authentication for all endpoints
5. **Resource Limits**: Set appropriate CPU/memory limits

## File Structure

```
observability/
├── docker-compose.observability.yaml  # Docker Compose for observability stack
├── prometheus/
│   ├── prometheus.yml                 # Prometheus configuration
│   └── alerts.yml                     # Alert rules
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   │   └── datasources.yml        # Prometheus datasource
│   │   └── dashboards/
│   │       └── dashboards.yml         # Dashboard provisioning
│   └── dashboards/
│       └── martianbank-overview.json  # Main dashboard
├── alertmanager/
│   └── alertmanager.yml               # Alertmanager configuration
└── README.md                          # This file
```
