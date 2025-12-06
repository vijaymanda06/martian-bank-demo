/**
 * Rate Limiting Middleware for ATM Locator Service
 * Protects API endpoints from abuse
 */

import rateLimit from 'express-rate-limit';

// General API rate limiter
const apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute window
  max: 100, // 100 requests per minute per IP
  message: {
    error: 'Too many requests',
    message: 'You have exceeded the rate limit. Please try again later.',
    retryAfter: 60
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    return req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.ip;
  },
  skip: (req) => {
    return req.path === '/health' || req.path === '/metrics';
  }
});

// ATM search rate limiter - slightly more permissive for location queries
const atmSearchLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute window
  max: 60, // 60 searches per minute
  message: {
    error: 'Too many ATM searches',
    message: 'You have exceeded the search limit. Please try again later.',
    retryAfter: 60
  },
  standardHeaders: true,
  legacyHeaders: false
});

export { apiLimiter, atmSearchLimiter };
