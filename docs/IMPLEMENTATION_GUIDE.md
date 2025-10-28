# 🚀 DevSecOps Implementation Guide

> Step-by-step guide to implement your DevSecOps pipeline from scratch

## 📋 Implementation Phases

This guide is organized into 5 phases, each building on the previous one:

1. **Phase 1**: Local Security Setup (30 minutes)
2. **Phase 2**: Security Tools Installation (45 minutes)
3. **Phase 3**: Jenkins DevSecOps Setup (60 minutes)
4. **Phase 4**: Pipeline Integration & Testing (45 minutes)
5. **Phase 5**: Production Deployment (30 minutes)

---

## 🎯 Phase 1: Local Security Setup (30 minutes)

### Step 1.1: Verify Repository Structure ✅

First, let's make sure all DevSecOps files are in place:

```bash
# Check if all security files exist
ls -la .gitleaks.toml                    # ✅ Should exist
ls -la .secrets.baseline                 # ✅ Should exist
ls -la .pre-commit-config.yaml          # ✅ Should exist
ls -la .trivyignore                      # ✅ Should exist
ls -la security/trivy-config.yaml       # ✅ Should exist
ls -la security/security-policies.yaml  # ✅ Should exist
ls -la scripts/security-scan.sh         # ✅ Should exist
ls -la scripts/security-scan.ps1        # ✅ Should exist
ls -la Jenkinsfile.devsecops            # ✅ Should exist
ls -la SECURITY.md                       # ✅ Should exist
```

**Expected Output**: All files should exist. If any are missing, they're already in your repository.

### Step 1.2: Make Scripts Executable ✅

```bash
# Make security scripts executable
chmod +x scripts/security-scan.sh
chmod +x scripts/security-scan.ps1

# Verify permissions
ls -la scripts/
```

**Expected Output**: Scripts should have execute permissions (x flag).

### Step 1.3: Create Security Reports Directory ✅

```bash
# Create directory for security reports
mkdir -p security-reports

# Add to .gitignore to avoid committing reports
echo "security-reports/" >> .gitignore
echo ".trivy/" >> .gitignore
```

**Checkpoint 1**: ✅ Repository structure verified, scripts executable, reports directory created.

---

## 🔧 Phase 2: Security Tools Installation (45 minutes)

### Step 2.1: Install Prerequisites ✅

**For Linux/macOS:**
```bash
# Update package manager
sudo apt update  # Ubuntu/Debian
# or
brew update      # macOS

# Install required packages
sudo apt install -y curl wget python3 python3-pip jq git  # Ubuntu/Debian
# or
brew install curl wget python3 jq git                     # macOS
```

**For Windows:**
```powershell
# Install Chocolatey (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install prerequisites
choco install git python3 jq -y
```

### Step 2.2: Install Security Tools Automatically ✅

**Option A: Use Our Installation Script (Recommended)**

```bash
# Linux/macOS - Run our comprehensive installation script
./scripts/security-scan.sh

# Windows PowerShell
.\scripts\security-scan.ps1
```

**Option B: Manual Installation (if script fails)**

```bash
# Install Gitleaks
curl -sSfL https://github.com/zricethezav/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz | tar -xz
sudo mv gitleaks /usr/local/bin/

# Install Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.46.0

# Install Hadolint
wget -O hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
chmod +x hadolint && sudo mv hadolint /usr/local/bin/

# Install Python security tools
pip3 install detect-secrets semgrep checkov bandit safety

# Install kube-score
wget -O kube-score.tar.gz https://github.com/zegl/kube-score/releases/download/v1.16.1/kube-score_1.16.1_linux_amd64.tar.gz
tar -xzf kube-score.tar.gz && sudo mv kube-score /usr/local/bin/
rm kube-score.tar.gz
```

### Step 2.3: Verify Tool Installation ✅

```bash
# Verify all security tools are installed
echo "🔍 Verifying security tools installation..."

gitleaks version          # Should show: v8.18.0
trivy version            # Should show: Version: 0.46.0
hadolint --version       # Should show: Haskell Dockerfile Linter 2.12.0
semgrep --version        # Should show: 1.x.x
checkov --version        # Should show: 2.4.9
detect-secrets --version # Should show: 1.4.0
bandit --version         # Should show: 1.x.x
safety --version         # Should show: 2.x.x

echo "✅ All tools installed successfully!"
```

**Expected Output**: All commands should return version numbers without errors.

**Checkpoint 2**: ✅ All security tools installed and verified.

---

## 🔒 Phase 3: Local Security Testing (30 minutes)

### Step 3.1: Initialize Security Baseline ✅

