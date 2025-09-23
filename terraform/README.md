# Terraform Infrastructure for Online Boutique

This directory contains Terraform configurations for deploying the Google Cloud microservices demo application (Online Boutique) on Google Kubernetes Engine (GKE).

## 📁 Directory Structure

```
terraform/
├── README.md                    # This file
├── dtap/                        # Environment-specific configurations
│   └── dev/                     # Development environment
│       ├── data.tf              # Data sources
│       ├── main.tf              # Main configuration
│       ├── output.tf            # Output values
│       ├── provider.tf          # Provider configuration
│       ├── roles.tf             # IAM roles and permissions
│       ├── state.tf             # Terraform state configuration
│       └── variables.tf         # Variable definitions
└── src/                         # Reusable modules
    └── modules/
        ├── enable_google_apis/  # Module to enable required GCP APIs
        ├── kubernetes_cluster/  # GKE cluster and app deployment
        └── vpc/                 # VPC network configuration
```

## 🔧 Prerequisites

Before you can deploy this infrastructure, ensure you have the following:

### Required Tools

1. **Terraform** (v1.0 or later)

   ```bash
   # Install via Homebrew (macOS)
   brew tap hashicorp/tap
   brew install hashicorp/tap/terraform

   # Verify installation
   terraform --version
   ```

2. **Google Cloud SDK**

   ```bash
   # Install via Homebrew (macOS)
   brew install google-cloud-sdk

   # Verify installation
   gcloud --version
   ```

3. **kubectl**

   ```bash
   # Install via Homebrew (macOS)
   brew install kubectl

   # Verify installation
   kubectl version --client
   ```

### GCP Setup

1. **Google Cloud Project**

   - Create or use an existing GCP project
   - Note your project ID

2. **Authentication**

   ```bash
   # Login to Google Cloud
   gcloud auth login

   # Set your project
   gcloud config set project YOUR_PROJECT_ID

   # Enable application default credentials
   gcloud auth application-default login
   ```

3. **Required Permissions**
   Your account needs the following IAM roles:
   - `Kubernetes Engine Admin`
   - `Compute Network Admin`
   - `Service Account Admin`
   - `Project IAM Admin`

## 🚀 Getting Started

### Step 1: Clone and Navigate

```bash
git clone https://github.com/asdutoit/microservices-demo.git
cd /path/to/microservices-demo/terraform/dtap/dev
```

### Step 2: Configure Variables

Create a `terraform.tfvars` file or export environment variables:

```bash
# Option 1: Create terraform.tfvars file
echo 'gcp_project_id = "your-project-id"' > terraform.tfvars

# Option 2: Export environment variable
export TF_VAR_gcp_project_id="your-project-id"
```

### Step 3: Initialize Terraform

```bash
terraform init
```

This will:

- Download required providers
- Initialize the backend
- Download modules

### Step 4: Plan the Deployment

```bash
terraform plan
```

Review the planned changes to ensure everything looks correct.

### Step 5: Deploy the Infrastructure

```bash
terraform apply
```

Type `yes` when prompted. This will:

- Enable required GCP APIs
- Create VPC network and subnet
- Deploy GKE Autopilot cluster
- Deploy the Online Boutique application
- Wait for all pods to be ready

⏱️ **Note**: Initial deployment takes approximately 10-15 minutes.

## 🔌 Connecting to Your Cluster

After deployment, get the kubectl connection command:

### Option 1: Get Connection Instructions

```bash
terraform output connect_instructions
```

### Option 2: Get Raw Command

```bash
terraform output -raw kubectl_context_command
```

### Option 3: Execute Directly

```bash
# Execute the connection command
eval $(terraform output -raw kubectl_context_command)

# Verify connection
kubectl get nodes
kubectl get pods
```

## 📊 Available Outputs

| Output                    | Description                          |
| ------------------------- | ------------------------------------ |
| `cluster_name`            | Name of the GKE cluster              |
| `cluster_location`        | Region where the cluster is deployed |
| `kubectl_context_command` | Command to set kubectl context       |
| `kubectl_config_info`     | Structured cluster information       |
| `connect_instructions`    | Complete connection guide            |

## 🛠️ Configuration Options

### Environment Variables

| Variable         | Description                      | Default           |
| ---------------- | -------------------------------- | ----------------- |
| `gcp_project_id` | GCP Project ID                   | _Required_        |
| `name`           | Cluster and resource name prefix | `online-boutique` |
| `region`         | GCP region for deployment        | `us-central1`     |
| `namespace`      | Kubernetes namespace             | `default`         |
| `memorystore`    | Enable Cloud Memorystore Redis   | `false`           |

### Customizing the Deployment

Edit `variables.tf` to modify:

- Cluster region
- Resource naming
- Enable/disable Memorystore
- Change application namespace

## 🔍 Troubleshooting

### Common Issues

1. **Authentication Errors**

   ```bash
   # Re-authenticate
   gcloud auth application-default login
   ```

2. **API Not Enabled Errors**

   ```bash
   # Enable APIs manually if needed
   gcloud services enable container.googleapis.com
   gcloud services enable compute.googleapis.com
   ```

3. **Permission Errors**

   - Verify your account has the required IAM roles
   - Check project permissions

4. **Terraform State Issues**
   ```bash
   # Refresh state
   terraform refresh
   ```

### Getting Help

```bash
# View Terraform help
terraform --help

# View resource documentation
terraform providers

# Check kubectl context
kubectl config get-contexts
```

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted. This will remove all created resources and avoid ongoing charges.

⚠️ **Warning**: This will permanently delete your cluster and all data. Make sure to backup any important data first.

## 🏗️ Architecture

This Terraform configuration deploys:

- **VPC Network**: Custom network with private subnets
- **GKE Autopilot Cluster**: Fully managed Kubernetes cluster
- **Online Boutique**: 11 microservices demo application
- **Load Balancer**: External access to the frontend service

The infrastructure follows Google Cloud best practices:

- Private cluster with authorized networks
- Automatic scaling and management
- Security policies and network isolation
- Resource optimization

## 📚 Additional Resources

- [Online Boutique Documentation](../README.md)
- [GKE Autopilot Documentation](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

**Happy deploying!** 🎉
