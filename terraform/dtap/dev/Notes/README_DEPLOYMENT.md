# 🚀 GKE Cluster Deployment Scripts

This directory contains automated scripts for deploying and managing your complete GKE Autopilot cluster with all platform services.

## 📋 Scripts Overview

| Script                    | Purpose                          | Usage                       |
| ------------------------- | -------------------------------- | --------------------------- |
| `deploy_cluster.sh`       | **Complete cluster deployment**  | `./deploy_cluster.sh`       |
| `destroy_cluster.sh`      | **Complete cluster destruction** | `./destroy_cluster.sh`      |
| `get_loadbalancer_ips.sh` | **Get service endpoints**        | `./get_loadbalancer_ips.sh` |

## 🚀 Quick Start

### Deploy Everything

```bash
./deploy_cluster.sh
```

This single command will:

- ✅ Check prerequisites (terraform, kubectl, gcloud)
- ✅ Deploy infrastructure with Terraform
- ✅ Wait for all services to be ready
- ✅ Setup kubectl context
- ✅ Display all service endpoints
- ✅ Show next steps and useful commands

### Destroy Everything

```bash
./destroy_cluster.sh
```

This will:

- ⚠️ Confirm destruction (safety check)
- ✅ Destroy all infrastructure
- ✅ Clean up kubectl contexts
- ✅ Verify complete cleanup

## 🌐 What Gets Deployed

### Infrastructure

- **GKE Autopilot Cluster** (`online-boutique-dev`)
- **Custom VPC & Networking** (10.0.0.0/16)
- **Platform RBAC** (team-based access control)

### Platform Services (all with Public IPs)

- **NGINX Ingress Controller** - LoadBalancer on port 80/443
- **ArgoCD Server** - GitOps deployment management
- **Argo Rollouts Dashboard** - Advanced deployment strategies

### Applications

- **Online Boutique** - Complete microservices demo (12 services)
- **Load Generator** - For testing and demos

## 🌐 Service Endpoints

After deployment, you'll get public IP addresses for:

| Service                 | Port    | Purpose                    |
| ----------------------- | ------- | -------------------------- |
| NGINX Ingress           | 80, 443 | General ingress controller |
| ArgoCD Server           | 80, 443 | GitOps management UI       |
| Argo Rollouts Dashboard | 3100    | Advanced deployment UI     |

### ArgoCD Access

- **URL**: `http://<argocd-loadbalancer-ip>`
- **Username**: `admin`
- **Password**: Retrieved automatically and displayed

## 📝 Prerequisites

Before running the scripts, ensure you have:

1. **Required Tools**:

   ```bash
   # Install if missing
   brew install terraform kubectl
   curl https://sdk.cloud.google.com | bash  # gcloud CLI
   ```

2. **GCP Authentication**:

   ```bash
   gcloud auth login
   gcloud config set project gcp-training-329013
   ```

3. **Directory**: Run scripts from `terraform/dtap/dev/`

## ⏱️ Deployment Timeline

| Phase             | Duration       | Description                  |
| ----------------- | -------------- | ---------------------------- |
| Infrastructure    | ~8-12 min      | GKE cluster, VPC, APIs       |
| Platform Services | ~5-8 min       | NGINX, ArgoCD, Argo Rollouts |
| LoadBalancer IPs  | ~2-5 min       | External IP assignment       |
| Application Pods  | ~3-5 min       | Online Boutique deployment   |
| **Total**         | **~15-25 min** | Complete end-to-end          |

## 🔧 Advanced Configuration

### Custom Domain Support

To use custom domains instead of public IPs:

1. Edit `argocd-rollouts.tf`
2. Uncomment the ingress configurations
3. Set the `domain_name` variable
4. Redeploy: `./deploy_cluster.sh`

### Resource Customization

Edit these files for customization:

- `variables.tf` - Environment settings
- `argocd-rollouts.tf` - Service configurations
- `main.tf` - Module parameters

## 🆘 Troubleshooting

### Common Issues

1. **"terraform not found"**

   ```bash
   brew install terraform
   ```

2. **"gcloud authentication required"**

   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

3. **LoadBalancer IP pending**

   - Wait 2-5 minutes for GCP to assign IPs
   - Check with: `./get_loadbalancer_ips.sh`

4. **Pods not ready**
   - Check pod status: `kubectl get pods --all-namespaces`
   - View logs: `kubectl logs -n <namespace> <pod-name>`

### Recovery Commands

```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Get service endpoints
./get_loadbalancer_ips.sh

# Reset kubectl context
gcloud container clusters get-credentials online-boutique-dev --region=europe-west4

# Terraform state issues
terraform init
terraform plan
```

## 💰 Cost Management

### Active Resources (when deployed)

- GKE Autopilot nodes (variable based on workload)
- LoadBalancer services (3x ~$18/month each)
- Persistent storage (minimal)

### Cost Optimization

- **Autopilot clusters** only charge for running pod resources
- **Automatic scaling** reduces waste
- **Destroy when not needed**: `./destroy_cluster.sh`

## 🎯 Next Steps

After successful deployment:

1. **Explore ArgoCD** - Set up GitOps workflows
2. **Try Argo Rollouts** - Canary/blue-green deployments
3. **Access Online Boutique** - Test the microservices
4. **Configure monitoring** - Add observability tools
5. **Clean up** - Run `./destroy_cluster.sh` when done