```bash
# Initialize detect-secrets baseline (if needed)
detect-secrets scan --baseline .secrets.baseline

# Verify baseline exists and is valid
cat .secrets.baseline | jq '.version'
```

**Expected Output**: Should show version "1.4.0" and no errors.

### Step 3.2: Test Individual Security Scans ✅

```bash
# Test secret detection
echo "🔐 Testing secret detection..."
gitleaks detect --source . --report-format json --report-path security-reports/test-gitleaks.json --exit-code 0
echo "✅ Gitleaks test completed"

# Test SAST scanning
echo "📋 Testing SAST scanning..."
semgrep --config=auto --json --output=security-reports/test-semgrep.json . || echo "⚠️ SAST issues found (normal)"
echo "✅ Semgrep test completed"

# Test Dockerfile linting
echo "🐳 Testing Dockerfile linting..."
hadolint Dockerfile --format json > security-reports/test-hadolint.json || echo "⚠️ Dockerfile issues found (normal)"
echo "✅ Hadolint test completed"

# Test IaC security
echo "🛡️ Testing IaC security..."
checkov -d k8s/ --framework kubernetes --output json --output-file security-reports/test-checkov.json || echo "⚠️ IaC issues found (normal)"
echo "✅ Checkov test completed"
```

### Step 3.3: Run Complete Security Scan ✅

```bash
# Run complete security scan
echo "🚀 Running complete security scan..."

# Linux/macOS
./scripts/security-scan.sh

# Windows PowerShell
# .\scripts\security-scan.ps1

echo "📊 Check security reports:"
ls -la security-reports/
```

**Expected Output**: 
- Script should complete without critical errors
- Multiple JSON report files should be generated
- Summary report should be created

**Checkpoint 3**: ✅ Local security scanning working, reports generated.

---

## 🔧 Phase 4: Pre-commit Hooks Setup (20 minutes)

### Step 4.1: Install Pre-commit Framework ✅

```bash
# Install pre-commit
pip3 install pre-commit

# Verify installation
pre-commit --version
```

### Step 4.2: Install and Test Hooks ✅

```bash
# Install pre-commit hooks
pre-commit install

# Install commit-msg hook (optional)
pre-commit install --hook-type commit-msg

# Test hooks on all files (first run will be slow)
echo "🔍 Testing pre-commit hooks (this may take a few minutes)..."
pre-commit run --all-files

echo "✅ Pre-commit hooks installed and tested"
```

### Step 4.3: Test Pre-commit with Dummy Commit ✅

```bash
# Create a test file
echo "# Test file" > test-security.md

# Add and try to commit (should trigger hooks)
git add test-security.md
git commit -m "Test pre-commit hooks"

# Clean up
rm test-security.md
git reset --soft HEAD~1
```

**Expected Output**: Pre-commit hooks should run and either pass or show specific issues.

**Checkpoint 4**: ✅ Pre-commit hooks installed and working.

---

## 🏗️ Phase 5: Jenkins DevSecOps Setup (60 minutes)

### Step 5.1: Start Jenkins with Security Tools ✅

Create `docker-compose.yml` for Jenkins with security tools:

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
      - ./scripts:/scripts:ro
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false
    command: >
      bash -c "
        apt-get update &&
        apt-get install -y docker.io curl wget python3 python3-pip jq &&
        
        # Install security tools
        curl -sSfL https://github.com/zricethezav/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz | tar -xz &&
        mv gitleaks /usr/local/bin/ &&
        
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.46.0 &&
        
        wget -O hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64 &&
        chmod +x hadolint && mv hadolint /usr/local/bin/ &&
        
        pip3 install detect-secrets semgrep checkov bandit safety &&
        
        git config --global --add safe.directory '*' &&
        /usr/local/bin/jenkins.sh
      "

volumes:
  jenkins_home:
```

```bash
# Start Jenkins
docker-compose up -d

# Wait for Jenkins to start
echo "⏳ Waiting for Jenkins to start (this may take 2-3 minutes)..."
sleep 120

# Get initial admin password
echo "🔑 Jenkins admin password:"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### Step 5.2: Configure Jenkins ✅

1. **Access Jenkins**: Open `http://localhost:8080`
2. **Enter admin password** from previous step
3. **Install suggested plugins**
4. **Create admin user**

### Step 5.3: Install Additional Jenkins Plugins ✅

Go to **Manage Jenkins** → **Plugins** → **Available plugins** and install:

- ✅ HTML Publisher Plugin
- ✅ Warnings Next Generation Plugin  
- ✅ Pipeline Stage View Plugin
- ✅ Blue Ocean (optional)

