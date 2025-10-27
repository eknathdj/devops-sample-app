# DevOps Sample App

> A complete CI/CD pipeline demonstration using Jenkins, ArgoCD, Docker, and Kubernetes

This repository showcases a production-ready DevOps workflow with automated builds, containerization, and GitOps-based deployments.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
  - [1. Jenkins Setup](#1-jenkins-setup)
  - [2. GitHub Configuration](#2-github-configuration)
  - [3. DockerHub Configuration](#3-dockerhub-configuration)
  - [4. ArgoCD Setup](#4-argocd-setup)
- [Pipeline Workflow](#pipeline-workflow)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Contributing](#contributing)

---

## 🎯 Overview

This project implements a complete CI/CD pipeline that:
- ✅ Automatically builds Docker images on code commits
- ✅ Pushes images to DockerHub registry
- ✅ Updates Kubernetes manifests with new image tags
- ✅ Deploys applications using GitOps principles via ArgoCD
- ✅ Supports multiple environments (staging, production)

**Tech Stack:**
- **CI/CD**: Jenkins
- **Containerization**: Docker
- **Orchestration**: Kubernetes
- **GitOps**: ArgoCD
- **Registry**: DockerHub

---

## 🏗️ Architecture

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   GitHub    │─────▶│   Jenkins   │────▶│  DockerHub  │
│  (Source)   │      │   (Build)   │      │  (Registry) │
└─────────────┘      └─────────────┘      └─────────────┘
                            │
                            │ Update Manifest
                            ▼
                     ┌─────────────┐
                     │   GitHub    │
                     │ (GitOps)    │
                     └─────────────┘
                            │
                            │ Sync
                            ▼
                     ┌─────────────┐      ┌─────────────┐
                     │   ArgoCD    │─────▶│ Kubernetes  │
                     │   (Deploy)  │      │  (Runtime)  │
                     └─────────────┘      └─────────────┘
```

**Workflow:**
1. Developer pushes code to GitHub
2. Jenkins detects changes via webhook
3. Jenkins builds Docker image and pushes to DockerHub
4. Jenkins updates Kubernetes manifest with new image tag
5. ArgoCD detects manifest changes
6. ArgoCD syncs and deploys to Kubernetes cluster

---

## ✅ Prerequisites

Before starting, ensure you have:

### Required Tools
- **Docker** (v20.10+) - [Install Docker](https://docs.docker.com/get-docker/)
- **Kubernetes Cluster** (v1.24+) - Options:
  - Minikube (local testing)
  - K3s/K3d (lightweight)
  - EKS/GKE/AKS (cloud)
  - OpenShift (optional)
- **kubectl** (v1.24+) - [Install kubectl](https://kubernetes.io/docs/tasks/tools/)
- **Git** (v2.30+)

### Accounts Needed
- GitHub account with repository access
- DockerHub account (free tier works)
- Basic understanding of Docker, Kubernetes, and CI/CD concepts

### System Requirements
- **Minimum**: 4GB RAM, 2 CPU cores, 20GB disk space
- **Recommended**: 8GB RAM, 4 CPU cores, 50GB disk space

---

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/eknathdj/devops-sample-app.git
cd devops-sample-app

# Build Docker image locally (optional test)
docker build -t devops-sample-app:local .

# Run locally to test
docker run -p 8080:8080 devops-sample-app:local
```

For full CI/CD setup, continue to [Detailed Setup](#detailed-setup).

---

## 📖 Detailed Setup

### 1. Jenkins Setup

#### Step 1.1: Install Jenkins with Docker

**Option A: Using Docker Compose (Recommended)**

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  jenkins:
    image: jenkins/jenkins:lts
    user: root
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false
    command: >
      bash -c "
        apt-get update &&
        apt-get install -y docker.io &&
        git config --global --add safe.directory '*' &&
        /usr/local/bin/jenkins.sh
      "

volumes:
  jenkins_home:
```

Start Jenkins:
```bash
docker-compose up -d
```

**Option B: Using Docker CLI**

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --user root \
  jenkins/jenkins:lts

# Install Docker inside Jenkins container
docker exec -it jenkins bash
apt-get update && apt-get install -y docker.io
git config --global --add safe.directory '*'
exit
docker restart jenkins
```

#### Step 1.2: Initial Jenkins Configuration

1. **Get Initial Admin Password:**
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

2. **Access Jenkins:**
   - Open browser: `http://localhost:8080`
   - Paste the admin password
   - Click "Install suggested plugins"
   - Create your admin user

#### Step 1.3: Install Required Jenkins Plugins

Go to **Manage Jenkins** → **Plugins** → **Available plugins**

Install these plugins:
- ✅ **Git Plugin** (git operations)
- ✅ **Pipeline** (pipeline support)
- ✅ **Docker Pipeline** (Docker integration)
- ✅ **Credentials Binding** (secure credential handling)
- ✅ **Workspace Cleanup** (cleanWs support)

Click "Install without restart" and wait for completion.

#### Step 1.4: Configure Jenkins Credentials

##### a) GitHub Credentials (Personal Access Token)

1. **Generate GitHub PAT:**
   - Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token (classic)"
   - Name: `Jenkins CI`
   - Expiration: 90 days or No expiration
   - Select scopes:
     - ✅ `repo` (Full control of repositories)
     - ✅ `workflow` (Update GitHub Action workflows)
   - Click "Generate token"
   - **⚠️ Copy the token immediately** (you won't see it again!)

2. **Add to Jenkins:**
   - Go to Jenkins → Manage Jenkins → Credentials → System → Global credentials
   - Click "Add Credentials"
   - **Kind:** Username with password
   - **Username:** `eknathdj` (your GitHub username)
   - **Password:** Paste your GitHub PAT
   - **ID:** `github-creds`
   - **Description:** GitHub Personal Access Token
   - Click "Create"

##### b) DockerHub Credentials

1. **Add to Jenkins:**
   - Same path: Manage Jenkins → Credentials → System → Global credentials
   - Click "Add Credentials"
   - **Kind:** Username with password
   - **Username:** Your DockerHub username
   - **Password:** Your DockerHub password or access token
   - **ID:** `dockerhub-creds`
   - **Description:** DockerHub Registry Credentials
   - Click "Create"

#### Step 1.5: Create Jenkins Pipeline

1. **Create New Pipeline:**
   - Click "New Item"
   - Name: `sample-app-pipeline`
   - Select "Pipeline"
   - Click "OK"

2. **Configure Pipeline:**
   - **Description:** CI/CD Pipeline for DevOps Sample App
   
   - **Build Triggers:**
     - ✅ Check "GitHub hook trigger for GITScm polling"
   
   - **Pipeline Definition:**
     - Select "Pipeline script from SCM"
     - **SCM:** Git
     - **Repository URL:** `https://github.com/eknathdj/devops-sample-app`
     - **Credentials:** Select `github-creds`
     - **Branch:** `*/main`
     - **Script Path:** `Jenkinsfile`
   
   - **Additional Behaviours:**
     - Add "Wipe out repository & force clone" (optional, for clean builds)

3. **Click "Save"**

---

### 2. GitHub Configuration

#### Step 2.1: Configure Webhook

1. Go to your GitHub repository: `https://github.com/eknathdj/devops-sample-app`
2. Click **Settings** → **Webhooks** → **Add webhook**
3. Configure:
   - **Payload URL:** `http://<YOUR_JENKINS_IP>:8080/github-webhook/`
     - Replace `<YOUR_JENKINS_IP>` with your Jenkins server IP
     - For local testing with public access, use [ngrok](https://ngrok.com/):
       ```bash
       ngrok http 8080
       # Use the ngrok URL: https://xxxx.ngrok.io/github-webhook/
       ```
   - **Content type:** `application/json`
   - **Events:** Select "Just the push event"
   - **Active:** ✅ Checked
4. Click "Add webhook"

#### Step 2.2: Verify Repository Structure

Ensure your repository has this structure:

```
devops-sample-app/
├── Dockerfile                              # Docker build instructions
├── Jenkinsfile                            # CI/CD pipeline definition (simple)
├── argocd-application-sample.yaml         # ArgoCD application example
├── argocd/
│   └── product-service-app.yaml          # ArgoCD application config
├── jenkins/
│   └── Jenkinsfile                        # Production-grade Jenkins pipeline
├── k8s/
│   └── product-service/                   # Kubernetes manifests
│       ├── 00-namespace.yaml             # Namespace with quotas
│       ├── 02-postgres-db.yaml           # PostgreSQL database
│       ├── 03-db-init-job.yaml           # DB schema & seed data
│       ├── 04-app-deployment.yaml        # Application deployment
│       ├── 05-ingress.yaml               # Ingress rules
│       ├── 06-monitoring.yaml            # Prometheus monitoring
│       ├── 07-network-policies.yaml      # Network security
│       ├── 08-rbac.yaml                  # RBAC permissions
│       ├── app-sealed-secret.yaml        # App secrets (sealed)
│       └── postgres-sealed-secret.yaml   # DB secrets (sealed)
└── README.md
```

---

### 3. DockerHub Configuration

#### Step 3.1: Create DockerHub Repository

1. Log in to [DockerHub](https://hub.docker.com)
2. Click "Create Repository"
3. Configure:
   - **Name:** `devops-sample-app`
   - **Visibility:** Public (or Private if preferred)
   - **Description:** Sample DevOps application
4. Click "Create"

Your image will be: `<username>/devops-sample-app`

#### Step 3.2: Update Jenkinsfile

Edit the `DOCKER_IMAGE` environment variable in your Jenkinsfile:

```groovy
environment {
    DOCKER_IMAGE = "your-dockerhub-username/devops-sample-app"
    // ... rest of config
}
```

---

### 4. ArgoCD Setup

#### Step 4.1: Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

#### Step 4.2: Access ArgoCD UI

**Option A: Port Forward (Local Access)**
```bash
kubectl port-forward svc/argocd-server -n argocd 8081:443
```
Access at: `https://localhost:8081`

**Option B: LoadBalancer (Cloud)**
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc argocd-server -n argocd
```

#### Step 4.3: Get ArgoCD Admin Password

```bash
# For ArgoCD 2.0+
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Username: admin
# Password: (output from above command)
```

#### Step 4.4: Install ArgoCD CLI (Optional)

```bash
# Linux
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# macOS
brew install argocd

# Login via CLI
argocd login localhost:8081 --username admin --password <password> --insecure
```

#### Step 4.5: Create ArgoCD Application

**Option A: Using ArgoCD UI**

1. Login to ArgoCD UI
2. Click "New App"
3. Configure:
   - **Application Name:** `product-service`
   - **Project:** `default`
   - **Sync Policy:** `Automatic`
     - ✅ Self Heal
     - ✅ Prune Resources
   - **Repository URL:** `https://github.com/eknathdj/devops-sample-app`
   - **Revision:** `main`
   - **Path:** `k8s/product-service`
   - **Cluster URL:** `https://kubernetes.default.svc`
   - **Namespace:** `product-service` (auto-created by manifests)
4. Click "Create"

**Option B: Using ArgoCD CLI**

```bash
# Create application
argocd app create product-service \
  --repo https://github.com/eknathdj/devops-sample-app \
  --path k8s/product-service \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace product-service \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

**Option C: Using Existing Manifest (Recommended)**

Use the provided ArgoCD application manifest:

```bash
kubectl apply -f argocd/product-service-app.yaml
```

This creates an ArgoCD application that monitors `k8s/product-service/` and automatically deploys all manifests (namespace, database, app, monitoring, etc.)

---

## 🗄️ Database Setup

This repo includes a production-ready PostgreSQL setup with:

**Components:**
- **StatefulSet** - Ensures stable storage and pod identity
- **Service** - Internal DNS endpoint (`postgres-service.product-service.svc.cluster.local`)
- **PersistentVolume** - 10Gi storage for database data
- **Init Jobs** - Automatic schema creation and seed data
- **Backups** - CronJob runs daily backups at 2 AM
- **Monitoring** - Prometheus metrics and health checks

**Database Credentials:**
Stored as SealedSecrets in `k8s/product-service/postgres-sealed-secret.yaml`. To create your own:

```bash
# Install Sealed Secrets controller first
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Create and seal a secret
kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_USER=productuser \
  --from-literal=POSTGRES_PASSWORD=yourpassword \
  --from-literal=POSTGRES_DB=productdb \
  --from-literal=DATABASE_URL=postgresql://productuser:yourpassword@postgres-service:5432/productdb \
  --dry-run=client -o yaml | \
  kubeseal -o yaml > k8s/product-service/postgres-sealed-secret.yaml
```

**Manifest Deployment Order:**
Files are numbered to ensure correct deployment sequence:
1. `00-namespace.yaml` - Creates namespace with resource quotas
2. `02-postgres-db.yaml` - PostgreSQL database (StatefulSet + Service)
3. `03-db-init-job.yaml` - Database schema creation and seed data
4. `04-app-deployment.yaml` - Application deployment (waits for DB)
5. `05-ingress.yaml` - External access configuration
6. `06-monitoring.yaml` - Prometheus ServiceMonitor
7. `07-network-policies.yaml` - Network security rules
8. `08-rbac.yaml` - Service accounts and permissions

---

## 🔄 Pipeline Workflow

### What Happens When You Push Code?

1. **Trigger**: Push to GitHub → Webhook notifies Jenkins
2. **Setup**: Jenkins configures Git and cleans workspace
3. **Checkout**: Clone repository
4. **Build**: Create Docker image tagged with build number
5. **Push**: Upload image to DockerHub
6. **Update**: Modify Kubernetes manifest with new image tag
7. **Commit**: Push manifest changes back to GitHub
8. **Deploy**: ArgoCD detects changes and syncs to Kubernetes

### Manual Trigger

To manually trigger a build:
```bash
# In Jenkins UI: Click "Build Now" on your pipeline
# Or via CLI:
curl -X POST http://localhost:8080/job/sample-app-pipeline/build \
  --user admin:<your-jenkins-token>
```

### Monitor Deployment

```bash
# Watch ArgoCD sync status
argocd app get product-service --refresh

# Watch Kubernetes pods
kubectl get pods -n product-service -w

# Check application logs
kubectl logs -f deployment/product-service -n product-service

# Check PostgreSQL database logs
kubectl logs -f statefulset/postgres -n product-service

# Get service endpoints
kubectl get svc -n product-service

# Check ingress
kubectl get ingress -n product-service
```

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. Jenkins: "fatal: not in a git directory"

**Cause:** Git ownership/permission issue

**Solution:**
```bash
# Inside Jenkins container
docker exec -it jenkins bash
git config --global --add safe.directory '*'
exit
docker restart jenkins
```

#### 2. Jenkins: "Permission denied" when pushing to GitHub (403 error)

**Cause:** GitHub credentials invalid or expired

**Solution:**
- Generate new GitHub Personal Access Token (PAT)
- Update `github-creds` in Jenkins with new PAT
- Ensure PAT has `repo` and `workflow` scopes

#### 3. Jenkins: "Cannot connect to Docker daemon"

**Cause:** Docker socket not mounted or permission issue

**Solution:**
```bash
# Ensure socket is mounted
docker run -v /var/run/docker.sock:/var/run/docker.sock ...

# Or give Jenkins user permission
docker exec -it jenkins bash
chmod 666 /var/run/docker.sock
```

#### 4. ArgoCD: Application stuck in "OutOfSync"

**Cause:** Manifest changes not detected or sync policy issue

**Solution:**
```bash
# Force refresh
argocd app get product-service --refresh

# Manual sync
argocd app sync product-service

# Check diff
argocd app diff product-service
```

#### 5. Kubernetes: ImagePullBackOff

**Cause:** Image not found in registry or auth issue

**Solution:**
```bash
# Verify image exists in DockerHub
# Check image name in deployment.yaml matches exactly

# For private repos, create imagePullSecret
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<username> \
  --docker-password=<password> \
  -n product-service

# Add to deployment.yaml:
# imagePullSecrets:
#   - name: dockerhub-secret
```

#### 6. Jenkins: Build fails at "Update ArgoCD Manifest" stage

**Cause:** File path incorrect or sed command issue

**Solution:**
```bash
# Verify file exists
ls -la k8s/product-service/04-app-deployment.yaml

# Test sed command locally
sed -i 's|image: .*|image: new-image:tag|g' k8s/product-service/04-app-deployment.yaml
```

#### 7. PostgreSQL: Pod stuck in CrashLoopBackOff

**Cause:** Permission issues, missing PVC, or data directory problems

**Solution:**
```bash
# Check pod status
kubectl describe pod postgres-0 -n product-service

# Check logs
kubectl logs postgres-0 -n product-service --previous

# Check PVC status
kubectl get pvc -n product-service

# Common fixes:
# 1. Delete and recreate pod (data persists in PVC)
kubectl delete pod postgres-0 -n product-service

# 2. If PVC is stuck, delete and recreate
kubectl delete pvc postgres-storage-postgres-0 -n product-service
kubectl delete pod postgres-0 -n product-service
```

#### 8. Application can't connect to database

**Cause:** Database not ready or incorrect connection string

**Solution:**
```bash
# Verify database is running
kubectl get pods -n product-service | grep postgres

# Test database connectivity from app pod
kubectl exec -it deployment/product-service -n product-service -- \
  sh -c 'nc -zv postgres-service 5432'

# Check database secrets
kubectl get secret postgres-secret -n product-service -o yaml

# Verify DATABASE_URL format
# Should be: postgresql://user:password@postgres-service:5432/dbname
```

### Debug Commands

```bash
# Jenkins logs
docker logs jenkins -f

# ArgoCD logs
kubectl logs -f deployment/argocd-server -n argocd

# Application logs
kubectl logs -f deployment/product-service -n product-service

# PostgreSQL logs
kubectl logs -f statefulset/postgres -n product-service

# Describe pod for details
kubectl describe pod <pod-name> -n product-service

# Check events
kubectl get events -n product-service --sort-by='.lastTimestamp'
```

---

## 🎯 Best Practices

### Security

1. **Rotate Credentials Regularly**
   - GitHub PATs: Rotate every 90 days
   - DockerHub tokens: Use access tokens instead of passwords
   - Jenkins credentials: Audit quarterly

2. **Use Secrets Management**
   ```bash
   # This repo uses SealedSecrets for GitOps-safe secret storage
   # Secrets are encrypted in Git and decrypted by the cluster
   
   # To create new sealed secrets:
   kubectl create secret generic my-secret \
     --from-literal=key=value \
     --dry-run=client -o yaml | \
     kubeseal -o yaml > my-sealed-secret.yaml
   
   # Apply sealed secret
   kubectl apply -f my-sealed-secret.yaml -n product-service
   ```

3. **Enable RBAC**
   - Restrict Jenkins service account permissions
   - Use least-privilege principle in Kubernetes

### Pipeline Optimization

1. **Use Build Caching**
   ```dockerfile
   # In Dockerfile, order layers by change frequency
   COPY package.json .
   RUN npm install
   COPY . .
   ```

2. **Parallel Stages**
   ```groovy
   parallel {
       stage('Test') { ... }
       stage('Security Scan') { ... }
   }
   ```

3. **Conditional Deployment**
   ```groovy
   when {
       branch 'main'
       expression { currentBuild.result == 'SUCCESS' }
   }
   ```

### GitOps Best Practices

1. **Separate Config from Code**
   - Keep manifests in `k8s/` directory organized by service
   - Use numbered files for deployment order (00, 02, 03, etc.)
   - Namespace created first, then dependencies, then application

2. **Version Everything**
   - Always use specific image tags (never `:latest` in production)
   - Tag format: `eknathdj/product-service:${BUILD_NUMBER}`
   - Jenkins updates image tags in manifests automatically

3. **Environment Management**
   - Current setup: Single `product-service` namespace
   - For multi-environment: Create separate namespaces or use Kustomize overlays
   - Example: `k8s/base/` + `k8s/overlays/staging/` + `k8s/overlays/production/`

---

## 📊 Monitoring and Observability

### Add Monitoring Stack (Optional)

```bash
# Install Prometheus and Grafana
kubectl create namespace monitoring

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring

# Access Grafana
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
# Default: admin / prom-operator
```

### Useful Metrics to Track

- Build success rate
- Deployment frequency
- Lead time for changes
- Mean time to recovery (MTTR)
- Container restart rate

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Development Workflow

```bash
# Clone your fork
git clone https://github.com/<your-username>/devops-sample-app.git

# Add upstream remote
git remote add upstream https://github.com/eknathdj/devops-sample-app.git

# Create feature branch
git checkout -b feature/my-feature

# Make changes and test locally
docker build -t test:local .
docker run -p 8080:8080 test:local

# Commit and push
git add .
git commit -m "Description of changes"
git push origin feature/my-feature
```

---

## 📚 Additional Resources

### Documentation
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)

### Tutorials
- [Jenkins Pipeline Tutorial](https://www.jenkins.io/doc/book/pipeline/)
- [GitOps with ArgoCD](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

### Community
- [Jenkins Community Forums](https://community.jenkins.io/)
- [ArgoCD Slack](https://argoproj.github.io/community/join-slack)
- [Kubernetes Slack](https://slack.k8s.io/)

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Eknath DJ**
- GitHub: [@eknathdj](https://github.com/eknathdj)
- Repository: [devops-sample-app](https://github.com/eknathdj/devops-sample-app)

---

## 🙏 Acknowledgments

- Jenkins community for excellent CI/CD tooling
- ArgoCD team for GitOps innovation
- Kubernetes community for container orchestration
- All contributors to this project

---

## 📞 Support

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section
2. Search existing [GitHub Issues](https://github.com/eknathdj/devops-sample-app/issues)
3. Create a new issue with:
   - Clear description of the problem
   - Steps to reproduce
   - Error logs
   - Environment details (OS, versions, etc.)

---

**⭐ If this project helped you, please give it a star!**

---

*Last Updated: October 2025*