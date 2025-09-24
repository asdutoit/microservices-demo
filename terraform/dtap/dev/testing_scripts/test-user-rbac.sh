#!/bin/bash

echo "🎭 COMPREHENSIVE RBAC USER TESTING"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to test user permissions
test_user_permission() {
    local user_sa=$1
    local action=$2
    local resource=$3
    local namespace=${4:-"default"}
    local description=$5
    
    local sa_full="system:serviceaccount:${namespace}:${user_sa}"
    
    if kubectl auth can-i $action $resource --as=$sa_full --namespace=$namespace >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $description${NC}"
        return 0
    else
        echo -e "${RED}❌ $description${NC}"
        return 1
    fi
}

# Function to test and show detailed permission results
show_permission_test() {
    local user_sa=$1
    local action=$2
    local resource=$3
    local namespace=${4:-"default"}
    
    local sa_full="system:serviceaccount:${namespace}:${user_sa}"
    
    printf "%-15s %-8s %-15s: " "$user_sa" "$action" "$resource"
    if kubectl auth can-i $action $resource --as=$sa_full --namespace=$namespace >/dev/null 2>&1; then
        echo -e "${GREEN}ALLOWED${NC}"
    else
        echo -e "${RED}DENIED${NC}"
    fi
}

echo -e "\n${BLUE}📋 1. VIEWER USER TESTS (Read-only access)${NC}"
echo "================================================"

echo -e "\n${YELLOW}Testing viewer-user permissions:${NC}"
test_user_permission "viewer-user" "get" "pods" "default" "Can view pods in default namespace"
test_user_permission "viewer-user" "list" "services" "default" "Can list services"
test_user_permission "viewer-user" "get" "secrets" "default" "Can view secrets"
test_user_permission "viewer-user" "create" "pods" "default" "Can create pods (should be DENIED)"
test_user_permission "viewer-user" "delete" "deployments" "default" "Can delete deployments (should be DENIED)"
test_user_permission "viewer-user" "get" "pods" "kube-system" "Can view pods in kube-system"

echo -e "\n${BLUE}👨‍💻 2. DEVELOPER USER TESTS (Full namespace access)${NC}"
echo "====================================================="

echo -e "\n${YELLOW}Testing developer-user permissions:${NC}"
test_user_permission "developer-user" "get" "pods" "default" "Can view pods"
test_user_permission "developer-user" "create" "deployments" "default" "Can create deployments"
test_user_permission "developer-user" "delete" "services" "default" "Can delete services"
test_user_permission "developer-user" "update" "configmaps" "default" "Can update configmaps"
test_user_permission "developer-user" "create" "pods" "kube-system" "Can create pods in kube-system (should be DENIED)"
test_user_permission "developer-user" "get" "nodes" "" "Can view cluster nodes"

echo -e "\n${BLUE}🤖 3. DEPLOYMENT BOT TESTS (CI/CD permissions)${NC}"
echo "==============================================="

echo -e "\n${YELLOW}Testing deployment-bot permissions:${NC}"
test_user_permission "deployment-bot" "create" "deployments" "default" "Can deploy applications"
test_user_permission "deployment-bot" "update" "services" "default" "Can update services"
test_user_permission "deployment-bot" "get" "pods" "default" "Can check pod status"
test_user_permission "deployment-bot" "delete" "secrets" "default" "Can delete secrets"
test_user_permission "deployment-bot" "create" "namespaces" "" "Can create namespaces (should be DENIED)"
test_user_permission "deployment-bot" "get" "nodes" "" "Can view nodes (should be DENIED)"

echo -e "\n${BLUE}🔒 4. SECURITY AUDITOR TESTS (Cross-namespace read)${NC}"
echo "=================================================="

echo -e "\n${YELLOW}Testing security-auditor permissions:${NC}"
test_user_permission "security-auditor" "list" "secrets" "default" "Can list secrets in default"
test_user_permission "security-auditor" "list" "secrets" "kube-system" "Can list secrets in kube-system"
test_user_permission "security-auditor" "get" "roles" "default" "Can view RBAC roles"
test_user_permission "security-auditor" "list" "clusterroles" "" "Can list cluster roles"
test_user_permission "security-auditor" "get" "nodes" "" "Can view cluster nodes"
test_user_permission "security-auditor" "create" "pods" "default" "Can create pods (should be DENIED)"
test_user_permission "security-auditor" "delete" "secrets" "default" "Can delete secrets (should be DENIED)"

echo -e "\n${BLUE}📝 5. LOG READER TESTS (Minimal access)${NC}"
echo "========================================="

echo -e "\n${YELLOW}Testing log-reader permissions:${NC}"
test_user_permission "log-reader" "get" "pods" "default" "Can view pods"
test_user_permission "log-reader" "get" "pods/log" "default" "Can read pod logs"
test_user_permission "log-reader" "list" "pods" "default" "Can list pods"
test_user_permission "log-reader" "create" "pods" "default" "Can create pods (should be DENIED)"
test_user_permission "log-reader" "get" "services" "default" "Can view services (should be DENIED)"
test_user_permission "log-reader" "get" "secrets" "default" "Can view secrets (should be DENIED)"

echo -e "\n${BLUE}📊 6. PERMISSION MATRIX${NC}"
echo "========================"

echo -e "\n${YELLOW}Permission matrix across all test users:${NC}"
printf "%-15s %-8s %-15s   %s\n" "USER" "ACTION" "RESOURCE" "RESULT"
echo "--------------------------------------------------------"

# Test matrix
users=("viewer-user" "developer-user" "deployment-bot" "security-auditor" "log-reader")
actions=("get" "create" "delete")
resources=("pods" "services" "secrets")

for user in "${users[@]}"; do
    for action in "${actions[@]}"; do
        for resource in "${resources[@]}"; do
            show_permission_test "$user" "$action" "$resource" "default"
        done
    done
    echo "--------------------------------------------------------"
done

echo -e "\n${BLUE}🔄 7. CROSS-NAMESPACE TESTING${NC}"
echo "================================"

echo -e "\n${YELLOW}Testing cross-namespace access:${NC}"
namespaces=("default" "kube-system")

for ns in "${namespaces[@]}"; do
    echo -e "\n${YELLOW}Namespace: $ns${NC}"
    test_user_permission "viewer-user" "get" "pods" "$ns" "viewer-user can view pods in $ns"
    test_user_permission "developer-user" "create" "pods" "$ns" "developer-user can create pods in $ns"
    test_user_permission "security-auditor" "list" "secrets" "$ns" "security-auditor can list secrets in $ns"
done

echo -e "\n${GREEN}🎯 TESTING COMPLETED!${NC}"
echo "======================"

echo -e "\n${YELLOW}📋 Summary of Test Users Created:${NC}"
kubectl get serviceaccounts -o custom-columns=NAME:.metadata.name,DESCRIPTION:.metadata.annotations.description | grep -E "(viewer-user|developer-user|deployment-bot|security-auditor|log-reader)"

echo -e "\n${YELLOW}🔧 To cleanup test resources:${NC}"
echo "kubectl delete -f rbac-test-users.yaml"