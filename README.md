# MARTIAN BANK

MartianBank is a microservices demo application that simulates an app to allow customers to access and manage their bank accounts, perform financial transactions, locate ATMs, and apply for loans. It is built using [React](https://react.dev/), [Node.js](https://nodejs.org/en/about), [Python](https://flask.palletsprojects.com/en/2.3.x/) and is packaged in [Docker](https://www.docker.com/) containers.

## Highlights

- Microservices Architecture with 8 containerized services
- GitOps deployment with ArgoCD (staging + production environments)
- Helm-based configurable deployments (HTTP/gRPC protocol switching)
- Docker Compose for local development
- Automated CI/CD with GitHub Actions (lint → test → security scan → build → deploy)
- Observability stack with Prometheus, Grafana, and Alertmanager
- Rate limiting and authentication middleware
- Swagger APIs and comprehensive documentation
- Performance tests with Locust
- Infrastructure as Code with Terraform (AWS EKS)

📖 **[Architecture Documentation](ARCHITECTURE.md)** - Detailed design decisions and system overview

## Table of Contents

- [Architecture](#architecture)
- [Local Development](#local-development)
- [Observability](#observability)
- [Running Tests](#running-tests)
- [Deployment to AWS](#deployment-to-aws)
- [CI/CD Pipeline](#cicd-pipeline)
- [Security Features](#security-features)
- [Contributing](#contributing)
- [License](#license)

## Architecture

The Martian Bank UI is created using [React](https://react.dev/) and [react-redux toolkit](https://redux-toolkit.js.org/). An [NGINX](https://www.nginx.com/) container acts as a reverse proxy for UI and backend services. There are 6 microservices: 2 (customer-auth and atm-locator) are developed in Node.js, while the others use Flask (Python). The dashboard microservice communicates with accounts, transactions, and loan microservices using [gRPC](https://grpc.io/) or [HTTP](https://en.wikipedia.org/wiki/HTTP) (configurable via deployment parameters).

![Architecture Diagram](./images/Arch.png)

### Services

| Service | Technology | Port | Description |
|---------|------------|------|-------------|
| UI | React | 3000 | Web frontend |
| NGINX | NGINX | 8080 | Reverse proxy |
| Customer Auth | Node.js | 8000 | Authentication service |
| ATM Locator | Node.js | 8001 | ATM location service |
| Dashboard | Python/Flask | 5000 | Main dashboard API |
| Accounts | Python/gRPC | 50051 | Account management |
| Transactions | Python/gRPC | 50052 | Transaction processing |
| Loan | Python/gRPC | 50053 | Loan processing |
| MongoDB | MongoDB | 27017 | Database |

### Deployment Architecture

```
Developer → Git Push → GitHub Actions → Build Images → Push to ECR → Update values.yaml → Commit
                                                                              ↓
                                                                          ArgoCD watches Git
                                                                              ↓
                                                                      Syncs to EKS Cluster
```

## Local Development

The easiest way to run MartianBank locally is using Docker Compose.

### Prerequisites

- [Docker](https://www.docker.com/) and Docker Compose installed
- Git

### Quick Start

1. Clone the repository:
```bash
git clone https://github.com/cisco-open/martian-bank-demo.git
cd martian-bank-demo
```

2. Start all services:
```bash
docker-compose up --build
```

3. Access the application:
   - **Web UI**: http://localhost:3000
   - **API Gateway (NGINX)**: http://localhost:8080

4. Stop all services:
```bash
docker-compose down
```

### Service Ports (Local Development)

| Service | URL |
|---------|-----|
| Web UI | http://localhost:3000 |
| NGINX Gateway | http://localhost:8080 |
| Customer Auth API | http://localhost:8000 |
| ATM Locator API | http://localhost:8001 |
| Dashboard API | http://localhost:5000 |
| MongoDB | localhost:27017 |

### Performance Testing (Optional)

To run Locust performance tests:
```bash
docker-compose --profile testing up locust
```
Access Locust UI at http://localhost:8089

## Observability

MartianBank includes a complete observability stack with Prometheus, Grafana, and Alertmanager.

### Start Observability Stack

```bash
# Start app + observability together
docker-compose -f docker-compose.yaml -f observability/docker-compose.observability.yaml up -d
```

### Access Dashboards

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3001 | admin / martianbank |
| Prometheus | http://localhost:9090 | - |
| Alertmanager | http://localhost:9093 | - |

### Pre-configured Dashboards

- **Martian Bank Overview**: Service health, request rates, latency, error rates
- **Resource Monitoring**: CPU, memory, disk usage
- **MongoDB Metrics**: Connections, query rates, performance

### Alerts

Configured alerts include:
- Service down (critical)
- High error rate > 5%
- High latency (p95 > 1s)
- High memory/CPU usage
- MongoDB connection issues
- Transaction failure rate > 1%

See [observability/README.md](observability/README.md) for detailed configuration.

## Running Tests

MartianBank includes smoke tests for Python and Node.js services.

### Prerequisites

- Python 3.12+ with pip
- Node.js 22+ with npm

### Python Tests

```bash
# Install test dependencies
pip install -r requirements-test.txt

# Run all Python tests
pytest tests/ -v
```

### Node.js Tests

```bash
# Customer Auth service
cd customer-auth
npm ci
npm test

# ATM Locator service
cd atm-locator
npm ci
npm test
```

### CI Integration

Tests run automatically on pull requests via GitHub Actions. The workflow:
- Runs pytest for Python services
- Runs jest for Node.js services
- Reports results as PR checks

## Deployment to AWS

MartianBank uses a GitOps approach with ArgoCD for Kubernetes deployments.

### Prerequisites

- AWS account with appropriate permissions
- [Terraform](https://www.terraform.io/) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) configured
- [Helm](https://helm.sh/) installed

### Step 1: Provision Infrastructure with Terraform

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

This creates:
- VPC with public/private subnets
- EKS cluster with managed node groups
- ECR repositories for container images
- IAM roles and policies
- Secrets Manager for sensitive data

### Step 2: Configure kubectl

```bash
aws eks update-kubeconfig --name martianbank-cluster --region us-east-1
```

### Step 3: Install ArgoCD

```bash
# Create namespace and apply configuration
kubectl apply -f argocd/install.yaml

# Install ArgoCD from official manifests
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### Step 4: Access ArgoCD UI

**Port Forward (Development):**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Access at https://localhost:8080
```

**Get Admin Password:**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```
Username: `admin`

### Step 5: Deploy MartianBank

```bash
kubectl apply -f argocd/application.yaml
```

ArgoCD will automatically:
- Create the `martianbank` namespace
- Deploy all services from the Helm chart
- Sync changes when `values.yaml` is updated in Git

### Verify Deployment

```bash
# Check ArgoCD application status
kubectl get applications -n argocd

# Check pods
kubectl get pods -n martianbank

# Get the application URL
kubectl get svc -n martianbank
```

## CI/CD Pipeline

The CI/CD pipeline is implemented with GitHub Actions and follows a GitOps workflow.

### Pipeline Stages

1. **Test**: Runs on pull requests
   - Python tests (pytest)
   - Node.js tests (jest)

2. **Build**: Runs on merge to main
   - Builds Docker images
   - Pushes to Amazon ECR
   - Tags with Git commit SHA

3. **Deploy**: GitOps via ArgoCD
   - Updates `martianbank/values.yaml` with new image tags
   - Commits changes to Git
   - ArgoCD detects changes and syncs automatically

### Workflow Files

| File | Trigger | Purpose |
|------|---------|---------|
| `.github/workflows/test.yml` | Pull requests | Run tests |
| `.github/workflows/deploy.yml` | Push to main | Build, push, update values |

## Helm Configuration

The Helm chart supports various configuration options:

```bash
# Use gRPC instead of HTTP
helm install martianbank martianbank --set SERVICE_PROTOCOL=grpc

# Disable local MongoDB (use external)
helm install martianbank martianbank --set "mongodb.enabled=false"

# Disable NGINX reverse proxy
helm install martianbank martianbank --set "nginx.enabled=false"
```

See `martianbank/values.yaml` for all available options.

## Security Features

MartianBank implements multiple layers of security:

### Rate Limiting

API endpoints are protected with rate limiting:
- General API: 100 requests/minute per IP
- Authentication: 10 attempts/15 minutes per IP
- ATM Search: 60 requests/minute per IP

Rate limiting is implemented at both:
- **NGINX Gateway**: See `nginx/nginx-ratelimit.conf`
- **Service Level**: Express middleware in Node.js services

### Authentication

- JWT-based authentication with configurable expiry
- Password hashing with bcrypt
- Protected routes via `authMiddleware`

### Container Security

- Non-root user execution (`runAsUser: 1000`)
- Read-only root filesystem
- Dropped capabilities
- Resource limits enforced

### CI/CD Security

- Trivy vulnerability scanning (blocks HIGH/CRITICAL)
- OIDC authentication (no long-lived AWS credentials)
- Branch protection with required tests

## Contributing

Pull requests and bug reports are welcome. For larger changes, please create an Issue in GitHub first to discuss your proposed changes and possible implications.

See [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

## License

[BSD 3-Clause License](https://opensource.org/license/bsd-3-clause/)
