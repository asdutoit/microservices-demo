# Cluster Utilities: ArgoCD & Argo Rollouts Setup

This project now includes automatic deployment of essential cluster utilities (ArgoCD and Argo Rollouts) when provisioning new Kubernetes clusters. You have two deployment approaches available.

## 🏗️ Option 1: Terraform-Based Deployment (Recommended)

**Location**: `terraform/dtap/dev/argocd-rollouts.tf`

### What it does:
- Automatically installs ArgoCD and Argo Rollouts via Helm during cluster provisioning
- Integrates with your existing infrastructure-as-code workflow
- Provides consistent, reproducible deployments
- Handles dependencies (waits for NGINX ingress controller)

### Features:
- ✅ **ArgoCD**: GitOps platform with web UI, LoadBalancer service, and ingress
- ✅ **Argo Rollouts**: Progressive delivery with canary/blue-green deployments  
- ✅ **Dashboard**: Argo Rollouts visualization dashboard
- ✅ **Ingress**: Automatic ingress configuration for external access
- ✅ **RBAC**: Pre-configured security policies
- ✅ **Monitoring**: Metrics and ServiceMonitor configuration

### Usage:
```bash
cd terraform/dtap/dev

# Configure optional variables in terraform.tfvars
echo 'domain_name = "yourdomain.com"' >> terraform.tfvars
echo 'argocd_admin_password = "secure-password"' >> terraform.tfvars

# Deploy (ArgoCD/Rollouts included automatically)
terraform apply
```

### Access after deployment:
- **ArgoCD UI**: LoadBalancer IP or `https://argocd.yourdomain.com`
- **Rollouts Dashboard**: `https://rollouts.yourdomain.com`
- **Credentials**: Username `admin`, password from Terraform output

---

## 🔧 Option 2: Kustomize Component (Alternative)

**Location**: `kustomize/components/cluster-utilities/`

### What it does:
- Provides Kustomize component for GitOps-style deployment
- Uses official upstream manifests
- Can be included in your main kustomization or deployed separately

### Features:
- ✅ **Official Manifests**: Direct from ArgoCD/Argo Rollouts repositories
- ✅ **GitOps Ready**: Perfect for ArgoCD self-management
- ✅ **Flexible**: Can be mixed and matched with other components
- ✅ **Upstream**: Always uses latest stable versions

### Usage:

#### Include in main kustomization:
```yaml
# In kustomize/kustomization.yaml
components:
- components/cluster-utilities
- components/team-rbac
```

#### Deploy separately:
```bash
kubectl apply -k kustomize/components/cluster-utilities
```

---

## 🎯 Which Option Should You Choose?

### Use **Terraform Option** (Option 1) if:
- ✅ You want infrastructure components managed as code
- ✅ You prefer automated, repeatable cluster provisioning
- ✅ You need tight integration with other infrastructure resources
- ✅ You want consistent deployment across environments (dev/test/acc/prod)
- ✅ **This is the recommended approach for your use case**

### Use **Kustomize Option** (Option 2) if:
- ✅ You prefer pure GitOps workflows
- ✅ You want ArgoCD to manage itself (bootstrap pattern)  
- ✅ You need more granular control over manifest customization
- ✅ You're already heavily invested in Kustomize patterns

## 📋 Current Implementation Status

✅ **Terraform Configuration**: Ready to use  
✅ **Kustomize Component**: Available as alternative  
✅ **Documentation**: Complete setup guides  
✅ **Integration**: Works with existing NGINX ingress  
✅ **Variables**: Configurable domain and passwords  

## 🚀 Quick Start (Terraform Option)

1. **Navigate to your environment**:
   ```bash
   cd terraform/dtap/dev
   ```

2. **Configure domain** (optional):
   ```bash
   echo 'domain_name = "yourdomain.com"' >> terraform.tfvars
   ```

3. **Deploy cluster with utilities**:
   ```bash
   terraform apply
   ```

4. **Access ArgoCD**:
   ```bash
   # Get LoadBalancer IP
   kubectl get svc argocd-server -n argocd
   
   # Get admin password
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

5. **Set up your first application**:
   - Navigate to ArgoCD UI
   - Create new application pointing to your Git repo
   - Use path: `kustomize/` for your microservices

## 📁 File Organization

```
microservices-demo/
├── terraform/dtap/dev/
│   ├── argocd-rollouts.tf         # 🎯 Main Terraform config
│   ├── variables.tf               # Updated with new variables
│   └── README_ARGOCD_ROLLOUTS.md  # Detailed Terraform docs
├── kustomize/components/cluster-utilities/
│   ├── kustomization.yaml         # Alternative Kustomize config
│   ├── argocd-*.yaml             # ArgoCD resources
│   ├── argo-rollouts-*.yaml      # Argo Rollouts resources
│   └── README.md                 # Kustomize component docs
└── CLUSTER_UTILITIES_SETUP.md    # This overview (you are here)
```

## 🔄 Next Steps

1. **Deploy your cluster** with the Terraform option
2. **Access ArgoCD** and set up your first application
3. **Convert a service** from Deployment to Rollout for progressive delivery
4. **Set up monitoring** for your rollouts
5. **Configure notifications** for deployment events

The infrastructure is now ready to support modern GitOps and progressive delivery workflows! 🎉