# ArgoCD and Argo Rollouts Terraform Integration

This setup automatically deploys ArgoCD and Argo Rollouts as part of your GKE cluster infrastructure provisioning process.

## What Gets Deployed

### ArgoCD
- **Version**: Latest stable (managed via Helm chart)
- **Namespace**: `argocd`
- **Access**: LoadBalancer service + Ingress (if domain configured)
- **Features**:
  - GitOps continuous delivery platform
  - Web UI for managing applications
  - CLI access for automation
  - RBAC configuration included
  - Insecure mode enabled for development (can be changed for production)

### Argo Rollouts
- **Version**: Latest stable (managed via Helm chart) 
- **Namespace**: `argo-rollouts`
- **Access**: Dashboard available via Ingress
- **Features**:
  - Progressive delivery (Blue/Green, Canary deployments)
  - Analysis and metrics integration
  - Dashboard for rollout visualization
  - Notifications support

## Configuration

### Required Variables
The following variables are automatically configured:
- `gcp_project_id`: Your GCP project
- `name`: Cluster name
- `region`: GCP region

### Optional Variables
You can configure these in your `terraform.tfvars`:

```hcl
# Domain name for ingress resources (optional)
domain_name = "yourdomain.com"

# Custom ArgoCD admin password (optional, leave empty to use default)
argocd_admin_password = "your-secure-password"
```

## Deployment

The ArgoCD and Argo Rollouts deployment happens automatically when you provision your cluster:

```bash
# Navigate to your environment
cd terraform/dtap/dev

# Initialize and apply (ArgoCD & Argo Rollouts will be included automatically)
terraform init
terraform plan
terraform apply
```

## Access Information

After deployment, Terraform will output access information:

### ArgoCD Access
```bash
# Get ArgoCD LoadBalancer IP
kubectl get svc argocd-server -n argocd

# Get initial admin password (if not set via variable)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Access via browser
# LoadBalancer: http://<EXTERNAL-IP>
# Ingress: https://argocd.yourdomain.com (if domain configured)
```

**Default credentials:**
- Username: `admin`
- Password: Retrieved via the command above or your custom password

### Argo Rollouts Access
```bash
# Access Rollouts dashboard
# Ingress: https://rollouts.yourdomain.com (if domain configured)

# Or use kubectl plugin
kubectl argo rollouts dashboard
```

## Integration with Your Applications

### Setting up ArgoCD Applications

Once ArgoCD is deployed, you can create applications that point to your Git repositories:

1. **Via ArgoCD UI**: Navigate to the ArgoCD interface and create applications
2. **Via CLI**: Use the ArgoCD CLI to create applications
3. **Declaratively**: Create Application manifests in your Git repo

Example Application manifest for your microservices-demo:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: microservices-demo
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/yourusername/microservices-demo'
    path: kustomize
    targetRevision: HEAD
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Using Argo Rollouts in Your Applications

Replace your Deployment resources with Rollout resources:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: frontend
spec:
  replicas: 3
  strategy:
    canary:
      steps:
      - setWeight: 25
      - pause: {}
      - setWeight: 50
      - pause: {duration: 30s}
      - setWeight: 75
      - pause: {duration: 30s}
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: server
        image: gcr.io/google-samples/microservices-demo/frontend:v0.8.0
        # ... rest of your container spec
```

## Security Considerations

### For Production Environments

1. **Disable Insecure Mode**: Update ArgoCD configuration to remove `--insecure` flag
2. **Enable TLS**: Configure proper TLS certificates for ingress
3. **Configure RBAC**: Set up proper RBAC policies for your teams
4. **Use External Auth**: Configure OIDC/SAML for authentication

### Environment-Specific Configuration

For production deployments, consider:
- Using a more restrictive RBAC policy
- Enabling TLS termination at the load balancer
- Configuring monitoring and alerting
- Setting up backup and restore procedures

## Troubleshooting

### Common Issues

1. **ArgoCD not accessible**: Check LoadBalancer service status
   ```bash
   kubectl get svc -n argocd argocd-server
   ```

2. **Ingress not working**: Ensure NGINX ingress controller is running
   ```bash
   kubectl get pods -n ingress-nginx
   ```

3. **Password not working**: Reset ArgoCD admin password
   ```bash
   kubectl -n argocd patch secret argocd-secret -p '{"stringData": {"admin.password": "$2a$10$rRyBsGSHK6.uc8fntPwVIuLVHgsAhAX7TcdrqW/RADU0uh7CaChLa", "admin.passwordMtime": "'$(date +%FT%T%Z)'"}}'
   ```

### Logs and Debugging

```bash
# ArgoCD server logs
kubectl logs -n argocd deployment/argocd-server

# Argo Rollouts controller logs
kubectl logs -n argo-rollouts deployment/argo-rollouts

# Check rollout status
kubectl argo rollouts get rollout <rollout-name> -n <namespace>
```

## Next Steps

1. **Configure Repository Access**: Add your Git repositories to ArgoCD
2. **Create Applications**: Set up ArgoCD applications for your services
3. **Implement Progressive Delivery**: Convert deployments to rollouts
4. **Set up Monitoring**: Configure Prometheus/Grafana for rollout metrics
5. **Automate**: Integrate with your CI/CD pipelines

## File Structure

The ArgoCD and Argo Rollouts integration consists of:

```
terraform/dtap/dev/
├── argocd-rollouts.tf         # Main configuration
├── variables.tf               # Variables (updated with new vars)
└── README_ARGOCD_ROLLOUTS.md  # This documentation
```

This infrastructure-as-code approach ensures consistent, repeatable deployments across all your environments while maintaining the benefits of GitOps and progressive delivery.