### Step 5.4: Add Jenkins Credentials ✅

**GitHub Credentials:**
1. Go to **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. Click **Add Credentials**
3. **Kind**: Username with password
4. **Username**: Your GitHub username
5. **Password**: Your GitHub Personal Access Token
6. **ID**: `github-creds`
7. **Description**: GitHub Personal Access Token

**DockerHub Credentials:**
1. Same path, click **Add Credentials**
2. **Kind**: Username with password  
3. **Username**: Your DockerHub username
4. **Password**: Your DockerHub password/token
5. **ID**: `dockerhub-creds`
6. **Description**: DockerHub Registry Credentials

### Step 5.5: Create DevSecOps Pipeline ✅

1. **Create New Item**:
   - Name: `devsecops-sample-app`
   - Type: **Pipeline**

2. **Configure Pipeline**:
   - **Description**: DevSecOps CI/CD Pipeline with Security Scanning
   - **Build Triggers**: ✅ GitHub hook trigger for GITScm polling
   - **Pipeline Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: `https://github.com/eknathdj/devops-sample-app`
   - **Credentials**: `github-creds`
   - **Branch**: `*/main`
   - **Script Path**: `Jenkinsfile.devsecops`

3. **Save** the pipeline

**Checkpoint 5**: ✅ Jenkins running with security tools, pipeline created.

---

## 🧪 Phase 6: Pipeline Testing (45 minutes)

### Step 6.1: Test Jenkins Security Tools ✅

```bash
# Test security tools in Jenkins container
docker exec jenkins bash -c "
echo '🔍 Testing security tools in Jenkins...'
gitleaks version
trivy version  
hadolint --version
semgrep --version
checkov --version
echo '✅ All tools working in Jenkins'
"
```

### Step 6.2: Run First Pipeline Build ✅

1. **Go to your pipeline** in Jenkins UI
2. **Click "Build Now"**
3. **Monitor the build** - it should go through these stages:
   - 🔧 Setup & Checkout
   - 🔍 Pre-Build Security Scans
   - 🔨 Build & Test  
   - 🔍 Container Security Scans
   - 📊 Security Report Generation

### Step 6.3: Review Security Reports ✅

After the build completes:

1. **Check Build Artifacts**:
   - Go to build → **Build Artifacts**
   - Download `security-scan-results.tar.gz`
   - Extract and review reports

2. **View Security Summary**:
   - Look for **DevSecOps Security Report** link
   - Review security metrics and findings

### Step 6.4: Fix Any Issues ✅

Common first-run issues and fixes:

**If Gitleaks fails:**
```bash
# Check what secrets were detected
# Add false positives to .gitleaks.toml allowlist
```

**If Trivy finds critical vulnerabilities:**
```bash
# Update Dockerfile base image
# Add justified ignores to .trivyignore
```

**If Semgrep finds critical issues:**
```bash
# Fix code issues or add ignore comments
# Adjust thresholds in Jenkinsfile.devsecops if needed
```

**Checkpoint 6**: ✅ Pipeline running successfully, security reports generated.

---

## 🚀 Phase 7: GitHub Integration (30 minutes)

### Step 7.1: Configure GitHub Webhook ✅

1. **Go to your GitHub repository**
2. **Settings** → **Webhooks** → **Add webhook**
3. **Payload URL**: `http://YOUR_JENKINS_IP:8080/github-webhook/`
4. **Content type**: `application/json`
5. **Events**: Just the push event
6. **Active**: ✅ Checked

**For local testing with ngrok:**
```bash
# Install ngrok
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update && sudo apt install ngrok

# Expose Jenkins
ngrok http 8080

# Use the ngrok URL in webhook: https://xxxx.ngrok.io/github-webhook/
```

### Step 7.2: Test Webhook Integration ✅

```bash
# Make a small change to trigger webhook
echo "# DevSecOps Pipeline Test" >> README.md
git add README.md
git commit -m "Test DevSecOps pipeline webhook"
git push origin main
```

**Expected Result**: Jenkins should automatically start a new build.

### Step 7.3: Monitor Automated Build ✅

1. **Check Jenkins** - new build should start automatically
2. **Monitor security scans** - all stages should pass
3. **Review artifacts** - security reports should be generated
4. **Check DockerHub** - new image should be pushed (if build succeeds)

**Checkpoint 7**: ✅ GitHub webhook working, automated builds triggered.

---

## 🎯 Phase 8: Production Readiness (30 minutes)

### Step 8.1: Configure Security Thresholds ✅

Edit `Jenkinsfile.devsecops` to adjust security gates for your needs:

