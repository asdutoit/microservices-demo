#!/bin/bash
# Script to get all LoadBalancer IPs for the deployed services
#
# Usage: ./get_loadbalancer_ips.sh
# Or: bash get_loadbalancer_ips.sh

set -e

echo "🌐 Getting LoadBalancer IPs for all services..."
echo "=============================================="

# Function to get LoadBalancer IP
get_lb_ip() {
    local namespace=$1
    local service=$2
    local display_name=$3
    
    echo -n "Checking $display_name... "
    
    # Check if service exists
    if kubectl get svc "$service" -n "$namespace" >/dev/null 2>&1; then
        # Get the external IP
        external_ip=$(kubectl get svc "$service" -n "$namespace" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        
        if [[ -n "$external_ip" && "$external_ip" != "null" ]]; then
            echo "✅ $external_ip"
            echo "   🔗 Access at: http://$external_ip"
        else
            echo "⏳ Pending (LoadBalancer provisioning...)"
            echo "   📝 Run: kubectl get svc $service -n $namespace"
        fi
    else
        echo "❌ Service not found"
    fi
    echo
}

get_lb_ingress_ip() {
    local namespace=$1
    local ingress_name=$2
    local display_name=$3
    
    echo -n "Checking $display_name... "
    
    # Check if ingress exists
    if kubectl get ingress "$ingress_name" -n "$namespace" >/dev/null 2>&1; then
        # Get the external IP
        external_ip=$(kubectl get ingress "$ingress_name" -n "$namespace" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [[ -n "$external_ip" && "$external_ip" != "null" ]]; then
            echo "✅ $external_ip"
            echo "   🔗 Access at: http://$external_ip"
        else
            echo "⏳ Pending (LoadBalancer provisioning...)"
            echo "   📝 Run: kubectl get ingress $ingress_name -n $namespace"
        fi
    else
        echo "❌ Ingress not found"
    fi
    echo    
}

# Check cluster connectivity
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "❌ Cannot connect to Kubernetes cluster"
    echo "💡 Run: gcloud container clusters get-credentials online-boutique-dev --region=europe-west4 --project=YOUR_PROJECT_ID"
    exit 1
fi

echo "📋 Current cluster: $(kubectl config current-context)"
echo

# Get all LoadBalancer IPs
get_lb_ip "ingress-nginx" "ingress-nginx-controller" "NGINX Ingress Controller"
get_lb_ip "argocd" "argocd-server" "ArgoCD Server"
get_lb_ip "argo-rollouts" "argo-rollouts-dashboard" "Argo Rollouts Dashboard"
get_lb_ingress_ip "development" "frontend-ingress" "Frontend Service"

# Show all LoadBalancer services at once
echo "📊 All LoadBalancer Services Summary:"
echo "====================================="
kubectl get svc --all-namespaces --field-selector spec.type=LoadBalancer -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,EXTERNAL-IP:.status.loadBalancer.ingress[0].ip,PORTS:.spec.ports[*].port"

echo
echo "📊 All Ingresses Summary:"
kubectl get ingress --all-namespaces -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,EXTERNAL-IP:.status.loadBalancer.ingress[0].ip"

echo
echo "💡 Tips:"
echo "  • ArgoCD default login: admin / (get password with: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
echo "  • Use --insecure flag or http:// for development access"
echo "  • LoadBalancer IPs may take 2-3 minutes to provision on first deployment"