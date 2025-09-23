# Quick Reference - Terraform Commands

## 🚀 Essential Commands

### Initial Setup
```bash
# Navigate to environment
cd terraform/dtap/dev

# Set your project ID
export TF_VAR_gcp_project_id="your-project-id"

# Initialize Terraform
terraform init
```

### Deploy & Manage
```bash
# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy everything
terraform destroy
```

### Connect to Cluster
```bash
# Get connection command
terraform output -raw kubectl_context_command

# Execute connection (copy/paste the output)
gcloud container clusters get-credentials online-boutique --region=us-central1 --project=your-project-id

# Or execute directly
eval $(terraform output -raw kubectl_context_command)

# Verify connection
kubectl get nodes
kubectl get pods
```

### Useful Outputs
```bash
# All outputs
terraform output

# Specific outputs
terraform output cluster_name
terraform output kubectl_context_command
terraform output connect_instructions
```

### Troubleshooting
```bash
# Refresh state
terraform refresh

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Show current state
terraform show
```

### GCP Authentication
```bash
# Login to GCP
gcloud auth login

# Set project
gcloud config set project YOUR_PROJECT_ID

# Enable application default credentials
gcloud auth application-default login

# Check current config
gcloud config list
```

### Kubectl Basics
```bash
# Get cluster info
kubectl cluster-info

# Get all resources
kubectl get all

# Get pods in all namespaces
kubectl get pods -A

# Check Online Boutique app
kubectl get pods -l app
kubectl get services
kubectl get ingress
```

## 🔧 Configuration Files

### terraform.tfvars (create this file)
```hcl
gcp_project_id = "your-project-id"
name           = "online-boutique"
region         = "us-central1"
namespace      = "default"
memorystore    = false
```

### Environment Variables
```bash
export TF_VAR_gcp_project_id="your-project-id"
export TF_VAR_region="us-central1"
export TF_VAR_name="online-boutique"
```

## ⏱️ Typical Deployment Timeline

1. **terraform init**: ~30 seconds
2. **terraform plan**: ~30 seconds  
3. **terraform apply**: ~10-15 minutes
4. **kubectl connection**: ~5 seconds
5. **terraform destroy**: ~5-10 minutes

## 🎯 Quick Deploy (One-liner)
```bash
cd terraform/dtap/dev && \
export TF_VAR_gcp_project_id="your-project-id" && \
terraform init && \
terraform apply -auto-approve
```

## 🧹 Quick Cleanup
```bash
cd terraform/dtap/dev && terraform destroy -auto-approve
```