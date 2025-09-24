#!/bin/bash

echo "🔬 ADVANCED USER TESTING METHODS"
echo "================================"

echo -e "\n🎭 METHOD 1: Testing with Hypothetical GCP Users"
echo "================================================"

# Test as if different GCP users existed
test_gcp_users() {
    echo -e "\n📧 Testing hypothetical GCP user permissions:"
    
    # Simulate different types of GCP users
    local users=(
        "developer@company.com"
        "admin@company.com"
        "intern@company.com"
        "security@company.com"
        "ci-bot@company.com"
    )
    
    for user in "${users[@]}"; do
        echo -e "\n🧪 Testing user: $user"
        printf "  %-20s: " "Can list pods"
        kubectl auth can-i get pods --as="$user" >/dev/null 2>&1 && echo "✅ ALLOWED" || echo "❌ DENIED"
        
        printf "  %-20s: " "Can create deployments"
        kubectl auth can-i create deployments --as="$user" >/dev/null 2>&1 && echo "✅ ALLOWED" || echo "❌ DENIED"
        
        printf "  %-20s: " "Can delete secrets"
        kubectl auth can-i delete secrets --as="$user" >/dev/null 2>&1 && echo "✅ ALLOWED" || echo "❌ DENIED"
    done
}

echo -e "\n🔐 METHOD 2: Testing Group-Based Access"
echo "======================================"

# Test group permissions (useful for GCP IAM groups)
test_group_access() {
    echo -e "\n👥 Testing hypothetical group permissions:"
    
    local groups=(
        "developers@company.com"
        "platform-team@company.com"
        "security-team@company.com"
        "interns@company.com"
    )
    
    for group in "${groups[@]}"; do
        echo -e "\n🏷️  Testing group: $group"
        printf "  %-25s: " "Can view all namespaces"
        kubectl auth can-i list namespaces --as-group="$group" >/dev/null 2>&1 && echo "✅ ALLOWED" || echo "❌ DENIED"
        
        printf "  %-25s: " "Can manage RBAC"
        kubectl auth can-i create roles --as-group="$group" >/dev/null 2>&1 && echo "✅ ALLOWED" || echo "❌ DENIED"
        
        printf "  %-25s: " "Can access system namespace"
        kubectl auth can-i get pods --namespace=kube-system --as-group="$group" >/dev/null 2>&1 && echo "✅ ALLOWED" || echo "❌ DENIED"
    done
}

echo -e "\n🎪 METHOD 3: Role Escalation Testing"
echo "===================================="

test_privilege_escalation() {
    echo -e "\n⚠️  Testing potential privilege escalation:"
    
    # Test if service accounts can escalate privileges
    local test_users=("viewer-user" "developer-user" "deployment-bot")
    
    for user in "${test_users[@]}"; do
        echo -e "\n🔍 Testing $user for privilege escalation:"
        
        # Can they create roles?
        printf "  %-30s: " "Create roles"
        kubectl auth can-i create roles --as="system:serviceaccount:default:$user" >/dev/null 2>&1 && echo "⚠️  POSSIBLE ESCALATION" || echo "✅ BLOCKED"
        
        # Can they bind cluster roles?
        printf "  %-30s: " "Create cluster role bindings"
        kubectl auth can-i create clusterrolebindings --as="system:serviceaccount:default:$user" >/dev/null 2>&1 && echo "⚠️  POSSIBLE ESCALATION" || echo "✅ BLOCKED"
        
        # Can they impersonate other users?
        printf "  %-30s: " "Impersonate users"
        kubectl auth can-i impersonate users --as="system:serviceaccount:default:$user" >/dev/null 2>&1 && echo "⚠️  POSSIBLE ESCALATION" || echo "✅ BLOCKED"
        
        # Can they modify service accounts?
        printf "  %-30s: " "Modify service accounts"
        kubectl auth can-i patch serviceaccounts --as="system:serviceaccount:default:$user" >/dev/null 2>&1 && echo "⚠️  POSSIBLE ESCALATION" || echo "✅ BLOCKED"
    done
}

echo -e "\n🔄 METHOD 4: Namespace Isolation Testing"
echo "========================================"

