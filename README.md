# 🛡️ DevSecOps Sample App

> A complete DevSecOps CI/CD pipeline with security-first approach using Jenkins, ArgoCD, Docker, and Kubernetes

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](http://localhost:8082)
[![Security Scan](https://img.shields.io/badge/security-scanned-blue)](./docs/SECURITY.md)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

This repository showcases a **production-ready DevSecOps workflow** with automated security scanning, secure builds, containerization, and GitOps-based deployments following shift-left security principles.

---

## 🎯 Overview

This project implements a complete **DevSecOps CI/CD pipeline** with security-first approach:

- 🔐 **Multi-layer Security Scanning** - Secrets, SAST, container vulnerabilities, IaC security
- 🛡️ **Automated Security Gates** - Configurable thresholds and policy enforcement
- ✅ **Secure Container Builds** - Docker images with vulnerability scanning
- 🔍 **Pre-commit Security Hooks** - Prevent vulnerabilities from entering repository
- 📊 **Comprehensive Security Reports** - HTML dashboards and JSON reports
- 🚨 **Automated Incident Response** - Security issue handling and notifications

### **DevSecOps Tech Stack**
- **CI/CD**: Jenkins with DevSecOps pipeline
- **Security Scanning**: Trivy, Gitleaks, Semgrep, Checkov, Hadolint
- **Secret Management**: detect-secrets, SealedSecrets
- **Containerization**: Docker with security scanning
- **Orchestration**: Kubernetes with security policies
- **GitOps**: ArgoCD with security validation
- **Application**: Node.js with Express.js

---

## 🏗️ DevSecOps Architecture

```
┌─────────────┐    🔐 Pre-commit    ┌─────────────────────────────────┐
│   GitHub    │◄──── Hooks ────────│        Developer               │
│  (Source)   │                    │   🔍 Secret Scan               │
└─────────────┘                    │   📋 SAST Analysis             │
       │                           │   🛡️ IaC Security              │
       │ Webhook                   └─────────────────────────────────┘
       ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Jenkins DevSecOps Pipeline                      │
│  🔐 Secret Detection  │  📋 SAST Scan  │  🛡️ Container Security    │
│  • Gitleaks          │  • Semgrep      │  • Trivy Vulnerabilities  │
│  • detect-secrets    │  • Bandit       │  • Trivy Configuration    │
│                      │                 │  • Hadolint Dockerfile    │
│  🏗️ IaC Security     │  📦 Dependencies │  📊 Security Reports      │
│  • Checkov          │  • Safety        │  • HTML Dashboard         │
│  • kube-score       │  • npm audit     │  • JSON Reports           │
└─────────────────────────────────────────────────────────────────────┘
       │                           │
       │ Build & Push              │ Security Gates
       ▼                           ▼
┌─────────────┐              ┌─────────────┐
│  DockerHub  │              │   Security  │
│ (Registry)  │              │   Reports   │
└─────────────┘              └─────────────┘
       │
       │ Update Manifest
       ▼
┌─────────────┐
│   GitHub    │
│  (GitOps)   │
└─────────────┘
       │
       │ Sync with Security Validation
       ▼
┌─────────────┐      ┌─────────────────────────────────┐
│   ArgoCD    │─────▶│          Kubernetes             │
│  (Deploy)   │      │  🛡️ Network Policies           │
│             │      │  🔐 RBAC & Security Contexts   │
│             │      │  📊 Runtime Security Monitoring │
└─────────────┘      └─────────────────────────────────┘
```

---

## 🚀 Quick Start

### **Prerequisites**
- Docker Desktop installed and running
- Git configured
- GitHub account with repository access
- DockerHub account (optional)

### **1. Clone and Setup**
```bash
git clone https://github.com/eknathdj/devops-sample-app.git
cd devops-sample-app

# Test the application locally
npm install
npm start
# Visit http://localhost:8080
```

### **2. Start DevSecOps Jenkins**
```bash
# Start Jenkins with all security tools
docker-compose up -d

# Get admin password
docker exec jenkins-devsecops cat /var/jenkins_home/secrets/initialAdminPassword

# Access Jenkins at http://localhost:8081
```

### **3. Run Security Scans Locally**
```bash
# Windows
.\scripts\security-scan.ps1

# Linux/macOS  
./scripts/security-scan.sh

# Check reports
ls security-reports/
```

---

## 📚 Documentation

All detailed documentation is organized in the [`docs/`](docs/) folder:

### **📖 Setup Guides**
- **[📋 Implementation Guide](docs/IMPLEMENTATION_GUIDE.md)** - Complete step-by-step setup (4-5 hours)
- **[⚡ Next Steps](docs/NEXT_STEPS.md)** - Quick setup guide (2 hours)
- **[🔧 Jenkins Setup](docs/JENKINS_SETUP.md)** - Jenkins configuration details

### **🛡️ Security Documentation**
- **[🔒 Security Guide](docs/SECURITY.md)** - Comprehensive security procedures and policies

### **📋 Quick Reference**
| I want to... | Read this guide | Time needed |
|--------------|----------------|-------------|
| **Understand the project** | This README | 15 minutes |
| **Get it running quickly** | [Next Steps](docs/NEXT_STEPS.md) | 2 hours |
| **Set up for production** | [Implementation Guide](docs/IMPLEMENTATION_GUIDE.md) | 4-5 hours |
| **Configure Jenkins** | [Jenkins Setup](docs/JENKINS_SETUP.md) | 1 hour |
| **Understand security** | [Security Guide](docs/SECURITY.md) | 30 minutes |

---

## 🔄 DevSecOps Pipeline Workflow

### **Security-First Development Process**

1. **🔍 Pre-commit Security** - Local security hooks prevent issues
2. **🔐 Secret Detection** - Gitleaks + detect-secrets scan for exposed credentials
3. **📋 SAST Analysis** - Semgrep analyzes code for security vulnerabilities
4. **🛡️ IaC Security** - Checkov + kube-score validate infrastructure security
5. **🔨 Secure Build** - Docker image built with security best practices
6. **🔍 Container Security** - Trivy scans for vulnerabilities and misconfigurations
7. **🎯 Security Gates** - Automated pass/fail based on security thresholds
8. **📊 Security Reports** - Comprehensive dashboards and compliance reports
9. **🚀 Secure Deploy** - GitOps deployment with ArgoCD

### **Security Thresholds**
```yaml
Critical Vulnerabilities: 0     # Pipeline fails if any critical issues
High Vulnerabilities: 5         # Pipeline fails if more than 5 high issues
Medium Vulnerabilities: 10      # Pipeline fails if more than 10 medium issues
Secrets Detected: 0             # Pipeline fails if any secrets found
```

---

## 🛡️ Security Features

### **8 Security Tools Integrated**
- **🔐 Gitleaks** - Git repository secret scanner
- **🔍 Trivy** - Container vulnerability and configuration scanner
- **📋 Semgrep** - Static application security testing (SAST)
- **🛡️ Checkov** - Infrastructure as Code security scanner
- **🐳 Hadolint** - Dockerfile security linter
- **🔑 detect-secrets** - Secret baseline management
- **🐍 Bandit** - Python security linter
- **📦 Safety** - Python dependency vulnerability scanner

### **Security Coverage**
- ✅ **Secret Detection** - Prevent credential exposure
- ✅ **Code Security** - Static analysis for vulnerabilities
- ✅ **Container Security** - Image vulnerability scanning
- ✅ **Infrastructure Security** - Kubernetes and Docker security
- ✅ **Dependency Security** - Third-party package vulnerabilities
- ✅ **Configuration Security** - Security misconfigurations

---

## 🧪 Testing the Application

### **Local Development**
```bash
# Install dependencies
npm install

# Start the application
npm start

# Test endpoints
curl http://localhost:8080/health
curl http://localhost:8080/info
curl http://localhost:8080/metrics
```

### **Docker Testing**
```bash
# Build image
docker build -t devops-sample-app:test .

# Run container
docker run -p 8080:8080 devops-sample-app:test

# Test health check
curl http://localhost:8080/health
```

### **Security Testing**
```bash
# Run all security scans
./scripts/security-scan.sh  # Linux/macOS
.\scripts\security-scan.ps1  # Windows

# Check results
cat security-reports/SECURITY_SUMMARY.md
```

---

## 🔧 Troubleshooting

### **Common Issues**

**Pipeline fails immediately**:
- Check Jenkins logs: `docker logs jenkins-devsecops`
- Verify Git plugin is installed in Jenkins
- Ensure credentials are configured correctly

**Docker build fails**:
- Check if `package-lock.json` exists: `ls package-lock.json`
- Run `npm install` to generate lock file
- Test build locally: `docker build -t test .`

**Security scans fail**:
- Check if tools are installed: `gitleaks version`
- Review security reports in `security-reports/`
- Adjust security thresholds if needed

**For detailed troubleshooting**, see the [Implementation Guide](docs/IMPLEMENTATION_GUIDE.md#troubleshooting).

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Run security scans: `./scripts/security-scan.sh`
4. Commit changes: `git commit -m 'Add amazing feature'`
5. Push to branch: `git push origin feature/amazing-feature`
6. Open a Pull Request

### **Development Workflow**
- All commits must pass pre-commit security hooks
- All PRs must pass DevSecOps pipeline security gates
- Security issues must be addressed before merging

---

## 📊 Project Status

### **✅ Working Features**
- DevSecOps CI/CD pipeline with Jenkins
- 8 security tools integrated and working
- Automated security scanning and reporting
- Docker containerization with security scanning
- Kubernetes manifests with security policies
- GitOps deployment with ArgoCD
- Pre-commit security hooks

### **🎯 Security Metrics**
- **Security Tools**: 8 tools integrated
- **Security Coverage**: 100% (secrets, SAST, containers, IaC, dependencies)
- **Security Gates**: Enforced with configurable thresholds
- **Vulnerability Detection**: Real-time scanning and reporting

---

## 📞 Support

### **Documentation**
- **📚 Complete Guides**: See [`docs/`](docs/) folder
- **🔍 Troubleshooting**: [Implementation Guide](docs/IMPLEMENTATION_GUIDE.md#troubleshooting)
- **🛡️ Security Procedures**: [Security Guide](docs/SECURITY.md)

### **Getting Help**
1. Check the [troubleshooting section](#troubleshooting)
2. Review the appropriate guide in [`docs/`](docs/)
3. Search existing [GitHub Issues](https://github.com/eknathdj/devops-sample-app/issues)
4. Create a new issue with detailed information

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Eknath DJ**
- GitHub: [@eknathdj](https://github.com/eknathdj)
- Repository: [devops-sample-app](https://github.com/eknathdj/devops-sample-app)

---

**⭐ If this DevSecOps pipeline helped you, please give it a star!**

---

*🛡️ Secure by design, fast by default - DevSecOps made simple*
