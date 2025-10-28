# 🚀 Jenkins DevSecOps Setup Guide

> Complete step-by-step guide to set up Jenkins with DevSecOps pipeline

## 📋 Prerequisites

- Docker Desktop installed and running
- Git configured with your credentials
- GitHub Personal Access Token ready
- DockerHub account credentials ready

---

## 🔧 Step 1: Start Jenkins with DevSecOps Tools (5 minutes)

### 1.1 Start Jenkins Container

```powershell
# Navigate to your project directory
cd "C:\Users\91967\OneDrive\Documents\GitHub\devops-sample-app"

# Start Jenkins with all security tools
docker-compose up -d

# Wait for Jenkins to start (this will take 3-5 minutes for first run)
Write-Host "⏳ Waiting for Jenkins to start..." -ForegroundColor Yellow
Start-Sleep 180

# Check if Jenkins is running
docker ps
```

### 1.2 Get Jenkins Admin Password

```powershell
# Get the initial admin password
$adminPassword = docker exec jenkins-devsecops cat /var/jenkins_home/secrets/initialAdminPassword
Write-Host "🔑 Jenkins Admin Password: $adminPassword" -ForegroundColor Green

# Copy to clipboard (optional)
$adminPassword | Set-Clipboard
Write-Host "📋 Password copied to clipboard!" -ForegroundColor Blue
```

### 1.3 Verify Security Tools Installation

```powershell
# Check if all security tools are installed in Jenkins
docker exec jenkins-devsecops bash -c "
echo '🔍 Verifying security tools installation:'
echo '✅ Gitleaks:' && gitleaks version
echo '✅ Trivy:' && trivy version | head -1
echo '✅ Hadolint:' && hadolint --version
echo '✅ Semgrep:' && semgrep --version
echo '✅ Checkov:' && checkov --version
echo '✅ detect-secrets:' && detect-secrets --version
echo '✅ Bandit:' && bandit --version
echo '✅ Safety:' && safety --version
echo '🎉 All security tools are ready!'
"
```

**Expected Output**: All tools should show their version numbers.

---

## 🌐 Step 2: Configure Jenkins Web Interface (10 minutes)

### 2.1 Access Jenkins

1. **Open browser**: Navigate to `http://localhost:8080`
2. **Enter admin password**: Use the password from Step 1.2
3. **Install suggested plugins**: Click "Install suggested plugins"
4. **Wait for installation**: This takes 2-3 minutes

### 2.2 Create Admin User

1. **Fill out the form**:
   - Username: `admin`
   - Password: `admin123` (or your preferred password)
   - Full name: `DevSecOps Admin`
   - Email: `admin@devsecops.local`

2. **Click "Save and Continue"**

3. **Jenkins URL**: Keep default `http://localhost:8080/`

4. **Click "Save and Finish"** → **"Start using Jenkins"**

### 2.3 Install Additional Security Plugins

1. **Go to**: Manage Jenkins → Plugins → Available plugins

2. **Search and install these plugins**:
   - ✅ **HTML Publisher Plugin** (for security reports)
   - ✅ **Warnings Next Generation Plugin** (for security scan results)
   - ✅ **Pipeline Stage View Plugin** (for pipeline visualization)
   - ✅ **Blue Ocean** (modern UI - optional)
   - ✅ **JUnit Plugin** (for test results)

3. **Click "Install without restart"**

4. **Wait for installation** (2-3 minutes)

---

## 🔐 Step 3: Configure Credentials (5 minutes)

### 3.1 Add GitHub Credentials

1. **Navigate to**: Manage Jenkins → Credentials → System → Global credentials (unrestricted)

2. **Click "Add Credentials"**

3. **Configure GitHub PAT**:
   - **Kind**: Username with password
   - **Scope**: Global
   - **Username**: `eknathdj` (your GitHub username)
   - **Password**: `your-github-personal-access-token`
   - **ID**: `github-creds`
   - **Description**: `GitHub Personal Access Token for DevSecOps`

4. **Click "Create"**

