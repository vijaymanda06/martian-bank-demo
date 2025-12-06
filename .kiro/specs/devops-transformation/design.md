# Design Document

## Overview

This design transforms Martian Bank from a push-based deployment model to a GitOps architecture. The key changes are:

1. **Test Coverage**: Add minimal smoke tests for Python and Node.js services
2. **CI Pipeline**: Update GitHub Actions to run tests on PRs
3. **ArgoCD**: Install ArgoCD and configure it to watch the Helm chart
4. **GitOps Flow**: CI builds images and updates Git; ArgoCD deploys automatically
5. **Documentation**: Update README with current architecture and workflows

The design maintains backward compatibility with existing Docker Compose local development and the current Helm chart structure.

## Architecture

### Current State
```
Developer → Git Push → GitHub Actions → Build Images → Push to ECR → helm upgrade (direct deploy)
```

### Target State
```
Developer → Git Push → GitHub Actions → Build Images → Push to ECR → Update values.yaml → Commit
                                                                              ↓
                                                                          ArgoCD watches Git
                                                                              ↓
                                                                      Syncs to EKS Cluster
```

### Components

**Local Development**
- Docker Compose for running all services locally
- No changes to existing setup

**CI Pipeline (GitHub Actions)**
- Lint job: Run ruff (Python) and eslint (Node.js)
- Test job: Run pytest and jest
- Security job: Run Trivy scans
- Build job: Build and push images to ECR
- Deploy job: Update Helm values with new image tags and commit

**ArgoCD**
- Installed in the EKS cluster
- Watches the `martianbank` Helm chart directory
- Auto-syncs when values.yaml changes
- Provides UI for deployment visibility

**Helm Chart**
- Existing chart structure remains unchanged
- Values file updated by CI with new image tags
- ArgoCD applies changes to cluster

## Components and Interfaces

### Test Suite

**Python Tests (pytest)**
- Location: `tests/` directory
- Framework: pytest with hypothesis for property-based tests
- Coverage: Smoke tests for accounts, transactions, loan services
- Existing tests remain; add minimal new tests if needed

**Node.js Tests (jest + supertest)**
- Location: `customer-auth/__tests__/` and `atm-locator/__tests__/`
- Framework: jest with supertest for HTTP testing
- Coverage: Health endpoint tests

### CI Workflow

**File**: `.github/workflows/test.yml`
- Triggers: Pull requests to main
- Jobs:
  - Install dependencies
  - Run pytest for Python services
  - Run jest for Node.js services
  - Report results

**File**: `.github/workflows/deploy.yml` (updated)
- Keep existing lint, test, security, build jobs
- Update deploy job to:
  - Update `martianbank/values.yaml` with new image tags
  - Commit and push changes
  - Let ArgoCD handle actual deployment

### ArgoCD Setup

**Installation**
- Use official ArgoCD installation manifest
- Install to `argocd` namespace
- Expose via LoadBalancer or port-forward for demo

**Application Manifest**
- File: `argocd/application.yaml`
- Points to: `martianbank/` Helm chart directory
- Sync policy: Automated
- Self-heal: Enabled

### Documentation

**README.md Structure**
1. Overview and architecture description
2. Local development with Docker Compose
3. Running tests
4. Deployment to AWS
   - Terraform for infrastructure
   - ArgoCD for application deployment
5. CI/CD pipeline explanation

## Data Models

### Helm Values Structure
```yaml
global:
  image:
    registry: <ecr-registry>
    tag: <git-sha>

services:
  accounts:
    enabled: true
    image: martianbank-accounts
  customer-auth:
    enabled: true
    image: martianbank-customer-auth
  # ... other services
```

### ArgoCD Application Spec
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: martianbank
spec:
  source:
    repoURL: <github-repo>
    path: martianbank
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: martianbank
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Test execution completeness
*For any* test suite execution, all discovered tests should be executed and none should be skipped due to configuration errors
**Validates: Requirements 1**

### Property 2: CI workflow determinism
*For any* pull request, running the test workflow multiple times with the same code should produce the same pass/fail result
**Validates: Requirements 2**

### Property 3: GitOps sync consistency
*For any* commit to values.yaml containing a valid image tag, ArgoCD should eventually sync the cluster to match that state
**Validates: Requirements 3, 4**

### Property 4: Image tag traceability
*For any* deployed pod, the image tag should correspond to a valid Git commit SHA in the repository
**Validates: Requirements 4**

## Error Handling

### Test Failures
- CI marks check as failed
- PR cannot be merged until tests pass
- Clear error messages in GitHub Actions logs

### ArgoCD Sync Failures
- ArgoCD retries automatically
- Previous working state is maintained
- Sync status visible in ArgoCD UI
- Alerts can be configured for persistent failures

### Invalid Helm Values
- ArgoCD validates manifests before applying
- Sync fails with validation error
- Cluster state unchanged

### Image Pull Failures
- Kubernetes retries with backoff
- Pod remains in ImagePullBackOff state
- ArgoCD reports unhealthy status
- Previous version continues running

## Testing Strategy

### Unit Tests
- Minimal smoke tests to verify services start correctly
- Test health endpoints return 200
- Mock external dependencies (MongoDB, etc.)
- Fast execution (< 30 seconds total)

### Property-Based Tests
- Use hypothesis (Python) for property-based testing
- Generate random inputs to test service robustness
- Validate that health endpoints always return valid HTTP status codes
- Run 100 iterations per property test

### Integration Tests
- Docker Compose for local integration testing
- Verify services can communicate
- Not part of CI pipeline (too slow for demo)

### Testing Tools
- **Python**: pytest, hypothesis, pytest-cov
- **Node.js**: jest, supertest
- **CI**: GitHub Actions with test result reporting

### Test Execution
- Local: `pytest tests/` and `npm test`
- CI: Automated on every PR
- Coverage: Focus on critical paths, not 100% coverage

### Property-Based Test Configuration
- Minimum 100 iterations per property test
- Tag each test with: `**Feature: devops-transformation, Property X: <description>**`
- Reference requirements: `**Validates: Requirements X.Y**`
