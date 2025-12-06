# Copyright (c) 2023 Cisco Systems, Inc. and its affiliates All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# =============================================================================
# Builder stage - Install dependencies
# =============================================================================
FROM node:22-bookworm-slim AS builder

WORKDIR /build

# Install build dependencies for native modules (node-gyp requires python3, make, g++)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy package files for dependency installation
COPY package*.json ./

# Install production dependencies only
RUN npm ci --omit=dev

# Copy application source code
COPY . .

# =============================================================================
# Runtime stage - Minimal production image
# =============================================================================
FROM node:22-bookworm-slim

# Install dumb-init for proper signal handling
RUN apt-get update && \
    apt-get install -y --no-install-recommends dumb-init && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy production dependencies from builder
COPY --from=builder /build/node_modules ./node_modules

# Copy application source files
COPY --from=builder /build/*.js ./
COPY --from=builder /build/package.json ./
COPY --from=builder /build/config ./config
COPY --from=builder /build/controllers ./controllers
COPY --from=builder /build/middleware ./middleware
COPY --from=builder /build/models ./models
COPY --from=builder /build/routes ./routes
COPY --from=builder /build/utils ./utils

# Run as non-root user (UID 1000)
USER 1000

EXPOSE 8001

# Use dumb-init as PID 1 for proper signal handling
CMD ["dumb-init", "node", "server.js"]
