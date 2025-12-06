# Copyright (c) 2023 Cisco Systems, Inc. and its affiliates All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# Development Dockerfile for React UI with Vite
# Removed --platform flag to support both AMD64 and ARM64 (Apple Silicon)
FROM node:22-bookworm-slim

WORKDIR /bankapp

# Copy package files first for better layer caching
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install --silent

# Copy source code
COPY . ./

EXPOSE 3000

# Run Vite dev server
CMD ["npm", "run", "ui"]
