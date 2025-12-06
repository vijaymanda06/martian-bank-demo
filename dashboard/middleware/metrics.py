"""
Prometheus Metrics Middleware for Flask
Collects HTTP request metrics for monitoring
"""

import time
from functools import wraps
from flask import request, Response
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST

# Metrics
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency in seconds',
    ['method', 'endpoint'],
    buckets=[0.001, 0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1.0, 2.5, 5.0]
)

REQUESTS_IN_PROGRESS = Gauge(
    'http_requests_in_progress',
    'Number of HTTP requests in progress',
    ['method']
)

# Business metrics
TRANSACTION_COUNT = Counter(
    'transaction_total',
    'Total transactions processed',
    ['type', 'status']
)

TRANSACTION_FAILURES = Counter(
    'transaction_failures_total',
    'Total failed transactions',
    ['reason']
)

LOAN_REQUESTS = Counter(
    'loan_requests_total',
    'Total loan requests',
    ['type', 'status']
)

ACCOUNT_OPERATIONS = Counter(
    'account_operations_total',
    'Total account operations',
    ['operation', 'status']
)


def setup_metrics(app):
    """Setup metrics middleware for Flask app"""
    
    @app.before_request
    def before_request():
        request.start_time = time.time()
        REQUESTS_IN_PROGRESS.labels(method=request.method).inc()
    
    @app.after_request
    def after_request(response):
        # Calculate request duration
        latency = time.time() - getattr(request, 'start_time', time.time())
        
        # Get endpoint name
        endpoint = request.endpoint or request.path or 'unknown'
        
        # Record metrics
        REQUEST_COUNT.labels(
            method=request.method,
            endpoint=endpoint,
            status=response.status_code
        ).inc()
        
        REQUEST_LATENCY.labels(
            method=request.method,
            endpoint=endpoint
        ).observe(latency)
        
        REQUESTS_IN_PROGRESS.labels(method=request.method).dec()
        
        return response
    
    @app.route('/metrics')
    def metrics():
        """Prometheus metrics endpoint"""
        return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


def track_transaction(transaction_type, status):
    """Track transaction metrics"""
    TRANSACTION_COUNT.labels(type=transaction_type, status=status).inc()


def track_transaction_failure(reason):
    """Track transaction failure"""
    TRANSACTION_FAILURES.labels(reason=reason).inc()


def track_loan_request(loan_type, status):
    """Track loan request metrics"""
    LOAN_REQUESTS.labels(type=loan_type, status=status).inc()


def track_account_operation(operation, status):
    """Track account operation metrics"""
    ACCOUNT_OPERATIONS.labels(operation=operation, status=status).inc()
