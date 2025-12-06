# ArgoCD Setup for Martian Bank

This directory contains the ArgoCD configuration for GitOps-based deployment of Martian Bank.

## Prerequisites

- EKS cluster running and accessible via kubectl
- kubectl configured with cluster admin permissions
- Helm chart in `martianbank/` directory

## Installation Steps

### 1. Install ArgoCD

```bash
# Create the argocd namespace and apply custom configuration
kubectl apply -f argocd/install.yaml

# Install ArgoCD from official manifests
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### 2. Access ArgoCD UI

**Option A: Port Forward (Development)**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Access at https://localhost:8080
```

**Option B: LoadBalancer (Production)**
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
# Get the external URL
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### 3. Get Admin Password

```bash
# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo  # Add newline for readability
```

Default username: `admin`

### 4. Deploy Martian Bank Application

```bash
# Apply the ArgoCD Application manifest
kubectl apply -f argocd/application.yaml
```

ArgoCD will automatically:
- Create the `martianbank` namespace
- Deploy all services from the Helm chart
- Sync changes when `values.yaml` is updated in Git

## GitOps Workflow

Once configured, the deployment flow is:

1. CI pipeline builds new container images
2. CI updates `martianbank/values.yaml` with new image tags
3. CI commits and pushes changes to Git
4. ArgoCD detects the change and syncs automatically
5. New version is deployed to the cluster

## Configuration Files

| File | Description |
|------|-------------|
| `install.yaml` | ArgoCD namespace and configuration |
| `application.yaml` | ArgoCD Application and Project definitions |

## Sync Policies

The application is configured with:
- **Automated sync**: Changes in Git trigger automatic deployment
- **Self-heal**: Drift from desired state is automatically corrected
- **Prune**: Resources removed from Git are deleted from cluster
- **Retry**: Failed syncs retry up to 5 times with exponential backoff

## Troubleshooting

### Check Application Status
```bash
kubectl get applications -n argocd
kubectl describe application martianbank -n argocd
```

### View Sync Status
```bash
# Using ArgoCD CLI (if installed)
argocd app get martianbank

# Or via kubectl
kubectl get application martianbank -n argocd -o jsonpath='{.status.sync.status}'
```

### Force Sync
```bash
# Via ArgoCD CLI
argocd app sync martianbank

# Or delete the application and reapply
kubectl delete application martianbank -n argocd
kubectl apply -f argocd/application.yaml
```

### View Logs
```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server
```

## Security Notes

- Change the admin password after first login
- Consider integrating with SSO/OIDC for production
- Review RBAC policies in `install.yaml` for your security requirements
- The server runs in insecure mode (TLS terminated at load balancer)
