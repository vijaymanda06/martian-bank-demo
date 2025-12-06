# Martian Bank Architecture

This document describes the architectural decisions, design patterns, and technical choices made for the Martian Bank microservices application.

## Table of Contents

- [System Overview](#system-overview)
- [Architecture Decisions](#architecture-decisions)
- [Service Communication](#service-communication)
- [Data Architecture](#data-architecture)
- [Infrastructure](#infrastructure)
- [Security](#security)
- [Observability](#observability)
- [CI/CD Pipeline](#cicd-pipeline)

## System Overview

Martian Bank is a cloud-native banking application built using microservices architecture. The system enables customers to manage bank accounts, perform financial transactions, locate ATMs, and apply for loans.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Client Layer                                    │
│                         (Web Browser / Mobile)                               │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           API Gateway (NGINX)                                │
│                              Port: 8080                                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │ /           │  │ /api/users  │  │ /api/atm    │  │ /api/account|loan   │ │
│  │ → UI:3000   │  │ → Auth:8000 │  │ → ATM:8001  │  │ → Dashboard:5000    │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        ▼                           ▼                           ▼
┌───────────────┐           ┌───────────────┐           ┌───────────────┐
│   React UI    │           │  Node.js      │           │  Python/Flask │
│   Port: 3000  │           │  Services     │           │  Services     │
│               │           │               │           │               │
│ • Redux State │           │ • Auth: 8000  │           │ • Dashboard   │
│ • Vite Build  │           │ • ATM: 8001   │           │ • Accounts    │
│ • SPA Router  │           │               │           │ • Transactions│
└───────────────┘           └───────────────┘           │ • Loans       │
                                    │                   └───────────────┘
                                    │                           │
                                    │         ┌─────────────────┤
                                    │         │ gRPC/HTTP       │
                                    ▼         ▼                 ▼
                            ┌─────────────────────────────────────┐
                            │           MongoDB 7.0               │
                            │           Port: 27017               │
                            │                                     │
                            │  Collections:                       │
                            │  • users      • accounts            │
                            │  • atms       • transactions        │
                            │  • loans                            │
                            └─────────────────────────────────────┘
```

## Architecture Decisions

### ADR-001: Microservices Architecture

**Context**: Building a banking application that needs to scale independently, be maintained by different teams, and support continuous deployment.

**Decision**: Adopt microservices architecture with 8 independently deployable services.

**Rationale**:
- Independent scaling: Transaction service can scale during peak hours without affecting ATM locator
- Technology flexibility: Node.js for I/O-heavy auth, Python for computation-heavy banking logic
- Fault isolation: Failure in loan service doesn't affect account operations
- Team autonomy: Different teams can own different services

**Consequences**:
- Increased operational complexity
- Need for service discovery and load balancing
- Distributed tracing required for debugging

### ADR-002: Dual Protocol Support (HTTP/gRPC)

**Context**: Internal services need efficient communication, while external clients need REST APIs.

**Decision**: Support both HTTP REST and gRPC protocols, configurable via `SERVICE_PROTOCOL` environment variable.

**Rationale**:
- gRPC benefits: Binary protocol, ~10x faster than JSON, strong typing via Protocol Buffers
- HTTP benefits: Browser compatibility, easier debugging, wider tooling support
- Flexibility: Development uses HTTP for debugging; production can use gRPC for performance

**When to use gRPC**:
```
Dashboard ──gRPC──► Accounts Service (high-frequency balance checks)
Dashboard ──gRPC──► Transactions Service (bulk transaction processing)
Dashboard ──gRPC──► Loan Service (complex loan calculations)
```

**When to use HTTP**:
```
Browser ──HTTP──► NGINX ──HTTP──► Customer Auth (JWT-based auth)
Browser ──HTTP──► NGINX ──HTTP──► ATM Locator (geo queries)
```

### ADR-003: API Gateway Pattern

**Context**: Multiple backend services need unified entry point with cross-cutting concerns.

**Decision**: Use NGINX as reverse proxy/API gateway.

**Rationale**:
- Single entry point for all client requests
- SSL termination at gateway level
- Request routing based on URL path
- Future: Rate limiting, caching, request transformation

**Routing Configuration**:
| Path | Backend Service | Port |
|------|-----------------|------|
| `/` | UI (React) | 3000 |
| `/api/users/*` | Customer Auth | 8000 |
| `/api/atm/*` | ATM Locator | 8001 |
| `/api/account/*` | Dashboard | 5000 |
| `/api/transaction/*` | Dashboard | 5000 |
| `/api/loan/*` | Dashboard | 5000 |

### ADR-004: Database Per Service (Logical Separation)

**Context**: Microservices need data isolation while managing operational complexity.

**Decision**: Single MongoDB instance with logical collection separation per service.

**Rationale**:
- Simplified operations for demo/development
- Each service owns its collections
- Easy migration to separate databases in production

**Collection Ownership**:
```
Customer Auth  → users collection
ATM Locator    → atms collection
Accounts       → accounts collection
Transactions   → transactions collection
Loans          → loans collection
```

### ADR-005: GitOps Deployment Model

**Context**: Need reliable, auditable, and automated deployments to Kubernetes.

**Decision**: Implement GitOps using ArgoCD with Helm charts.

**Rationale**:
- Git as single source of truth
- Declarative infrastructure
- Automatic drift detection and correction
- Full audit trail via Git history

**Flow**:
```
Code Push → GitHub Actions → Build Image → Push to ECR → Update values.yaml → Git Commit
                                                                    ↓
                                                            ArgoCD detects change
                                                                    ↓
                                                            Sync to EKS cluster
```

## Service Communication

### Synchronous Communication

```
┌──────────────┐     HTTP/REST      ┌──────────────┐
│   Frontend   │ ◄─────────────────► │    NGINX     │
└──────────────┘                     └──────────────┘
                                            │
                    ┌───────────────────────┼───────────────────────┐
                    ▼                       ▼                       ▼
            ┌──────────────┐        ┌──────────────┐        ┌──────────────┐
            │ Customer Auth│        │  ATM Locator │        │  Dashboard   │
            │   (Node.js)  │        │   (Node.js)  │        │   (Flask)    │
            └──────────────┘        └──────────────┘        └──────────────┘
                                                                    │
                                                    gRPC or HTTP (configurable)
                                    ┌───────────────────────┬───────┴───────┐
                                    ▼                       ▼               ▼
                            ┌──────────────┐        ┌──────────────┐ ┌──────────────┐
                            │   Accounts   │        │ Transactions │ │    Loans     │
                            │   (Python)   │        │   (Python)   │ │   (Python)   │
                            └──────────────┘        └──────────────┘ └──────────────┘
```

### Protocol Buffer Definitions

Located in `/protobufs/`:
- `accounts.proto` - Account CRUD operations
- `transaction.proto` - Money transfer operations
- `loan.proto` - Loan application processing

### Error Handling Strategy

| Error Type | HTTP Status | gRPC Code | Retry |
|------------|-------------|-----------|-------|
| Validation | 400 | INVALID_ARGUMENT | No |
| Auth Failed | 401 | UNAUTHENTICATED | No |
| Not Found | 404 | NOT_FOUND | No |
| Rate Limited | 429 | RESOURCE_EXHAUSTED | Yes (backoff) |
| Server Error | 500 | INTERNAL | Yes (3 attempts) |
| Unavailable | 503 | UNAVAILABLE | Yes (circuit breaker) |

## Data Architecture

### MongoDB Schema Design

**Users Collection** (Customer Auth Service)
```javascript
{
  _id: ObjectId,
  name: String,
  email: String (unique, indexed),
  password: String (bcrypt hashed),
  createdAt: Date,
  updatedAt: Date
}
```

**Accounts Collection** (Accounts Service)
```javascript
{
  _id: ObjectId,
  account_number: String (unique, indexed),  // Format: IBAN + 16 digits
  email_id: String (indexed),
  account_type: String,  // "checking" | "savings"
  name: String,
  address: String,
  govt_id_number: String,
  government_id_type: String,
  balance: Number,
  currency: String,  // Default: "USD"
  created_at: Date
}
```

**Transactions Collection** (Transactions Service)
```javascript
{
  _id: ObjectId,
  transaction_id: String (unique),
  account_number: String (indexed),
  amount: Number,
  type: String,  // "credit" | "debit"
  reason: String,
  time_stamp: Date,
  sender_account_number: String,
  receiver_account_number: String
}
```

**Loans Collection** (Loan Service)
```javascript
{
  _id: ObjectId,
  email: String (indexed),
  name: String,
  account_number: String,
  account_type: String,
  govt_id_type: String,
  govt_id_number: String,
  loan_type: String,
  loan_amount: Number,
  interest_rate: Number,
  time_period: String,
  status: String,  // "pending" | "approved" | "rejected"
  timestamp: Date
}
```

### Data Flow Patterns

**Account Creation Flow**:
```
UI → NGINX → Dashboard → Accounts Service → MongoDB
                              │
                              └── Validates: No duplicate email+account_type
                              └── Generates: IBAN account number
                              └── Sets: Initial balance = 100 USD
```

**Money Transfer Flow**:
```
UI → NGINX → Dashboard → Transactions Service
                              │
                              ├── Validates sender balance
                              ├── Debits sender account
                              ├── Credits receiver account
                              └── Records transaction history
```

## Infrastructure

### AWS Architecture (Production)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud                                       │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                         VPC (10.0.0.0/16)                              │  │
│  │                                                                        │  │
│  │  ┌─────────────────────┐          ┌─────────────────────┐             │  │
│  │  │   Public Subnets    │          │   Private Subnets   │             │  │
│  │  │                     │          │                     │             │  │
│  │  │  ┌───────────────┐  │          │  ┌───────────────┐  │             │  │
│  │  │  │  ALB Ingress  │  │          │  │  EKS Cluster  │  │             │  │
│  │  │  │  Controller   │◄─┼──────────┼─►│  (Auto Mode)  │  │             │  │
│  │  │  └───────────────┘  │          │  └───────────────┘  │             │  │
│  │  │                     │          │         │           │             │  │
│  │  │  ┌───────────────┐  │          │         ▼           │             │  │
│  │  │  │  NAT Gateway  │◄─┼──────────┼── Outbound Traffic  │             │  │
│  │  │  └───────────────┘  │          │                     │             │  │
│  │  └─────────────────────┘          └─────────────────────┘             │  │
│  │                                                                        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │     ECR      │  │   Secrets    │  │  CloudWatch  │  │     IAM      │    │
│  │ Repositories │  │   Manager    │  │    Logs      │  │    Roles     │    │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Terraform Modules

| Module | Purpose | Key Resources |
|--------|---------|---------------|
| `vpc` | Networking | VPC, Subnets, NAT Gateway, Route Tables |
| `eks` | Kubernetes | EKS Cluster (Auto Mode), OIDC Provider |
| `iam` | Security | Service Roles, GitHub OIDC, IRSA |
| `secrets` | Credentials | Secrets Manager entries |
| `ecr` | Container Registry | 7 repositories with lifecycle policies |

### EKS Auto Mode

Using EKS Auto Mode for simplified cluster management:
- AWS-managed node pools (general-purpose, system)
- Automatic Karpenter scaling
- Built-in ALB controller
- Pod Identity support

## Security

### Authentication Flow

```
┌────────┐     1. Login Request      ┌──────────────┐
│ Client │ ─────────────────────────► │ Customer Auth│
└────────┘                            └──────────────┘
    │                                        │
    │                                        │ 2. Validate credentials
    │                                        │    against MongoDB
    │                                        ▼
    │                                 ┌──────────────┐
    │                                 │   MongoDB    │
    │                                 └──────────────┘
    │                                        │
    │     3. Return JWT Token               │
    │ ◄──────────────────────────────────────┘
    │
    │     4. Subsequent requests with
    │        Authorization: <token>
    ▼
┌──────────────┐
│    NGINX     │ ─────► Protected Services
└──────────────┘
```

### Security Measures

| Layer | Measure | Implementation |
|-------|---------|----------------|
| Transport | TLS/HTTPS | ALB SSL termination |
| Authentication | JWT | HS256 signed tokens |
| Authorization | Middleware | `protect` middleware in routes |
| Secrets | AWS Secrets Manager | External Secrets Operator |
| Container | Non-root user | `runAsUser: 1000` |
| Container | Read-only filesystem | `readOnlyRootFilesystem: true` |
| Network | Private subnets | EKS nodes in private subnets |
| CI/CD | OIDC | GitHub Actions → AWS (no long-lived keys) |
| Scanning | Trivy | HIGH/CRITICAL vulnerability blocking |

### Rate Limiting

Implemented at NGINX gateway level:
- 100 requests/minute per IP for API endpoints
- 1000 requests/minute for static assets
- Burst allowance of 20 requests

## Observability

### Metrics (Prometheus)

Collected metrics:
- HTTP request duration (histogram)
- Request count by status code
- Active connections
- Service health status

### Logging

Structured JSON logging with:
- Timestamp
- Service name
- Log level
- Request ID (correlation)
- Message and context

### Health Checks

Each service exposes `/health` endpoint:
```json
{
  "status": "healthy",
  "service": "customer-auth",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Distributed Tracing (Future)

Planned OpenTelemetry integration for request tracing across services.

## CI/CD Pipeline

### Pipeline Stages

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    Lint     │───►│    Test     │───►│  Security   │───►│    Build    │
│             │    │             │    │    Scan     │    │             │
│ • ruff      │    │ • pytest    │    │ • Trivy     │    │ • Docker    │
│ • eslint    │    │ • jest      │    │             │    │ • Push ECR  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                                │
                                                                ▼
                                                        ┌─────────────┐
                                                        │   Deploy    │
                                                        │             │
                                                        │ • Update    │
                                                        │   values.yaml│
                                                        │ • Git commit│
                                                        └─────────────┘
                                                                │
                                                                ▼
                                                        ┌─────────────┐
                                                        │   ArgoCD    │
                                                        │             │
                                                        │ • Detect    │
                                                        │ • Sync      │
                                                        │ • Deploy    │
                                                        └─────────────┘
```

### Branch Strategy

| Branch | Purpose | Deployment |
|--------|---------|------------|
| `main` | Production code | Auto-deploy to production |
| `feature/*` | New features | PR required, tests must pass |
| `hotfix/*` | Critical fixes | Fast-track PR process |

### Rollback Strategy

1. **Automatic**: ArgoCD detects failed health checks, pauses sync
2. **Manual Git Revert**: Revert values.yaml commit, ArgoCD syncs previous state
3. **ArgoCD UI**: Click "Rollback" to previous successful deployment

## Performance Considerations

### Scaling Strategy

| Service | Scaling Trigger | Min/Max Replicas |
|---------|-----------------|------------------|
| UI | CPU > 70% | 2/10 |
| Customer Auth | CPU > 80% | 2/10 |
| ATM Locator | CPU > 80% | 2/10 |
| Dashboard | CPU > 70% | 2/10 |
| Accounts | CPU > 70% | 2/10 |
| Transactions | CPU > 60% | 2/20 |
| Loans | CPU > 80% | 2/10 |

### Caching Strategy (Future)

- Redis for session storage
- API response caching at NGINX
- MongoDB query result caching

## Technology Stack Summary

| Component | Technology | Version |
|-----------|------------|---------|
| Frontend | React + Redux + Vite | 18.x |
| API Gateway | NGINX | 1.27 |
| Auth Service | Node.js + Express | 22.x |
| ATM Service | Node.js + Express | 22.x |
| Dashboard | Python + Flask | 3.12 |
| Core Services | Python + gRPC | 3.12 |
| Database | MongoDB | 7.0 |
| Container Runtime | Docker | 24.x |
| Orchestration | Kubernetes (EKS) | 1.31 |
| IaC | Terraform | 1.5+ |
| CI/CD | GitHub Actions | - |
| GitOps | ArgoCD | 2.x |
| Cloud | AWS | - |
