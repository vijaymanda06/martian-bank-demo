# Copyright (c) 2023 Cisco Systems, Inc. and its affiliates All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# =============================================================================
# Builder Stage - Install dependencies and compile protobufs
# =============================================================================
FROM python:3.12-slim-bookworm AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY transactions/requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Copy protobufs and compile
COPY protobufs/ ./protobufs/
RUN python -m grpc_tools.protoc -I protobufs --python_out=. --grpc_python_out=. protobufs/transaction.proto

# =============================================================================
# Runtime Stage - Minimal image with only necessary artifacts
# =============================================================================
FROM python:3.12-slim-bookworm

# Create non-root user with UID 1000
RUN useradd --create-home --uid 1000 appuser

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /root/.local /home/appuser/.local

# Copy compiled protobuf files
COPY --from=builder /build/transaction_pb2.py /build/transaction_pb2_grpc.py ./

# Copy application source
COPY transactions/transaction.py transactions/api_client.py ./

# Set environment and permissions
ENV PATH=/home/appuser/.local/bin:$PATH
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER 1000

EXPOSE 50052

ENTRYPOINT ["python", "transaction.py"]
