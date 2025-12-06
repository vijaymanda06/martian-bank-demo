"""
Rate Limiting Middleware for Flask
Protects API endpoints from abuse
"""

import time
from functools import wraps
from flask import request, jsonify, g
from collections import defaultdict
import threading


class RateLimiter:
    """Simple in-memory rate limiter using token bucket algorithm"""
    
    def __init__(self):
        self.buckets = defaultdict(lambda: {'tokens': 100, 'last_update': time.time()})
        self.lock = threading.Lock()
    
    def _get_key(self, identifier):
        """Get rate limit key from request"""
        return identifier or request.headers.get('X-Forwarded-For', request.remote_addr)
    
    def _refill_tokens(self, bucket, rate, max_tokens):
        """Refill tokens based on time elapsed"""
        now = time.time()
        elapsed = now - bucket['last_update']
        bucket['tokens'] = min(max_tokens, bucket['tokens'] + elapsed * rate)
        bucket['last_update'] = now
    
    def is_allowed(self, identifier=None, rate=100/60, max_tokens=100, cost=1):
        """
        Check if request is allowed under rate limit
        
        Args:
            identifier: Unique identifier for rate limiting (default: IP)
            rate: Tokens per second to refill
            max_tokens: Maximum tokens in bucket
            cost: Number of tokens this request costs
        
        Returns:
            tuple: (allowed: bool, remaining: int, reset_time: float)
        """
        key = self._get_key(identifier)
        
        with self.lock:
            bucket = self.buckets[key]
            self._refill_tokens(bucket, rate, max_tokens)
            
            if bucket['tokens'] >= cost:
                bucket['tokens'] -= cost
                return True, int(bucket['tokens']), 0
            else:
                # Calculate time until enough tokens
                tokens_needed = cost - bucket['tokens']
                reset_time = tokens_needed / rate
                return False, 0, reset_time


# Global rate limiter instance
limiter = RateLimiter()


def rate_limit(requests_per_minute=100, burst=20):
    """
    Rate limiting decorator for Flask routes
    
    Args:
        requests_per_minute: Maximum requests per minute
        burst: Maximum burst size
    """
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            rate = requests_per_minute / 60  # Convert to per-second
            allowed, remaining, reset_time = limiter.is_allowed(
                rate=rate,
                max_tokens=burst,
                cost=1
            )
            
            if not allowed:
                response = jsonify({
                    'error': 'Too Many Requests',
                    'message': 'Rate limit exceeded. Please try again later.',
                    'retryAfter': int(reset_time) + 1
                })
                response.status_code = 429
                response.headers['Retry-After'] = str(int(reset_time) + 1)
                response.headers['X-RateLimit-Remaining'] = '0'
                return response
            
            # Add rate limit headers to response
            g.rate_limit_remaining = remaining
            return f(*args, **kwargs)
        
        return decorated_function
    return decorator


def rate_limit_by_user(requests_per_minute=50):
    """Rate limit by authenticated user instead of IP"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Get user identifier from request (e.g., from JWT or session)
            user_id = getattr(g, 'user_id', None) or request.headers.get('X-User-ID')
            
            if not user_id:
                # Fall back to IP-based limiting
                user_id = request.headers.get('X-Forwarded-For', request.remote_addr)
            
            rate = requests_per_minute / 60
            allowed, remaining, reset_time = limiter.is_allowed(
                identifier=f"user:{user_id}",
                rate=rate,
                max_tokens=requests_per_minute,
                cost=1
            )
            
            if not allowed:
                response = jsonify({
                    'error': 'Too Many Requests',
                    'message': 'You have exceeded your rate limit. Please try again later.',
                    'retryAfter': int(reset_time) + 1
                })
                response.status_code = 429
                response.headers['Retry-After'] = str(int(reset_time) + 1)
                return response
            
            return f(*args, **kwargs)
        
        return decorated_function
    return decorator


# Stricter limits for sensitive operations
auth_rate_limit = rate_limit(requests_per_minute=10, burst=5)
transaction_rate_limit = rate_limit(requests_per_minute=30, burst=10)
account_creation_rate_limit = rate_limit(requests_per_minute=5, burst=2)
