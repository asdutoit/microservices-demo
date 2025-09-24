# 🔒 GKE Autopilot Cluster Restrictions Report

## Overview
Your cluster is running **GKE Autopilot**, which applies several managed restrictions and security policies. You have **cluster-admin** permissions for most operations, but Google's **GKE Warden** system enforces security constraints.

---

## 1️⃣ **Namespace-Level Restrictions**

### ❌ **GKE Managed Namespace Limitations**
**Error Pattern:** `GKE Warden authz [denied by managed-namespaces-limitation]`

**Affected Namespaces:**
- `kube-system`
- `gke-gmp-system` (Google Managed Prometheus)
- `gke-managed-cim` (Container Image Management)
- `gke-managed-system`
- `gke-managed-parallelstorecsi`

**Restricted Operations:**
- ❌ `CREATE` any resources
- ❌ `DELETE` any resources  
- ❌ `UPDATE/PATCH` any resources
- ✅ `GET/LIST/WATCH` allowed

**Impact:** You can view system resources but cannot modify Google-managed namespaces.

---

## 2️⃣ **Security Context Restrictions**

### ❌ **Privileged Containers Blocked**
**Constraint:** `[denied by autogke-disallow-privilege]`
```yaml
# ❌ BLOCKED
securityContext:
  privileged: true
```

### ❌ **Host Network Access Denied**
**Constraint:** `[denied by autogke-disallow-hostnamespaces]`
```yaml
# ❌ BLOCKED
spec:
  hostNetwork: true
  hostPID: true
  hostIPC: true
```

### ❌ **Host Path Volume Restrictions**
**Constraint:** `[denied by autogke-no-write-mode-hostpath]`
```yaml
# ❌ BLOCKED (write access to host paths)
volumes:
- name: host-vol
  hostPath:
    path: /var/lib
```

### ✅ **Allowed Security Contexts**
```yaml
# ✅ ALLOWED
securityContext:
  runAsUser: 1000
  runAsNonRoot: true
  readOnlyRootFilesystem: true
```

---

## 3️⃣ **Resource Management**

### ✅ **Autopilot Resource Defaults**
- Automatic resource requests/limits applied
- Warning: `autopilot-default-resources-mutator`
- High resource requests (8Gi RAM, 4000m CPU) are **allowed**

### ✅ **Resource Quotas Present**
```
NAMESPACE               QUOTA              USAGE
kube-system            gcp-critical-pods   pods: 37/1G
gke-managed-cim        gcp-critical-pods   pods: 1/1G
```

---

## 4️⃣ **Workload Restrictions**

### ✅ **Allowed Workload Types**
- ✅ Pods (with security restrictions)
- ✅ Deployments  
- ✅ Services
- ✅ ConfigMaps/Secrets
- ✅ DaemonSets
- ✅ PriorityClasses

### 🟡 **Managed by Autopilot**
- Node management
- Pod resource allocation
- Cluster autoscaling
- System component management

---

## 5️⃣ **RBAC Restrictions**

### ✅ **Your Permissions (cluster-admin)**
- Full access to user namespaces (`default`, custom namespaces)
- Create/delete/modify all resource types
- Cross-namespace access
- Cluster-level resources (nodes, clusterroles, etc.)

### ❌ **Service Account Impersonation Limitations**
- Limited impersonation capabilities for service accounts
- Some service accounts may have restricted permissions

---

## 6️⃣ **GKE Warden Enforcement**

**Admission Webhook:** `warden-validating.common-webhooks.networking.gke.io`

**Active Constraints:**
1. `autogke-disallow-privilege` - Blocks privileged containers
2. `autogke-disallow-hostnamespaces` - Blocks host network access
3. `autogke-no-write-mode-hostpath` - Blocks writable host path volumes
4. `managed-namespaces-limitation` - Protects system namespaces

---

## 7️⃣ **Workarounds & Best Practices**

### ✅ **Working with Restrictions**
```yaml
# Use non-privileged containers
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: app
    image: myapp:latest
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
```

### ✅ **Alternative Storage Options**
- Use `emptyDir`, `configMap`, `secret` volumes
- Use `persistentVolumeClaims` for persistent storage
- Avoid `hostPath` volumes

### ✅ **Network Security**
- Use standard Kubernetes networking (Services, Ingress)
- Avoid `hostNetwork: true`
- Use NetworkPolicies for micro-segmentation

---

## 🎯 **Summary**

**Your Access Level:** **Cluster Admin** (with GKE Autopilot restrictions)

**Key Limitations:**
1. **No modification** of Google-managed system namespaces
2. **No privileged containers** or host-level access
3. **Security-first approach** enforced by GKE Warden
4. **Automatic resource management** by Autopilot

**Recommendation:** Work within the security constraints - they're designed to provide a secure, managed Kubernetes experience while still allowing full application deployment capabilities.