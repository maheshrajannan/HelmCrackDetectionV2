# Argo CD + Helm GitOps Guide (argocd app)

This repository demonstrates how to install Argo CD and deploy an **argocd app** using Helm and GitOps workflows on a Kubernetes cluster.

---

## Phase 1: Prerequisites & Cluster Validation

### Step 1.1: Verify Your Kubernetes Cluster

```bash
# Check cluster connectivity and version
kubectl cluster-info
kubectl version --client

# Verify cluster has sufficient resources (Argo CD needs ~2GB RAM)
kubectl top nodes
kubectl top pods -A

# Check available namespaces
kubectl get namespaces

Step 1.2: Create a Dedicated Namespace for Argo CD

bash
# Create the argocd namespace
kubectl create namespace argocd

# Verify namespace creation
kubectl get namespaces | grep argocd

Phase 2: Install Argo CD
Step 2.1: Add Argo CD Helm Repository

bash
# Add the official Argo CD Helm repository
helm repo add argo https://argoproj.github.io/argo-helm

# Update Helm repositories
helm repo update

# Verify the repository is added
helm repo list | grep argo

Step 2.2: Install Argo CD using Helm Chart

bash
# Basic installation (minimal configuration)
helm install argocd argo/argo-cd \
  --namespace argocd \
  --values - <<EOF
server:
  service:
    type: LoadBalancer
repoServer:
  replicas: 1
controller:
  replicas: 1
redis:
  enabled: true
EOF

# Verify installation
helm list -n argocd
kubectl get pods -n argocd

Phase 3: Access Argo CD Web UI
Step 3.1: Get the LoadBalancer External IP

bash
# Check services
kubectl get svc -n argocd

# Get the external IP/hostname of argocd-server service
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress.hostname}'

# Store it for later use
ARGOCD_URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress.hostname}')
echo "Argo CD URL: https://$ARGOCD_URL"

Step 3.2: Retrieve Default Admin Password

bash
# Get the auto-generated admin password
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Store password securely
ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 -d)

Step 3.3: Access the UI

bash
# Open in browser
# URL: https://<LoadBalancer-IP-or-Hostname>
# Username: admin
# Password: <from Step 3.2>

Phase 4: Connect Git Repository
Step 4.2: Add Repository Credentials to Argo CD (CLI method)

bash
# Login to Argo CD CLI
argocd login <ARGOCD_URL> \
  --username admin \
  --password <ARGOCD_PASSWORD> \
  --insecure  # Only for testing, remove in production

# Add Git repository (HTTPS with personal access token)
argocd repo add https://github.com/<your-username>/argocd-apps.git \
  --username <github-username> \
  --password <github-pat> \
  --insecure-skip-server-verification

# Verify repository is added
argocd repo list

Step 4.3: Add Repository Using Kubernetes Secret (Declarative)

bash
# Create repository secret
kubectl apply -f - -n argocd <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: github-repo-creds
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: https://github.com/<your-username>/argocd-apps.git
  password: <github-pat-token>
  username: <github-username>
EOF

# Verify secret creation
kubectl get secrets -n argocd | grep github

Phase 7: Create the argocd app Application

bash
cd applications

# Create application definition
cat > argocd-app-application.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/<your-username>/argocd-apps.git
    targetRevision: main
    path: helm-charts/argocd-app
    helm:
      releaseName: argocd-app
      values: |
        replicaCount: 3
        image:
          tag: "1.21"
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

Step 7.2: Deploy Application to Cluster

bash
# Apply the application
kubectl apply -f argocd-app-application.yaml

# Verify application is created
kubectl get applications -n argocd

# Check application status
kubectl describe application argocd-app -n argocd

# Watch sync status
kubectl get application argocd-app -n argocd -o jsonpath='{.status.sync.status}'

Step 7.3: Alternative - Create Application via CLI

bash
# Create application using argocd CLI
argocd app create argocd-app \
  --repo https://github.com/<your-username>/argocd-apps.git \
  --path helm-charts/argocd-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --auto-prune \
  --self-heal \
  --release-name argocd-app

# Verify application creation
argocd app list

# Get detailed status
argocd app get argocd-app

Phase 8: Trigger Synchronization
Step 8.1: Manual Sync (First Time)

bash
# Trigger manual sync
argocd app sync argocd-app

# Watch sync progress
argocd app wait argocd-app --sync

# Check pod status
kubectl get pods -n default
kubectl describe pod <pod-name> -n default

bash
# Open Argo CD UI in browser
# Navigate to: https://<ARGOCD_URL>
# Login with admin credentials
# You should see "argocd-app" with "Synced" status in green

Phase 9: Testing GitOps Workflow (Continuous Sync)
Step 9.1: Make a Change in Git

bash
# Update values in your Helm chart
cd helm-charts/argocd-app

# Edit values.yaml to change replica count
sed -i 's/replicaCount: 2/replicaCount: 3/' values.yaml

# Or manually edit:
nano values.yaml
# Change: replicaCount: 3

Step 9.2: Commit and Push Change

bash
# Commit the change
git add values.yaml
git commit -m "Increase replica count to 3"
git push origin main

# Wait for Argo CD to detect the change (default: 3 minutes)
# Or trigger manual sync:
argocd app sync argocd-app

Step 9.3: Verify Automatic Reconciliation

bash
# Watch new pods being created
kubectl get pods -n default -w

# Confirm 3 replicas are running
kubectl get deployment argocd-app -n default -o jsonpath='{.spec.replicas}'

# Expected output: 3

Phase 10: Advanced Configuration (Production-Ready)
Step 10.1: Enable RBAC and Access Control

bash
# Update admin password
argocd account update-password \
  --account admin \
  --new-password <new-secure-password>

# Set default policy to read-only for other users
kubectl patch configmap argocd-rbac-cm -n argocd -p '{"data":{"policy.default":"role:readonly"}}'

# Verify RBAC
argocd account list

Step 10.2: Configure Webhook for Automatic Trigger

bash
# Get webhook URL (refresh)
argocd app get argocd-app --refresh

# In GitHub:
# Settings → Webhooks → Add webhook
# Payload URL: https://<ARGOCD_URL>/api/webhook
# Content Type: application/json
# Events: Just the push event

Step 10.3: Configure Private Helm Repository (Optional)

bash
# For private Helm repos on AWS S3 or Artifactory
argocd repo add s3://my-helm-bucket \
  --type helm \
  --aws-use-ec2-iam

# Verify
argocd repo list

Phase 11: Monitoring and Troubleshooting
Step 11.1: Check Argo CD Logs

bash
# View controller logs
kubectl logs -n argocd deployment/argocd-controller-manager -f

# View repo server logs
kubectl logs -n argocd deployment/argocd-repo-server -f

# View API server logs
kubectl logs -n argocd deployment/argocd-server -f

Step 11.2: Verify Synchronization Status

bash
# Check application sync status
argocd app get argocd-app

# Expected output: Should show "Synced" status

# Get detailed health status
kubectl get application argocd-app -n argocd -o yaml | grep -A 5 status:

Step 11.3: Common Issues and Fixes

bash
# Issue 1: Application shows "OutOfSync"
# Solution: Trigger manual sync
argocd app sync argocd-app

# Issue 2: Repository credentials error
# Solution: Verify repo secret
kubectl get secret -n argocd | grep repo

# Issue 3: Helm chart rendering error
# Solution: Test locally first
helm template argocd-app helm-charts/argocd-app --debug

# Issue 4: Pod not starting
# Solution: Check pod events
kubectl describe pod <pod-name> -n default

Quick Reference Summary
Phase	Key Commands
Install	helm install argocd argo/argo-cd -n argocd
Access UI	kubectl get svc argocd-server -n argocd
Add Repo	argocd repo add https://github.com/.../repo.git
Create App	kubectl apply -f argocd-app-application.yaml
Sync	argocd app sync argocd-app
Monitor	argocd app get argocd-app