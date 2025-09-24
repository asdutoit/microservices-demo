#!/bin/bash
# Complete GKE Cluster Deployment Script
# 
# This script will:
# 1. Deploy the entire infrastructure using Terraform
# 2. Wait for all services to be ready
# 3. Add cluster to kubectl context
# 4. Display all service endpoints and access information
#
# Usage: ./deploy_cluster.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="gcp-training-329013"
CLUSTER_NAME="online-boutique-dev"
REGION="europe-west4"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅ SUCCESS:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}❌ ERROR:${NC} $1"
}

log_step() {
    echo -e "${PURPLE}🚀 STEP:${NC} $1"
}

log_endpoint() {
    echo -e "${CYAN}🌐 ENDPOINT:${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if required commands exist
    local required_commands=("terraform" "kubectl" "gcloud")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "$cmd is required but not installed"
            exit 1
        fi
    done
    
    # Check if we're in the right directory
    if [[ ! -f "main.tf" ]]; then
        log_error "main.tf not found. Please run this script from the terraform/dtap/dev directory"
        exit 1
    fi
    
    # Check if gcloud is authenticated
    if ! gcloud auth list --filter="status:ACTIVE" --format="value(account)" | head -n1 > /dev/null 2>&1; then
        log_error "Please authenticate with gcloud: gcloud auth login"
        exit 1
    fi
    
    # Set project
    gcloud config set project "$PROJECT_ID" > /dev/null 2>&1 || {
        log_error "Failed to set project $PROJECT_ID"
        exit 1
    }
    
    log_success "All prerequisites met"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    log_step "Deploying infrastructure with Terraform..."
    
    # Initialize Terraform if needed
    if [[ ! -d ".terraform" ]]; then
        log_info "Initializing Terraform..."
        terraform init
    fi
    
    # Plan deployment
    log_info "Creating deployment plan..."
    terraform plan -out=tfplan
    
    # Apply deployment
    log_info "Applying Terraform configuration..."
    terraform apply tfplan
    
    # Clean up plan file
    rm -f tfplan
    
    log_success "Infrastructure deployment completed"
}

# Function to wait for LoadBalancer services to get external IPs
wait_for_loadbalancers() {
    log_step "Waiting for LoadBalancer services to get external IPs..."
    
    local services=(
        "ingress-nginx:ingress-nginx-controller"
        "argocd:argocd-server"
        "argo-rollouts:argo-rollouts-dashboard"
    )
    
    local max_wait=600  # 10 minutes max
    local wait_interval=30
    local elapsed=0
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r namespace service <<< "$service_info"
        
        log_info "Waiting for LoadBalancer IP for $service in namespace $namespace..."
        
        while [[ $elapsed -lt $max_wait ]]; do
            # Check if service exists first
            if kubectl get svc "$service" -n "$namespace" &> /dev/null; then
                external_ip=$(kubectl get svc "$service" -n "$namespace" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
                
                if [[ -n "$external_ip" && "$external_ip" != "null" ]]; then
                    log_success "$service got external IP: $external_ip"
                    break
                fi
            fi
            
            log_info "Still waiting for $service... (${elapsed}s/${max_wait}s)"
            sleep $wait_interval
            elapsed=$((elapsed + wait_interval))
        done
        
        if [[ $elapsed -ge $max_wait ]]; then
            log_warning "Timeout waiting for $service to get external IP"
        fi
    done
}

# Function to wait for pods to be ready
wait_for_pods() {
    log_step "Waiting for all pods to be ready..."
    
    local namespaces=("development" "ingress-nginx" "argocd" "argo-rollouts")
    local max_wait=900  # 15 minutes max
    local wait_interval=30
    
    for namespace in "${namespaces[@]}"; do
        log_info "Waiting for pods in namespace: $namespace"
        
        # Check if namespace exists
        if ! kubectl get namespace "$namespace" &> /dev/null; then
            log_info "Namespace $namespace doesn't exist yet, skipping..."
            continue
        fi
        
        # Wait for pods with timeout
        if ! timeout $max_wait kubectl wait --for=condition=ready pods --all -n "$namespace" --timeout=0; then
            log_warning "Some pods in $namespace may not be ready yet"
            # Show pod status for debugging
            kubectl get pods -n "$namespace"
        else
            log_success "All pods ready in namespace: $namespace"
        fi
    done
}

# Function to get cluster context
setup_kubectl_context() {
    log_step "Setting up kubectl context..."
    
    # Get cluster credentials
    gcloud container clusters get-credentials "$CLUSTER_NAME" --region="$REGION" --project="$PROJECT_ID"
    
    # Verify connection
    if kubectl cluster-info &> /dev/null; then
        local current_context=$(kubectl config current-context)
        log_success "kubectl context set to: $current_context"
    else
        log_error "Failed to connect to cluster"
        exit 1
    fi
}

# Function to get service endpoints
get_service_endpoints() {
    log_step "Retrieving service endpoints..."
    
    echo ""
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}🌐 SERVICE ENDPOINTS & ACCESS INFORMATION${NC}"
    echo -e "${CYAN}===============================================${NC}"
    
    # Function to get LoadBalancer IP
    get_lb_ip() {
        local namespace=$1
        local service=$2
        kubectl get svc "$service" -n "$namespace" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending"
    }
    
    # Get NGINX Ingress Controller
    local nginx_ip=$(get_lb_ip "ingress-nginx" "ingress-nginx-controller")
    echo ""
    log_endpoint "NGINX Ingress Controller:"
    echo "   📍 External IP: $nginx_ip"
    if [[ "$nginx_ip" != "pending" ]]; then
        echo "   🔗 Access URL: http://$nginx_ip"
    fi
    
    # Get ArgoCD
    local argocd_ip=$(get_lb_ip "argocd" "argocd-server")
    echo ""
    log_endpoint "ArgoCD Server:"
    echo "   📍 External IP: $argocd_ip"
    if [[ "$argocd_ip" != "pending" ]]; then
        echo "   🔗 Access URL: http://$argocd_ip"
        echo "   👤 Username: admin"
        
        # Try to get ArgoCD password
        local argocd_password
        if argocd_password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null); then
            echo "   🔑 Password: $argocd_password"
        else
            echo "   🔑 Password: Run 'kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d'"
        fi
    fi
    
    # Get Argo Rollouts Dashboard
    local rollouts_ip=$(get_lb_ip "argo-rollouts" "argo-rollouts-dashboard")
    echo ""
    log_endpoint "Argo Rollouts Dashboard:"
    echo "   📍 External IP: $rollouts_ip"
    if [[ "$rollouts_ip" != "pending" ]]; then
        echo "   🔗 Access URL: http://$rollouts_ip:3100"
    fi
    
    # Get Online Boutique Frontend (if available)
    echo ""
    log_endpoint "Online Boutique Application:"
    local frontend_svc=$(kubectl get svc -n development --no-headers 2>/dev/null | grep frontend || echo "")
    if [[ -n "$frontend_svc" ]]; then
        local frontend_type=$(echo "$frontend_svc" | awk '{print $2}')
        if [[ "$frontend_type" == "LoadBalancer" ]]; then
            local frontend_ip=$(kubectl get svc frontend -n development -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
            echo "   📍 External IP: $frontend_ip"
            if [[ "$frontend_ip" != "pending" ]]; then
                echo "   🔗 Access URL: http://$frontend_ip"
            fi
        else
            echo "   📍 Service Type: $frontend_type (use port-forward or ingress)"
            echo "   🔗 Port Forward: kubectl port-forward -n development svc/frontend 8080:80"
        fi
    else
        echo "   📍 Status: Deployed via ingress (use NGINX Ingress Controller IP)"
    fi
}

