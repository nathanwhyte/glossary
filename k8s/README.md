# Glossary Application - Kubernetes Deployment

This directory contains Kubernetes manifests for deploying the Glossary Elixir/Phoenix application.

## Directory Structure

Manifests are organized into subdirectories:
- **`glossary/`** - Application deployment manifests (Deployment, Service, PVC, Ingress, Cloudflare Tunnel)
- **`postgres/`** - PostgreSQL database manifests (StatefulSet, Service, PVC)
- **Root** - Namespace definition, shared ConfigMap (`configmap.yaml`), shared Secrets template (`secrets.yaml.template`), and this README

**Note**: Both the application and PostgreSQL share the same ConfigMap (`glossary-config`) and Secret (`glossary-secrets`) from the root directory.

## Overview

The deployment includes:
- **Deployment**: Main application pods with persistent storage
- **Service**: Internal ClusterIP service exposing the application
- **PVC**: Persistent volume claim using `longhorn-nvme` StorageClass (10Gi)
- **ConfigMap**: Non-sensitive application configuration
- **Secrets**: Sensitive configuration (database, secrets)
- **PostgreSQL**: Single replica PostgreSQL StatefulSet with persistent storage
- **Cloudflare Tunnel**: Optional secure external access via Cloudflare

## Prerequisites

- Kubernetes cluster with `longhorn-nvme` StorageClass available
- `kubectl` configured to access your cluster
- Docker image built and available (update `glossary:latest` in glossary/deployment.yaml)
- (Optional) Cloudflare Zero Trust account for tunnel setup

## Quick Start

### 1. Create Namespace

```bash
kubectl create namespace glossary
```

### 2. Deploy PostgreSQL

First, set up the shared ConfigMap and Secrets (used by both PostgreSQL and the application):

```bash
# Create shared secret with PostgreSQL password and application secrets
# Generate SECRET_KEY_BASE first
mix phx.gen.secret

# Create the shared secret (includes both PostgreSQL and application secrets)
kubectl create secret generic glossary-secrets \
  --from-literal=POSTGRES_PASSWORD='your-secure-password' \
  --from-literal=DATABASE_URL='ecto://postgres:your-secure-password@postgres:5432/glossary' \
  --from-literal=SECRET_KEY_BASE='your-generated-secret-key-base' \
  -n glossary
```

Or copy `secrets.yaml.template` to `secrets.yaml`, fill in the base64-encoded values, and apply:

```bash
# Copy the template
cp k8s/secrets.yaml.template k8s/secrets.yaml

# Encode values
echo -n "your-secure-password" | base64
echo -n "ecto://postgres:your-password@postgres:5432/glossary" | base64
echo -n "your-secret-key-base" | base64

# Edit secrets.yaml with encoded values, then:
kubectl apply -f k8s/secrets.yaml

# Important: Add secrets.yaml to .gitignore to prevent committing secrets
```

Then deploy PostgreSQL:

```bash
kubectl apply -f postgres/statefulset.yaml
kubectl apply -f postgres/service.yaml
# Note: StatefulSet automatically creates PVCs via volumeClaimTemplate
```

**Note**:
- PostgreSQL uses the shared `glossary-config` ConfigMap and `glossary-secrets` Secret from the root directory.
- The StatefulSet provides better pod identity and ordered restarts, but still uses a single replica. See the "Replicas" section in Customization for limitations and alternatives.

Wait for PostgreSQL to be ready:

```bash
kubectl wait --for=condition=ready pod -l app=db -n glossary --timeout=300s
```

### 3. Update Configuration

Edit `configmap.yaml` in the root directory and update:
- `PHX_HOST`: Your application's hostname (e.g., `glossary.example.com`)
- `PORT`: Application port (default: 4000)
- `POOL_SIZE`: Database connection pool size (default: 10)

**Note**: The DATABASE_URL uses `postgres` as the hostname, which is the Kubernetes service name. This allows the application to connect to the database within the cluster.

### 4. Update Docker Image

Edit `glossary/deployment.yaml` and update the image reference:

```yaml
image: your-registry/glossary:v1.0.0
imagePullPolicy: IfNotPresent
```

**Note**: For production, use specific version tags (e.g., `v1.0.0`) instead of `latest`, and set `imagePullPolicy: IfNotPresent` for better reproducibility and rollback capabilities. The current configuration uses `latest` with `Always` for development convenience.