### 3.2 Add DockerHub Credentials

1. **Click "Add Credentials"** again

2. **Configure DockerHub**:
   - **Kind**: Username with password
   - **Scope**: Global
   - **Username**: `your-dockerhub-username`
   - **Password**: `your-dockerhub-password`
   - **ID**: `dockerhub-creds`
   - **Description**: `DockerHub Registry Credentials`

3. **Click "Create"**

---

## 🔄 Step 4: Create DevSecOps Pipeline (10 minutes)

### 4.1 Create New Pipeline Job

1. **Click "New Item"**

2. **Configure**:
   - **Name**: `devsecops-sample-app`
   - **Type**: Pipeline
   - **Click "OK"**

### 4.2 Configure Pipeline Settings

1. **General Tab**:
   - **Description**: `DevSecOps CI/CD Pipeline with Security Scanning`
   - ✅ **GitHub project**: `https://github.com/eknathdj/devops-sample-app`

2. **Build Triggers**:
   - ✅ **GitHub hook trigger for GITScm polling**
   - ✅ **Poll SCM**: `H/5 * * * *` (every 5 minutes)

3. **Pipeline Configuration**:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: `https://github.com/eknathdj/devops-sample-app`
   - **Credentials**: Select `github-creds`
   - **Branch Specifier**: `*/main`
   - **Script Path**: `Jenkinsfile.devsecops`

4. **Additional Behaviours** (click "Add"):
   - ✅ **Wipe out repository & force clone**
   - ✅ **Check out to specific local branch**: `main`

5. **Click "Save"**

### 4.3 Configure Pipeline Parameters

1. **Go back to pipeline configuration**

2. **Check "This project is parameterized"**

3. **Add String Parameters**:

   **Parameter 1**:
   - Name: `DOCKER_IMAGE`
   - Default Value: `eknathdj/devops-sample-app`
   - Description: `Docker image name`

   **Parameter 2**:
   - Name: `SECURITY_GATE_CRITICAL`
   - Default Value: `0`
   - Description: `Maximum critical vulnerabilities allowed`

   **Parameter 3**:
   - Name: `SECURITY_GATE_HIGH`
   - Default Value: `5`
   - Description: `Maximum high vulnerabilities allowed`

   **Parameter 4**:
   - Name: `SECURITY_GATE_MEDIUM`
   - Default Value: `10`
   - Description: `Maximum medium vulnerabilities allowed`

4. **Click "Save"**

---

## 🧪 Step 5: Test the DevSecOps Pipeline (15 minutes)

### 5.1 Run First Build

1. **Go to your pipeline**: `devsecops-sample-app`

2. **Click "Build with Parameters"**

3. **Keep default parameters** and **click "Build"**

4. **Monitor the build**:
   - Click on the build number (e.g., `#1`)
   - Click "Console Output"
   - Watch the security scans execute

### 5.2 Expected Pipeline Stages

You should see these stages executing:

```
🔧 Setup & Checkout (1-2 minutes)
├── Clean workspace
├── Configure Git
└── Checkout code

🔍 Pre-Build Security Scans (5-8 minutes)
├── 🔐 Secret Detection (Gitleaks + detect-secrets)
├── 📋 SAST Analysis (Semgrep)
└── 🛡️ Infrastructure Security (Checkov + kube-score)

🔨 Build & Test (2-3 minutes)
├── Build Docker image
└── Run application tests

🔍 Container Security Scans (8-12 minutes)
├── 🛡️ Trivy Vulnerability Scan
└── 🔍 Trivy Configuration Scan

📊 Security Report Generation (1-2 minutes)
├── Generate HTML reports
├── Archive security artifacts
└── Publish security dashboard

🚀 Deploy (2-3 minutes) [Only on main branch]
├── Push to DockerHub
├── Update Kubernetes manifests
└── Commit changes back to Git
```

### 5.3 Review Security Reports

After the build completes:

1. **Go to build page** (e.g., Build #1)

2. **Check "Build Artifacts"**:
   - `security-scan-results.tar.gz` - All security reports
   - `pipeline-success.txt` or `pipeline-failure.txt` - Build summary

3. **View Security Dashboard**:
   - Look for "DevSecOps Security Report" link
   - Review security metrics and findings

4. **Check Console Output** for security gate results:
   ```
   ✅ Secret Detection: No secrets detected
   ✅ SAST Analysis: 0 critical, 2 high issues
   ✅ Container Security: 0 critical, 3 high vulnerabilities
   ✅ All security gates passed!
   ```

---

## 🔧 Step 6: Configure GitHub Webhook (5 minutes)

### 6.1 Set Up Webhook for Automatic Builds

1. **Go to your GitHub repository**: `https://github.com/eknathdj/devops-sample-app`

2. **Settings** → **Webhooks** → **Add webhook**

3. **Configure webhook**:
   - **Payload URL**: `http://YOUR_IP:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Which events**: Just the push event
   - ✅ **Active**

4. **Click "Add webhook"**

### 6.2 Test Webhook (For Local Development)

If you're running locally, use ngrok for public access:

```powershell
# Install ngrok (if not installed)
choco install ngrok

# Expose Jenkins to internet
ngrok http 8080

# Use the ngrok URL in webhook
# Example: https://abc123.ngrok.io/github-webhook/
```

---

## 🎯 Step 7: Verify Complete Setup (5 minutes)

### 7.1 Test Automatic Build

1. **Make a small change** to README.md:
   ```powershell
   # Add a line to README.md
   echo "`n<!-- DevSecOps Pipeline Test -->" >> README.md
   
   # Commit and push
   git add README.md
   git commit -m "Test DevSecOps pipeline automation"
   git push origin main
   ```

2. **Check Jenkins**: A new build should start automatically

3. **Monitor the build** through all security stages

### 7.2 Verify Security Integration

1. **Check that all security tools run**:
   - Gitleaks secret detection
   - Semgrep SAST analysis
   - Trivy vulnerability scanning
   - Checkov IaC security
   - Hadolint Dockerfile linting

2. **Verify security gates work**:
   - Build should pass if within thresholds
   - Build should fail if security issues exceed limits

3. **Check security reports are generated**:
   - HTML security dashboard
   - JSON reports for each tool
   - Consolidated security summary

---

## 🎉 Success! Your DevSecOps Pipeline is Ready

### ✅ What You've Accomplished

1. **Jenkins with 8 Security Tools** running in Docker
2. **Automated DevSecOps Pipeline** with security gates
3. **GitHub Integration** with webhooks
4. **DockerHub Integration** for secure image publishing
5. **Comprehensive Security Reporting** with dashboards
6. **Security Gate Enforcement** with configurable thresholds

### 📊 Your Security Coverage

- **Secret Detection**: Gitleaks + detect-secrets
- **SAST Analysis**: Semgrep + Bandit
- **Container Security**: Trivy vulnerability + configuration scanning
- **IaC Security**: Checkov + kube-score
- **Dependency Scanning**: Safety + npm audit
- **Dockerfile Security**: Hadolint linting

### 🚀 Next Steps

1. **Fine-tune security thresholds** based on your risk tolerance
2. **Set up ArgoCD** for GitOps deployment
3. **Configure monitoring** and alerting for security events
4. **Train your team** on the DevSecOps workflow

---

## 🆘 Troubleshooting

### Common Issues

**Jenkins won't start**:
```powershell
# Check Docker logs
docker logs jenkins-devsecops

# Restart if needed
docker-compose restart
```

**Security tools not found**:
```powershell
# Rebuild container with tools
docker-compose down
docker-compose up --build -d
```

**Build fails at security stage**:
```powershell
# Check security tool logs in Jenkins console output
# Adjust security thresholds if needed
# Review security reports for specific issues
```

**GitHub webhook not working**:
- Check webhook URL is correct
- Verify Jenkins is accessible from internet (use ngrok for local)
- Check webhook delivery in GitHub settings

---

**🎯 Congratulations! You now have a production-ready DevSecOps pipeline!**