# Function to display cluster information
display_cluster_info() {
    echo ""
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}📋 CLUSTER INFORMATION${NC}"
    echo -e "${CYAN}===============================================${NC}"
    
    echo ""
    log_info "Cluster Details:"
    echo "   📍 Name: $CLUSTER_NAME"
    echo "   📍 Region: $REGION"
    echo "   📍 Project: $PROJECT_ID"
    echo "   📍 Type: GKE Autopilot"
    
    # Get cluster version
    local cluster_version=$(gcloud container clusters describe "$CLUSTER_NAME" --region="$REGION" --project="$PROJECT_ID" --format="value(currentMasterVersion)" 2>/dev/null || echo "unknown")
    echo "   📍 Version: $cluster_version"
    
    echo ""
    log_info "kubectl Context:"
    echo "   📍 Current Context: $(kubectl config current-context)"
    echo "   📍 Connection: $(kubectl cluster-info --request-timeout=5s | head -n1 | sed 's/Kubernetes control plane is running at //')"
    
    echo ""
    log_info "Useful Commands:"
    echo "   📝 Get all services: kubectl get svc --all-namespaces"
    echo "   📝 Get all pods: kubectl get pods --all-namespaces"
    echo "   📝 Get LoadBalancer IPs: $SCRIPT_DIR/get_loadbalancer_ips.sh"
    echo "   📝 ArgoCD password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

# Function to display next steps
display_next_steps() {
    echo ""
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}🎯 NEXT STEPS${NC}"
    echo -e "${CYAN}===============================================${NC}"
    
    echo ""
    log_info "Your cluster is ready! Here's what you can do next:"
    echo ""
    echo "   1. 🌐 Access ArgoCD to set up GitOps workflows"
    echo "   2. 🚀 Use Argo Rollouts for advanced deployment strategies"
    echo "   3. 📊 Explore the Online Boutique microservices demo"
    echo "   4. 🔧 Configure custom domains by uncommenting ingress configs"
    echo "   5. 🗑️  Clean up when done: terraform destroy"
    echo ""
    echo -e "${GREEN}🎉 Happy Kubernetes-ing!${NC}"
}

# Main execution
main() {
    echo -e "${PURPLE}===============================================${NC}"
    echo -e "${PURPLE}🚀 GKE CLUSTER DEPLOYMENT SCRIPT${NC}"
    echo -e "${PURPLE}===============================================${NC}"
    echo ""
    
    local start_time=$(date +%s)
    
    # Run all steps
    check_prerequisites
    deploy_infrastructure
    setup_kubectl_context
    wait_for_loadbalancers
    wait_for_pods
    get_service_endpoints
    display_cluster_info
    display_next_steps
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo ""
    echo -e "${GREEN}===============================================${NC}"
    echo -e "${GREEN}✅ DEPLOYMENT COMPLETED SUCCESSFULLY!${NC}"
    echo -e "${GREEN}===============================================${NC}"
    echo -e "${GREEN}⏱️  Total time: ${minutes}m ${seconds}s${NC}"
    echo ""
}

# Trap to handle interruptions
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"