### 5. Deploy Application

```bash
# Apply shared ConfigMap and Secrets (if not already applied)
kubectl apply -f configmap.yaml
# Note: Create secrets.yaml from secrets.yaml.template first, or use kubectl create secret
kubectl apply -f secrets.yaml  # Only if you've created this from the template

# Apply application manifests
kubectl apply -f glossary/pvc.yaml
kubectl apply -f glossary/deployment.yaml
kubectl apply -f glossary/service.yaml
kubectl apply -f glossary/ingress.yaml  # Optional: if using Ingress instead of Cloudflare Tunnel
```

### 6. Verify Deployment

```bash
# Check pods
kubectl get pods -l app=web -n glossary

# Check service
kubectl get svc glossary -n glossary

# Check logs
kubectl logs -l app=web -n glossary -f
```

## Cloudflare Tunnel Setup (Optional)

The Cloudflare tunnel provides secure external access without exposing ports directly.

### 1. Create Tunnel in Cloudflare

1. Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Navigate to **Networks** → **Tunnels**
3. Click **Create a tunnel**
4. Choose **Cloudflared** as the connector
5. Give it a name (e.g., `glossary-tunnel`)
6. Copy the token provided

### 2. Create Tunnel Secret

Create the secret using kubectl (recommended approach):

```bash
# Create secret directly (no base64 encoding needed)
kubectl create secret generic glossary-cloudflared-token \
  --from-literal=TOKEN='your-cloudflare-token-here' \
  -n glossary
```

**Note**: The secret should never be committed to version control. Always create it using `kubectl` as shown above.

### 3. Configure Tunnel Routing

In the Cloudflare Zero Trust dashboard:
1. Go to your tunnel's configuration
2. Add a **Public Hostname**:
   - **Subdomain**: `glossary` (or your choice)
   - **Domain**: Your domain (e.g., `example.com`)
   - **Service Type**: HTTP
   - **URL**: `glossary:4000` (the Kubernetes service name and port)

### 4. Deploy Cloudflare Tunnel

```bash
# Apply all Cloudflare tunnel resources (Secret, ServiceAccount, Deployment)
kubectl apply -f glossary/cloudflared.yaml
```

### 5. Verify Tunnel

```bash
# Check cloudflared pod
kubectl get pods -l app=cloudflared -n glossary

# Check logs
kubectl logs -l app=cloudflared -n glossary -f
```

## Ingress Setup (Alternative to Cloudflare Tunnel)

If you prefer to use Kubernetes Ingress instead of Cloudflare Tunnel:

### 1. Deploy Ingress

```bash
kubectl apply -f glossary/ingress.yaml
```

### 2. Configure Ingress Controller

The Ingress manifest is configured for Traefik. Ensure you have:
- Traefik ingress controller installed in your cluster
- `ingressClassName: traefik` configured
- Appropriate annotations for your ingress controller

**Note**: The Ingress is configured for HTTP only (web entrypoint). This is intentional when using Cloudflare Tunnel, which handles TLS termination. If using Ingress without Cloudflare Tunnel, consider adding TLS configuration with certificates for HTTPS.

### 3. Update Hostname

Edit `glossary/ingress.yaml` and update the `host` field to match your domain:

```yaml
spec:
  rules:
    - host: glossary.yourdomain.com
```

**Note**: The Ingress references the `glossary` service on port `4000`, which targets the container port `4000`. Both the service and the application container use port 4000.

## Configuration Details

### Environment Variables

