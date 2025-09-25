#!/bin/bash
# Complete GKE Cluster Destruction Script
# 
# This script will:
# 1. Safely destroy all infrastructure using Terraform
# 2. Clean up kubectl context
# 3. Confirm complete cleanup
#
# Usage: ./destroy_cluster.sh

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
CLUSTER_NAME="online-boutique"
REGION="europe-west4"

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
    
    log_success "All prerequisites met"
}

# Function to confirm destruction
confirm_destruction() {
    echo ""
    echo -e "${YELLOW}===============================================${NC}"
    echo -e "${YELLOW}⚠️  CLUSTER DESTRUCTION WARNING${NC}"
    echo -e "${YELLOW}===============================================${NC}"
    echo ""
    log_warning "This will permanently destroy the following resources:"
    echo "   🗑️  GKE Autopilot cluster: $CLUSTER_NAME"
    echo "   🗑️  All LoadBalancer services and IPs"
    echo "   🗑️  Custom VPC and networking"
    echo "   🗑️  All deployed applications and data"
    echo ""
    echo -e "${RED}⚠️  THIS ACTION CANNOT BE UNDONE!${NC}"
    echo ""
    
    read -p "Are you sure you want to destroy the cluster? (type 'yes' to confirm): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        log_info "Destruction cancelled by user"
        exit 0
    fi
    
    log_info "Destruction confirmed. Proceeding..."
}

# Function to destroy infrastructure
destroy_infrastructure() {
    log_step "Destroying infrastructure with Terraform..."
    
    # Check if terraform state exists
    if [[ ! -f ".terraform/terraform.tfstate" ]] && [[ ! -f "terraform.tfstate" ]]; then
        log_warning "No Terraform state found. Infrastructure may already be destroyed."
        return 0
    fi
    
    # Create destruction plan
    log_info "Creating destruction plan..."
    if ! terraform plan -destroy -out=destroy-plan; then
        log_error "Failed to create destruction plan"
        exit 1
    fi
    
    # Apply destruction
    log_info "Applying destruction plan..."
    if ! terraform apply destroy-plan; then
        log_error "Failed to apply destruction plan"
        exit 1
    fi
    
    # Clean up plan file
    rm -f destroy-plan
    
    log_success "Infrastructure destruction completed"
}

# Function to clean up kubectl context
cleanup_kubectl_context() {
    log_step "Cleaning up kubectl context..."
    
    local context_name="gke_${PROJECT_ID}_${REGION}_${CLUSTER_NAME}"
    
    # Check if context exists
    if kubectl config get-contexts "$context_name" &> /dev/null; then
        # Delete the context
        kubectl config delete-context "$context_name" &> /dev/null || true
        log_success "kubectl context removed: $context_name"
    else
        log_info "kubectl context not found or already removed"
    fi
    
    # Remove cluster from kubeconfig
    if kubectl config get-clusters "$context_name" &> /dev/null; then
        kubectl config delete-cluster "$context_name" &> /dev/null || true
        log_success "kubectl cluster config removed"
    fi
    
    # Remove user from kubeconfig
    if kubectl config get-users "$context_name" &> /dev/null; then
        kubectl config delete-user "$context_name" &> /dev/null || true
        log_success "kubectl user config removed"
    fi
}

# Function to verify cleanup
verify_cleanup() {
    log_step "Verifying cleanup..."
    
    # Check if cluster still exists
    log_info "Checking for remaining clusters..."
    local clusters=$(gcloud container clusters list --project="$PROJECT_ID" --format="value(name)" 2>/dev/null || echo "")
    
    if [[ -z "$clusters" ]]; then
        log_success "No clusters found in project $PROJECT_ID"
    else
        log_warning "Found remaining clusters: $clusters"
    fi
    
    # Check if custom networks still exist
    log_info "Checking for custom networks..."
    local networks=$(gcloud compute networks list --project="$PROJECT_ID" --filter="name!~default" --format="value(name)" 2>/dev/null || echo "")
    
    if [[ -z "$networks" ]]; then
        log_success "No custom networks found in project $PROJECT_ID"
    else
        log_warning "Found remaining custom networks: $networks"
    fi
    
    # Check Terraform state
    log_info "Checking Terraform state..."
    local resources=$(terraform state list 2>/dev/null || echo "")
    
    if [[ -z "$resources" ]]; then
        log_success "Terraform state is clean"
    else
        log_warning "Terraform state still contains resources:"
        echo "$resources"
    fi
}

# Function to display cleanup summary
display_cleanup_summary() {
    echo ""
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${CYAN}📋 CLEANUP SUMMARY${NC}"
    echo -e "${CYAN}===============================================${NC}"
    
    echo ""
    log_info "Resources cleaned up:"
    echo "   ✅ GKE Autopilot cluster destroyed"
    echo "   ✅ LoadBalancer services and IPs released"
    echo "   ✅ Custom VPC and subnets removed"
    echo "   ✅ kubectl context cleaned up"
    echo "   ✅ Terraform state cleared"
    
    echo ""
    log_info "Current status:"
    echo "   💰 No billable resources remaining"
    echo "   🏗️  Infrastructure ready for redeployment"
    echo "   🧹 Clean slate achieved"
    
    echo ""
    log_info "To redeploy:"
    echo "   📝 Run: ./deploy_cluster.sh"
}

# Main execution
main() {
    echo -e "${PURPLE}===============================================${NC}"
    echo -e "${PURPLE}🗑️  GKE CLUSTER DESTRUCTION SCRIPT${NC}"
    echo -e "${PURPLE}===============================================${NC}"
    echo ""
    
    local start_time=$(date +%s)
    
    # Run all steps
    check_prerequisites
    confirm_destruction
    destroy_infrastructure
    cleanup_kubectl_context
    verify_cleanup
    display_cleanup_summary
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo ""
    echo -e "${GREEN}===============================================${NC}"
    echo -e "${GREEN}✅ DESTRUCTION COMPLETED SUCCESSFULLY!${NC}"
    echo -e "${GREEN}===============================================${NC}"
    echo -e "${GREEN}⏱️  Total time: ${minutes}m ${seconds}s${NC}"
    echo ""
}

# Trap to handle interruptions
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"