test_namespace_isolation() {
    echo -e "\n🏠 Testing namespace isolation:"
    
    # Create a test namespace for isolation testing
    kubectl create namespace rbac-test-ns --dry-run=client -o yaml | kubectl apply -f -
    
    # Test cross-namespace access
    local users=("viewer-user" "developer-user" "security-auditor")
    local namespaces=("default" "rbac-test-ns" "kube-system")
    
    for user in "${users[@]}"; do
        echo -e "\n👤 Testing $user across namespaces:"
        for ns in "${namespaces[@]}"; do
            printf "  %-15s pods in %-15s: " "Can list" "$ns"
            kubectl auth can-i list pods --namespace="$ns" --as="system:serviceaccount:default:$user" >/dev/null 2>&1 && echo "✅ YES" || echo "❌ NO"
        done
    done
    
    # Cleanup test namespace
    kubectl delete namespace rbac-test-ns --ignore-not-found >/dev/null 2>&1
}

echo -e "\n🛡️  METHOD 5: Security Context Testing"
echo "====================================="

test_security_context_access() {
    echo -e "\n🔒 Testing security-sensitive operations:"
    
    local users=("viewer-user" "developer-user" "deployment-bot" "security-auditor")
    
    for user in "${users[@]}"; do
        echo -e "\n🔍 Security tests for $user:"
        
        # Test access to sensitive resources
        printf "  %-25s: " "Read secrets"
        kubectl auth can-i get secrets --as="system:serviceaccount:default:$user" >/dev/null 2>&1 && echo "⚠️  CAN ACCESS" || echo "✅ BLOCKED"
        
        printf "  %-25s: " "Access pod logs"
        kubectl auth can-i get pods/log --as="system:serviceaccount:default:$user" >/dev/null 2>&1 && echo "⚠️  CAN ACCESS" || echo "✅ BLOCKED"
        
        printf "  %-25s: " "Execute in pods"
        kubectl auth can-i create pods/exec --as="system:serviceaccount:default:$user" >/dev/null 2>&1 && echo "⚠️  CAN EXEC" || echo "✅ BLOCKED"
        
        printf "  %-25s: " "Port forward"
        kubectl auth can-i create pods/portforward --as="system:serviceaccount:default:$user" >/dev/null 2>&1 && echo "⚠️  CAN PORT FORWARD" || echo "✅ BLOCKED"
    done
}

echo -e "\n📊 METHOD 6: Permission Audit Report"
echo "===================================="

generate_permission_report() {
    echo -e "\n📋 Generating comprehensive permission report:"
    
    local users=("viewer-user" "developer-user" "deployment-bot" "security-auditor" "log-reader")
    local critical_actions=("create" "delete" "patch" "update")
    local sensitive_resources=("secrets" "serviceaccounts" "roles" "rolebindings")
    
    echo -e "\n⚠️  CRITICAL PERMISSIONS REPORT:"
    echo "=================================="
    printf "%-15s | %-10s | %-15s | %s\\n" "USER" "ACTION" "RESOURCE" "ALLOWED"
    echo "------------------------------------------------------"
    
    for user in "${users[@]}"; do
        for action in "${critical_actions[@]}"; do
            for resource in "${sensitive_resources[@]}"; do
                if kubectl auth can-i "$action" "$resource" --as="system:serviceaccount:default:$user" >/dev/null 2>&1; then
                    printf "%-15s | %-10s | %-15s | %s\\n" "$user" "$action" "$resource" "⚠️  YES"
                fi
            done
        done
    done
    
    echo "------------------------------------------------------"
}

# Run all tests
test_gcp_users
test_group_access  
test_privilege_escalation
test_namespace_isolation
test_security_context_access
generate_permission_report

echo -e "\n🎯 ADVANCED TESTING COMPLETED!"
echo "=============================="

echo -e "\n💡 Key Insights:"
echo "• GCP users inherit your cluster-admin permissions by default"
echo "• Service accounts provide more granular control"
echo "• System namespaces are protected by GKE Warden"
echo "• Privilege escalation is generally blocked"
echo "• Cross-namespace access depends on specific RBAC rules"