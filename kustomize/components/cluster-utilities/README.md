# Cluster Utilities Component

This Kustomize component automatically installs essential cluster utilities when deploying to a new cluster:

## Included Components

### ArgoCD
- **Namespace**: `argocd`
- **Installation**: Official ArgoCD stable manifests
- **Access**: Via ingress at `argocd.example.com` (configure your domain)
- **Features**:
  - GitOps continuous delivery
  - Web UI dashboard
  - CLI access
  - RBAC configuration

### Argo Rollouts
- **Namespace**: `argo-rollouts`
- **Installation**: Official Argo Rollouts latest manifests
- **Access**: Dashboard via ingress at `rollouts.example.com`
- **Features**:
  - Progressive delivery (Blue/Green, Canary)
  - Analysis and metrics
  - Dashboard for visualization

## Usage

### Option 1: Include in your main kustomization.yaml
```yaml
components:
- components/cluster-utilities
```

### Option 2: Deploy separately
```bash
kubectl apply -k kustomize/components/cluster-utilities
```

## Configuration

### Domain Configuration
Update the following files with your actual domain:
- `argocd-ingress.yaml`: Replace `argocd.example.com`
- `argo-rollouts-ingress.yaml`: Replace `rollouts.example.com`

### TLS Configuration
Uncomment the TLS sections in the ingress files and configure your certificates.

## Post-Installation Steps

### ArgoCD Setup
1. Get the initial admin password:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

2. Access ArgoCD:
   - Via LoadBalancer: `kubectl -n argocd get svc argocd-server`
   - Via Ingress: `https://argocd.example.com`

3. Login with username `admin` and the password from step 1.

### Argo Rollouts Setup
1. Install the kubectl plugin:
   ```bash
   curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
   chmod +x ./kubectl-argo-rollouts-linux-amd64
   sudo mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
   ```

2. Access the dashboard:
   - Via Ingress: `https://rollouts.example.com`
   - Via kubectl: `kubectl argo rollouts dashboard`

## Dependencies

This component requires:
- NGINX Ingress Controller (for ingress resources)
- Valid DNS configuration for the specified domains
- Optional: TLS certificates for HTTPS access

## Integration with Terraform

This component works alongside the Terraform-based installation. Choose one approach:
- **Terraform + Helm**: Use `argocd-rollouts.tf` for complete automation
- **Kustomize Component**: Use this component for GitOps-style deployment

Both approaches will result in the same functionality but with different management paradigms.