# ArgoCD + Jenkins Integration Setup Guide

## 🎯 Overview

This guide walks you through connecting Jenkins CI pipeline with ArgoCD GitOps deployment.

**Flow:**
1. Push code → Jenkins builds Docker image → Pushes to DockerHub
2. Jenkins updates k8s manifest with new image tag → Pushes to GitHub
3. ArgoCD detects change → Deploys to Kubernetes

---

## ✅ Prerequisites Checklist

- [ ] Kubernetes cluster running (Minikube/K3s/EKS/GKE)
- [ ] ArgoCD installed and accessible
- [ ] Jenkins installed with required plugins
- [ ] DockerHub account
- [ ] GitHub repository access

---

## 📋 Step-by-Step Setup

### STEP 1: Push Kubernetes Manifests to GitHub

```bash
cd /c/Users/91967/OneDrive/Documents/GitHub/devops-sample-app

# Check what will be committed
git status

# Add all files
git add .

# Commit
git commit -m "Add production k8s manifests with PostgreSQL and monitoring"

# Push to GitHub
git push origin main
```

**Verify on GitHub:** Visit https://github.com/eknathdj/devops-sample-app and confirm `k8s/product-service/` folder exists.

---

### STEP 2: Create Kubernetes Secrets

Before ArgoCD can deploy, create the required secrets:

```bash
# Create product-service namespace
kubectl create namespace product-service

# Create PostgreSQL secret
kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_USER=productuser \
  --from-literal=POSTGRES_PASSWORD=SecurePassword123! \
  --from-literal=POSTGRES_DB=productdb \
  --from-literal=DATABASE_URL=postgresql://productuser:SecurePassword123!@postgres-service:5432/productdb \
  -n product-service

# Create application secret
kubectl create secret generic app-secret \
  --from-literal=JWT_SECRET=$(openssl rand -base64 32) \
  --from-literal=API_KEY=$(openssl rand -hex 16) \
  --from-literal=ENCRYPTION_KEY=$(openssl rand -base64 32) \
  -n product-service

# Verify secrets
kubectl get secrets -n product-service
```

---

### STEP 3: Deploy ArgoCD Application

```bash
# Apply ArgoCD application manifest
kubectl apply -f argocd/product-service-app.yaml

# Verify application created
kubectl get application -n argocd

# Check application status
argocd app get product-service
```

---

### STEP 4: Sync ArgoCD (First Deployment)

```bash
# Manual sync (first time)
argocd app sync product-service

# Watch deployment
kubectl get pods -n product-service -w

# Expected pods:
# - postgres-0 (StatefulSet)
# - product-service-xxx-xxx (Deployment - 3 replicas)
# - db-schema-job-xxx (Completed)
# - db-seed-job-xxx (Completed)
```

**Check in ArgoCD UI:**
- Open http://localhost:8081 (or your ArgoCD URL)
- Login with admin credentials
- You should see `product-service` app with status "Synced" and "Healthy"

---

### STEP 5: Configure Jenkins Credentials

#### A. GitHub Credentials

1. Generate GitHub Personal Access Token:
   - Go to https://github.com/settings/tokens
   - Generate new token (classic)
   - Scopes: ✅ `repo`, ✅ `workflow`
   - Copy token

2. Add to Jenkins:
   - Jenkins → Manage Jenkins → Credentials → Global
   - Add Credentials
   - Kind: **Username with password**
   - Username: `eknathdj`
   - Password: `<paste-github-token>`
   - ID: `github-creds`

#### B. DockerHub Credentials

1. Add to Jenkins:
   - Jenkins → Manage Jenkins → Credentials → Global
   - Add Credentials
   - Kind: **Username with password**
   - Username: `<your-dockerhub-username>`
   - Password: `<your-dockerhub-password>`
   - ID: `dockerhub-creds`

---

### STEP 6: Create Jenkins Pipeline

1. Jenkins → New Item
2. Name: `devops-sample-app-pipeline`
3. Type: **Pipeline**
4. Configuration:
   - **Build Triggers:** ✅ GitHub hook trigger for GITScm polling
   - **Pipeline:**
     - Definition: **Pipeline script from SCM**
     - SCM: **Git**
     - Repository URL: `https://github.com/eknathdj/devops-sample-app`
     - Credentials: `github-creds`
     - Branch: `*/main`
     - Script Path: `Jenkinsfile`
5. **Save**

---

### STEP 7: Configure GitHub Webhook (Optional - for auto-trigger)

1. Go to https://github.com/eknathdj/devops-sample-app/settings/hooks
2. Add webhook:
   - Payload URL: `http://<jenkins-ip>:8080/github-webhook/`
   - Content type: `application/json`
   - Events: ✅ Push events
3. **Add webhook**

**For local Jenkins (using ngrok):**
```bash
# Expose Jenkins via ngrok
ngrok http 8080

# Use ngrok URL in webhook: https://xxxx.ngrok.io/github-webhook/
```

