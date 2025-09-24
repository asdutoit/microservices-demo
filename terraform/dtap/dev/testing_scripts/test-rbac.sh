#!/bin/bash

# Comprehensive RBAC Testing Script
echo "🔐 Kubernetes RBAC Permission Testing"
echo "======================================"

# Function to test permission
test_permission() {
    local action=$1
    local resource=$2
    local namespace=${3:-""}
    local as_user=${4:-""}
    
    local cmd="kubectl auth can-i $action $resource"
    
    if [[ -n "$namespace" ]]; then
        cmd="$cmd --namespace=$namespace"
    fi
    
    if [[ -n "$as_user" ]]; then
        cmd="$cmd --as=$as_user"
    fi
    
    if eval "$cmd" >/dev/null 2>&1; then
        echo "✅ $action $resource${namespace:+ (ns: $namespace)}${as_user:+ (as: $as_user)}"
    else
        echo "❌ $action $resource${namespace:+ (ns: $namespace)}${as_user:+ (as: $as_user)}"
    fi
}

echo -e "\n📋 Core Workload Resources"
echo "-------------------------"
test_permission "get" "pods"
test_permission "create" "pods"
test_permission "delete" "pods"
test_permission "get" "deployments"
test_permission "create" "deployments"
test_permission "delete" "deployments"
test_permission "get" "services"
test_permission "create" "services"
test_permission "delete" "services"

echo -e "\n🔧 Configuration Resources"
echo "-------------------------"
test_permission "get" "configmaps"
test_permission "create" "configmaps"
test_permission "get" "secrets"
test_permission "create" "secrets"
test_permission "get" "persistentvolumes"
test_permission "create" "persistentvolumes"

echo -e "\n🏗️ Cluster Resources"
echo "-------------------"
test_permission "get" "nodes"
test_permission "get" "namespaces"
test_permission "create" "namespaces"
test_permission "get" "clusterroles"
test_permission "create" "clusterroles"

echo -e "\n👥 RBAC Resources"
echo "---------------"
test_permission "get" "roles"
test_permission "create" "roles"
test_permission "get" "rolebindings"
test_permission "create" "rolebindings"
test_permission "get" "clusterrolebindings"
test_permission "create" "clusterrolebindings"

echo -e "\n🔍 Cross-Namespace Testing"
echo "-------------------------"
test_permission "get" "pods" "default"
test_permission "get" "pods" "kube-system"
test_permission "get" "secrets" "kube-system"
test_permission "create" "configmaps" "kube-system"

echo -e "\n🎭 Impersonation Testing"
echo "----------------------"
test_permission "get" "pods" "" "system:serviceaccount:default:default"
test_permission "get" "secrets" "" "system:serviceaccount:kube-system:default"

echo -e "\n🌟 Special Permissions"
echo "--------------------"
test_permission "*" "*"
test_permission "get" "*"
test_permission "create" "*"
test_permission "delete" "*"

echo -e "\n✨ Testing completed!"