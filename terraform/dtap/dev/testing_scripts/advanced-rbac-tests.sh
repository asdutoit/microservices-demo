#!/bin/bash

echo "🔬 Advanced RBAC Testing Techniques"
echo "==================================="

echo -e "\n1️⃣ Test Resource-Specific Permissions"
echo "------------------------------------"
# Test specific resources by name
kubectl auth can-i get pod/frontend-84db48ccc8-pvw8n
kubectl auth can-i delete deployment/adservice
kubectl auth can-i patch service/frontend

echo -e "\n2️⃣ Test Subresources"
echo "-------------------"
kubectl auth can-i get pods/log
kubectl auth can-i get pods/status
kubectl auth can-i create pods/exec
kubectl auth can-i get deployments/scale

echo -e "\n3️⃣ Test API Groups"
echo "-----------------"
kubectl auth can-i get deployments.apps
kubectl auth can-i get networkpolicies.networking.k8s.io
kubectl auth can-i get ingresses.networking.k8s.io
kubectl auth can-i get horizontalpodautoscalers.autoscaling

echo -e "\n4️⃣ Test with Resource Names"
echo "--------------------------"
kubectl auth can-i get configmap/kube-root-ca.crt --namespace=default
kubectl auth can-i get secret/default-token --namespace=default

echo -e "\n5️⃣ Generate RBAC Policy (What Can I Do?)"
echo "---------------------------------------"
echo "All permissions for current user:"
kubectl auth can-i --list

echo -e "\n6️⃣ Test Service Account Token Access"
echo "-----------------------------------"
# Create a pod with our test service account
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: rbac-test-pod
  namespace: default
spec:
  serviceAccountName: rbac-test-account
  containers:
  - name: test
    image: alpine:latest
    command: ["sleep", "3600"]
EOF

echo "Pod created with rbac-test-account service account"

echo -e "\n7️⃣ Cleanup Test Resources"
echo "------------------------"
echo "To clean up test resources, run:"
echo "kubectl delete -f rbac-test-resources.yaml"
echo "kubectl delete pod rbac-test-pod"