---

### STEP 8: Test the Complete Pipeline

#### Manual Test (First Build)

```bash
# In Jenkins UI: Click "Build Now" on devops-sample-app-pipeline

# Jenkins will:
# 1. Clone repo
# 2. Build Docker image (eknathdj/devops-sample-app:1)
# 3. Push to DockerHub
# 4. Update k8s/product-service/04-app-deployment.yaml with new tag
# 5. Commit and push to GitHub

# ArgoCD will:
# 1. Detect manifest change in GitHub
# 2. Sync new image tag to Kubernetes
# 3. Perform rolling update (zero downtime)
```

#### Monitor Deployment

```bash
# Watch ArgoCD sync
argocd app get product-service --refresh

# Watch Kubernetes pods
kubectl get pods -n product-service -w

# Check deployment rollout
kubectl rollout status deployment/product-service -n product-service

# View application logs
kubectl logs -f deployment/product-service -n product-service
```

---

## 🔄 How It Works (End-to-End Flow)

### Scenario: You make a code change

```bash
# 1. Make code change
echo "console.log('new feature');" >> src/index.js

# 2. Commit and push
git add .
git commit -m "Add new feature"
git push origin main

# 3. GitHub webhook triggers Jenkins
# Jenkins automatically:
# - Builds Docker image: eknathdj/devops-sample-app:2
# - Pushes to DockerHub
# - Updates k8s/product-service/04-app-deployment.yaml:
#   FROM: image: eknathdj/devops-sample-app:1
#   TO:   image: eknathdj/devops-sample-app:2
# - Commits and pushes manifest change

# 4. ArgoCD detects manifest change
# - Sees image tag changed from :1 to :2
# - Triggers sync
# - Kubernetes performs rolling update
# - Old pods gradually replaced with new pods

# 5. Deployment complete (zero downtime!)
```

---

## 🐛 Troubleshooting

### ArgoCD shows "Unknown" status

```bash
# Refresh ArgoCD
argocd app get product-service --refresh

# Hard refresh
argocd app get product-service --hard-refresh

# Check for errors
kubectl describe application product-service -n argocd
```

### Jenkins build fails at "Push to DockerHub"

```bash
# Test DockerHub login manually
docker login
# Enter credentials

# Verify credentials in Jenkins
# Manage Jenkins → Credentials → Check dockerhub-creds
```

### Application pods stuck in "ImagePullBackOff"

```bash
# Check if image exists in DockerHub
# Visit: https://hub.docker.com/r/eknathdj/devops-sample-app/tags

# Check pod events
kubectl describe pod <pod-name> -n product-service
```

### PostgreSQL pod in CrashLoopBackOff

```bash
# Check logs
kubectl logs postgres-0 -n product-service --previous

# Check PVC
kubectl get pvc -n product-service

# Recreate pod
kubectl delete pod postgres-0 -n product-service
```

---

## 📊 Verification Commands

```bash
# Check all components
kubectl get all -n product-service

# Check ArgoCD application
argocd app list

# Check recent deployments
kubectl rollout history deployment/product-service -n product-service

# Check Jenkins builds
# Visit: http://localhost:8080/job/devops-sample-app-pipeline/

# Check DockerHub images
# Visit: https://hub.docker.com/r/eknathdj/devops-sample-app/tags
```

---

## 🎉 Success Indicators

✅ **ArgoCD UI shows:**
- Status: **Synced** (green)
- Health: **Healthy** (green)

✅ **Kubernetes shows:**
```bash
$ kubectl get pods -n product-service
NAME                               READY   STATUS      RESTARTS   AGE
postgres-0                         1/1     Running     0          5m
product-service-7d9f8c-abc12       1/1     Running     0          2m
product-service-7d9f8c-def34       1/1     Running     0          2m
product-service-7d9f8c-ghi56       1/1     Running     0          2m
db-schema-job-xyz                  0/1     Completed   0          5m
db-seed-job-abc                    0/1     Completed   0          5m
```

✅ **Jenkins shows:**
- Last build: **SUCCESS** (blue ball)
- Console output shows: "Pipeline completed successfully!"

---

## 📚 Next Steps

1. **Add Tests to Pipeline:** Uncomment test stages in Jenkinsfile
2. **Add Notifications:** Configure Slack/Email alerts in Jenkins
3. **Enable HTTPS:** Configure Ingress with TLS certificates
4. **Add Monitoring:** Deploy Prometheus + Grafana stack
5. **Multi-Environment:** Create staging/production overlays with Kustomize

---

## 🔗 Useful Links

- ArgoCD UI: http://localhost:8081
- Jenkins UI: http://localhost:8080
- DockerHub: https://hub.docker.com/r/eknathdj/devops-sample-app
- GitHub Repo: https://github.com/eknathdj/devops-sample-app

---

**Need Help?** Check the [main README.md](README.md) or open an issue on GitHub.