```groovy
environment {
    // Adjust these based on your risk tolerance
    SECURITY_GATE_CRITICAL = "0"    # No critical vulnerabilities
    SECURITY_GATE_HIGH = "5"        # Max 5 high vulnerabilities  
    SECURITY_GATE_MEDIUM = "10"     # Max 10 medium vulnerabilities
}
```

### Step 8.2: Set Up Security Monitoring ✅

```bash
# Create monitoring script
cat > monitor-security.sh << 'EOF'
#!/bin/bash
# Security monitoring script

echo "📊 DevSecOps Security Dashboard"
echo "================================"

# Check latest security reports
if [ -d "security-reports" ]; then
    echo "📋 Latest Security Scan: $(ls -t security-reports/*.json | head -1 | xargs stat -c %y)"
    
    # Count vulnerabilities
    if [ -f "security-reports/trivy-report.json" ]; then
        CRITICAL=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' security-reports/trivy-report.json 2>/dev/null || echo "0")
        HIGH=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' security-reports/trivy-report.json 2>/dev/null || echo "0")
        echo "🔍 Vulnerabilities: Critical: $CRITICAL, High: $HIGH"
    fi
    
    # Check secrets
    if [ -f "security-reports/gitleaks-report.json" ]; then
        SECRETS=$(jq '. | length' security-reports/gitleaks-report.json 2>/dev/null || echo "0")
        echo "🔐 Secrets Detected: $SECRETS"
    fi
else
    echo "❌ No security reports found. Run security scan first."
fi
EOF

chmod +x monitor-security.sh
```

### Step 8.3: Document Your Setup ✅

```bash
# Create deployment documentation
cat > DEPLOYMENT.md << 'EOF'
# DevSecOps Deployment Guide

## Current Configuration

- **Jenkins**: http://localhost:8080
- **Pipeline**: devsecops-sample-app  
- **Security Tools**: Gitleaks, Trivy, Semgrep, Checkov, Hadolint
- **Security Gates**: Critical: 0, High: 5, Medium: 10
- **Reports**: security-reports/ directory

## Daily Operations

1. **Monitor Security Dashboard**: `./monitor-security.sh`
2. **Review Failed Builds**: Check Jenkins for security gate failures
3. **Update Security Tools**: Monthly tool updates
4. **Rotate Credentials**: Quarterly credential rotation

## Emergency Procedures

1. **Critical Vulnerability**: Stop deployment, patch immediately
2. **Secret Detected**: Rotate credentials, clean git history
3. **Pipeline Failure**: Check security reports, fix issues

EOF
```

**Checkpoint 8**: ✅ Production-ready DevSecOps pipeline configured.

---

## ✅ Final Verification Checklist

Run through this checklist to ensure everything is working:

### Local Environment ✅
- [ ] All security tools installed and working
- [ ] Pre-commit hooks installed and tested
- [ ] Security scans run successfully locally
- [ ] Reports generated in security-reports/

### Jenkins Environment ✅  
- [ ] Jenkins running with security tools installed
- [ ] DevSecOps pipeline created and configured
- [ ] GitHub and DockerHub credentials added
- [ ] Pipeline runs successfully with security scans

### Integration ✅
- [ ] GitHub webhook configured and working
- [ ] Automated builds triggered on push
- [ ] Security gates enforced (build fails on threshold breach)
- [ ] Security reports archived and accessible

### Security ✅
- [ ] No secrets detected in repository
- [ ] Vulnerability thresholds appropriate for your risk level
- [ ] Security baseline established and maintained
- [ ] Incident response procedures documented

---

## 🎉 Success! Your DevSecOps Pipeline is Ready

You now have a fully functional DevSecOps pipeline with:

- **🔐 Multi-layer security scanning** (secrets, SAST, container, IaC)
- **🛡️ Automated security gates** with configurable thresholds
- **📊 Comprehensive security reporting** and dashboards
- **🔄 Continuous integration** with GitHub webhooks
- **🚀 Secure deployment** pipeline with ArgoCD integration

## 📞 Next Steps

1. **Train your team** on the new DevSecOps workflow
2. **Set up monitoring** and alerting for security events
3. **Schedule regular** security tool updates
4. **Plan credential rotation** schedule
5. **Conduct security reviews** of the pipeline quarterly

## 🆘 Need Help?

If you encounter issues:

1. **Check the logs**: Jenkins build logs, Docker logs
2. **Review security reports**: Look for specific error messages
3. **Consult documentation**: SECURITY.md and README.md
4. **Test individually**: Run security tools manually to isolate issues

---

**🎯 Congratulations! You've successfully implemented a production-ready DevSecOps pipeline!**