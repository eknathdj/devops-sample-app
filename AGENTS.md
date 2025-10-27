# AGENTS.md - DevOps Sample App

## Build/Test/Deploy Commands
- **Build Docker image**: `docker build -t devops-sample-app:local .`
- **Run locally**: `docker run -p 8080:8080 devops-sample-app:local`
- **Security checks**: `pre-commit run --all-files` (uses detect-secrets and gitleaks)
- **Deploy to k8s**: `kubectl apply -f k8s/product-service/` (or use ArgoCD sync)
- **ArgoCD sync**: `argocd app sync product-service`
- **View logs**: `kubectl logs -f deployment/product-service -n product-service`

## Architecture
- **CI/CD**: Jenkins pipeline (Jenkinsfile) builds Docker images, pushes to DockerHub, updates manifests
- **GitOps**: ArgoCD auto-syncs k8s manifests from `k8s/product-service/` directory
- **Container**: Multi-stage Node.js (18-alpine) build with non-root user, health checks
- **Deployment**: Product service with PostgreSQL database in `product-service` namespace
- **Manifests**: Numbered deployment order (00-namespace → 08-rbac), includes sealed secrets
- **Registry**: DockerHub (eknathdj/devops-sample-app) with build number tags

## Code Style & Conventions
- **YAML**: Use `---` separators, 2-space indentation, labels include app/version/environment
- **K8s naming**: `product-service` namespace, numbered manifest files (00, 02, 03, etc.)
- **Docker tags**: Never use `:latest` in k8s manifests; use `${BUILD_NUMBER}` from Jenkins
- **Security**: Pre-commit hooks scan for secrets; use SealedSecrets for sensitive data
- **Resources**: Always define resource limits/requests, use initContainers for DB readiness