**Required:**
- `PHX_SERVER=true`: Enables Phoenix server
- `DATABASE_URL`: PostgreSQL connection string (ecto:// format)
- `SECRET_KEY_BASE`: Phoenix secret key base

**Optional:**
- `PORT`: Application port (default: 4000)
- `PHX_HOST`: Application hostname
- `POOL_SIZE`: Database connection pool size (default: 10)
- `DNS_CLUSTER_QUERY`: DNS cluster query for distributed Phoenix
- `ECTO_IPV6`: Enable IPv6 for database connections (`true` or `1`)

### Service Configuration

The application service (`glossary`) is configured as:
- **Type**: ClusterIP (internal only)
- **Port**: 4000 (service port)
- **Target Port**: 4000 (container port where the application listens)
- **Protocol**: TCP

The Ingress and Cloudflare Tunnel both reference the service on port `4000`.

### Persistent Storage

The application PVC provides 10Gi of persistent storage mounted at `/app/storage`. This can be used for:
- Application logs
- File uploads
- Temporary files
- Other persistent data

### Resource Limits

**Application:**
- CPU: 500m request, 1000m limit
- Memory: 512Mi request, 1Gi limit

**PostgreSQL:**
- CPU: 200m request, 1000m limit
- Memory: 256Mi request, 1Gi limit
- Storage: 20Gi persistent volume (longhorn-nvme)

**Cloudflare Tunnel:**
- CPU: 10m request, 100m limit
- Memory: 32Mi request, 128Mi limit

### Health Checks

**Application:**
- **Liveness Probe**: HTTP GET on `/health` every 10 seconds (starts after 30s)
  - Checks if the application process is running
  - Does not check database connectivity to avoid unnecessary pod restarts
  - Returns 200 OK if the application is alive
- **Readiness Probe**: HTTP GET on `/health/ready` every 5 seconds (starts after 30s to allow for migrations)
  - Checks if the application is ready to serve traffic, including database connectivity
  - Returns 200 OK if ready, 503 Service Unavailable if database is disconnected
  - This prevents traffic from being routed to pods that cannot serve requests

**PostgreSQL:**
- **Startup Probe**: `pg_isready` check every 5 seconds (allows up to 60s for initial startup)
- **Liveness Probe**: `pg_isready` check every 10 seconds (starts after 60s)
- **Readiness Probe**: `pg_isready` check every 5 seconds (starts after 5s)

## Customization

### Replicas

Edit `glossary/deployment.yaml` to change the number of replicas:

```yaml
spec:
  replicas: 3  # Increase for more availability
```

**Important - PostgreSQL Single Replica Limitation**: The PostgreSQL StatefulSet uses a single replica. This means:
- **Any pod restart or failure will cause database downtime** - The application will be unable to connect to the database during this time
- **Data loss risk** - If the persistent volume fails, all data could be lost
- **No high availability** - This configuration is suitable for development or low-traffic production environments

For production deployments requiring high availability, consider:
- **PostgreSQL replication**: Set up primary/replica replication for redundancy
- **Backup strategy**: Implement regular backups (see Backup Strategy section below)
- **Managed database service**: Use a managed database service (e.g., AWS RDS, Google Cloud SQL, Azure Database) for built-in HA and backups

### Node Affinity (Cloudflare Tunnel)

The cloudflared deployment includes node affinity to exclude WiFi nodes. To customize:

1. **Remove affinity** (allow any node): Remove the `affinity` section
2. **Pin to specific node**: Uncomment Pattern 2 and set `<NODE_NAME>`
3. **Custom rules**: Modify the `matchExpressions` as needed

### Namespace

All manifests use the `glossary` namespace. To use a different namespace:

1. Update `metadata.namespace` in all YAML files
2. Or use `kubectl apply -f <file> -n <namespace>`

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### Database Connection Issues

- Verify `DATABASE_URL` format: `ecto://user:password@host:5432/database`
- Use `postgres` as the hostname (the Kubernetes service name)
- Check PostgreSQL pod is running: `kubectl get pods -l app=db -n glossary`
- Check PostgreSQL logs: `kubectl logs -l app=db -n glossary`
- Verify PostgreSQL service exists: `kubectl get svc postgres -n glossary`
- Test connection from glossary pod: `kubectl exec -it <glossary-pod> -n glossary -- /app/bin/glossary eval "Glossary.Repo.query(\"SELECT 1\")"`

### Cloudflare Tunnel Not Connecting

- Verify token is correct and not expired
- Check tunnel configuration in Cloudflare dashboard
- Verify service name matches: `glossary:4000`
- Check cloudflared pod logs: `kubectl logs -l app=cloudflared -n glossary`

### Storage Issues

- Verify `longhorn-nvme` StorageClass exists: `kubectl get storageclass`
- Check application PVC status: `kubectl get pvc glossary-storage -n glossary`
- Check PostgreSQL PVC status: `kubectl get pvc postgres-data -n glossary`
- Verify PVCs are bound: `kubectl get pvc -n glossary`
- Verify storage is available in the cluster

## Maintenance

### Updating the Application

```bash
# Update image tag in glossary/deployment.yaml, then:
kubectl apply -f glossary/deployment.yaml

# Or use kubectl set image
kubectl set image deployment/glossary glossary=your-registry/glossary:v1.1.0 -n glossary
```

### Scaling

```bash
# Scale up
kubectl scale deployment glossary --replicas=3

# Scale down
kubectl scale deployment glossary --replicas=1
```

### Rolling Restart

```bash
# Restart application
kubectl rollout restart deployment/glossary -n glossary

# Restart PostgreSQL (use with caution - may cause downtime)
kubectl rollout restart statefulset/postgres -n glossary
```

### Database Migrations

**Automatic Migrations**: Migrations run automatically when the container starts. The `server` script (used as the container CMD) executes `./migrate` before starting the Phoenix server. This ensures the database is always up-to-date when the application starts.

**Manual Migrations** (if needed):

If you need to run migrations manually (e.g., for troubleshooting or one-off operations):

```bash
# Get a shell in a glossary pod
kubectl exec -it deployment/glossary -n glossary -- /bin/sh

# Run migrations
/app/bin/glossary eval "Glossary.Release.migrate()"
```

Or use a one-off job:

```bash
kubectl run glossary-migrate --image=your-registry/glossary:v1.0.0 \
  --rm -it --restart=Never \
  -- /app/bin/glossary eval "Glossary.Release.migrate()" \
  -n glossary
```

**Note**: The `Glossary.Release.migrate()` function is defined in `lib/glossary/release.ex` and follows the [Phoenix Releases pattern](https://hexdocs.pm/phoenix/releases.html#ecto-migrations) for running migrations in production releases.

## Backup Strategy

Since the PostgreSQL StatefulSet uses a single replica with persistent storage, implementing a backup strategy is critical to prevent data loss.

### Manual Backup

```bash
# Create a backup
kubectl exec -it postgres-0 -n glossary -- \
  pg_dump -U postgres -d glossary > backup-$(date +%Y%m%d-%H%M%S).sql

# Restore from backup
kubectl exec -i postgres-0 -n glossary -- \
  psql -U postgres -d glossary < backup-20240101-120000.sql
```

### Automated Backup with CronJob

Create a Kubernetes CronJob to run regular backups:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  namespace: glossary
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: postgres-backup
            image: postgres:16-alpine
            env:
            - name: PGHOST
              value: postgres
            - name: PGDATABASE
              valueFrom:
                configMapKeyRef:
                  name: glossary-config
                  key: POSTGRES_DB
            - name: PGUSER
              valueFrom:
                configMapKeyRef:
                  name: glossary-config
                  key: POSTGRES_USER
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: glossary-secrets
                  key: POSTGRES_PASSWORD
            command:
            - /bin/sh
            - -c
            - pg_dump -Fc -f /backups/glossary-$(date +%Y%m%d-%H%M%S).dump
            volumeMounts:
            - name: backup-storage
              mountPath: /backups
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: postgres-backup-storage
          restartPolicy: OnFailure
```

### Backup Storage

Create a PVC for backup storage:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-backup-storage
  namespace: glossary
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn-nvme
  resources:
    requests:
      storage: 50Gi
EOF
```

### Backup Best Practices

- **Frequency**: Daily backups for production, more frequent for critical data
- **Retention**: Keep at least 7 days of daily backups, plus weekly/monthly archives
- **Off-cluster storage**: Copy backups to external storage (S3, NFS, etc.) for disaster recovery
- **Testing**: Regularly test restore procedures to ensure backups are valid
- **Monitoring**: Set up alerts for backup job failures

## Security Notes

- **Application Security**:
  - Runs as non-root user (`nobody`, UID 65534)
  - Container-level security context with `allowPrivilegeEscalation: false` and dropped capabilities
- **PostgreSQL Security**:
  - Runs as postgres user (UID 999)
  - Container-level security context with `allowPrivilegeEscalation: false` and dropped capabilities
- **Secrets Management**:
  - Secrets should never be committed to version control
  - Use `secrets.yaml.template` as a template only (contains placeholder values that must be replaced)
  - Never commit `secrets.yaml` to version control - add it to `.gitignore`
  - Use `kubectl create secret` to create secrets instead of committing them
  - Consider using Kubernetes secrets management (e.g., Sealed Secrets, External Secrets Operator)
- **Cloudflare Tunnel**:
  - ServiceAccount has `automountServiceAccountToken: false`
  - Token should be created via `kubectl` rather than committed to version control

## Additional Resources

- [Phoenix Deployment Guide](https://hexdocs.pm/phoenix/deployment.html)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)

