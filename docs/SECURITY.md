# 🛡️ DevSecOps Security Guide

This document outlines the comprehensive security measures implemented in this DevOps pipeline, following shift-left security principles and industry best practices.

## 📋 Table of Contents

- [Security Overview](#security-overview)
- [Security Scanning Tools](#security-scanning-tools)
- [Security Gates & Thresholds](#security-gates--thresholds)
- [Automated Security Scans](#automated-security-scans)
- [Manual Security Testing](#manual-security-testing)
- [Security Policies](#security-policies)
- [Incident Response](#incident-response)
- [Compliance & Standards](#compliance--standards)

## 🔍 Security Overview

Our DevSecOps pipeline implements multiple layers of security scanning and validation:

### Security Scanning Layers
1. **Pre-commit Hooks** - Prevent secrets and vulnerabilities from entering the repository
2. **CI/CD Pipeline Scans** - Comprehensive security validation during build process
3. **Container Security** - Image vulnerability and configuration scanning
4. **Infrastructure as Code** - Kubernetes and Dockerfile security validation
5. **Runtime Security** - Continuous monitoring and threat detection

### Security-First Approach
- **Zero Trust Architecture** - No implicit trust, verify everything
- **Least Privilege Access** - Minimal required permissions
- **Defense in Depth** - Multiple security layers
- **Continuous Monitoring** - Real-time security validation

## 🛠️ Security Scanning Tools

### Secret Detection
- **Gitleaks** - Git repository secret scanner
  - Configuration: `.gitleaks.toml`
  - Detects AWS keys, GitHub tokens, private keys, and custom patterns
  - Runs in pre-commit hooks and CI/CD pipeline

- **detect-secrets** - Baseline secret detection
  - Configuration: `.secrets.baseline`
  - Prevents new secrets from being committed
  - Supports multiple detection plugins

### Static Application Security Testing (SAST)
- **Semgrep** - Code security analysis
  - Rules: OWASP Top 10, CWE Top 25, security-audit
  - Language support: Python, JavaScript, Go, Java, and more
  - Custom rule configuration available

- **Bandit** - Python security linter
  - Identifies common security issues in Python code
  - Integrated with CI/CD pipeline for Python projects

### Container Security
- **Trivy** - Comprehensive container scanner
  - Configuration: `security/trivy-config.yaml`
  - Scans for vulnerabilities, secrets, and misconfigurations
  - Supports multiple output formats (JSON, SARIF, HTML)
  - Cache optimization for faster scans

- **Hadolint** - Dockerfile linter
  - Best practice validation for Dockerfiles
  - Security-focused rule set
  - Integration with pre-commit hooks

### Infrastructure as Code (IaC)
- **Checkov** - IaC security scanner
  - Supports Kubernetes, Terraform, Dockerfile
  - 1000+ built-in policies
  - Custom policy support

- **kube-score** - Kubernetes best practices
  - Security and reliability recommendations
  - Pod security standards validation
  - Network policy recommendations

### Dependency Scanning
- **Safety** - Python dependency vulnerability scanner
- **npm audit** - Node.js dependency security audit
- **Nancy** - Go module vulnerability scanner

## 🎯 Security Gates & Thresholds

### Vulnerability Thresholds
```yaml
Critical: 0     # No critical vulnerabilities allowed
High: 5         # Maximum 5 high severity vulnerabilities  
Medium: 10      # Maximum 10 medium severity vulnerabilities
Low: 50         # Maximum 50 low severity vulnerabilities
```

### SAST Thresholds
```yaml
Critical: 0     # No critical SAST issues allowed
High: 3         # Maximum 3 high severity SAST issues
Medium: 10      # Maximum 10 medium severity SAST issues
```

### Secret Detection
```yaml
Secrets: 0      # No secrets allowed in repository
```

### License Compliance
**Forbidden Licenses:**
- GPL-3.0, AGPL-3.0, LGPL-3.0

**Allowed Licenses:**
- MIT, Apache-2.0, BSD-3-Clause, ISC

## 🔄 Automated Security Scans

### Pre-commit Hooks (`.pre-commit-config.yaml`)
Runs before each commit to prevent security issues:
- Secret detection (gitleaks, detect-secrets)
- Dockerfile linting (hadolint)
- YAML/JSON validation
- Large file detection
- Private key detection
- IaC security scanning (checkov)

### CI/CD Pipeline Security Stages

#### 1. Pre-Build Security Scans
- **Secret Detection**: Gitleaks + detect-secrets
- **SAST Analysis**: Semgrep code scanning
- **IaC Security**: Checkov + kube-score validation

#### 2. Build & Test
- Secure Docker image building
- Application security testing
- Dependency vulnerability scanning

#### 3. Container Security Scans
- **Trivy Vulnerability Scan**: OS and library vulnerabilities
- **Trivy Configuration Scan**: Container misconfigurations
- **License Compliance**: Dependency license validation

#### 4. Security Report Generation
- Consolidated security dashboard
- Vulnerability metrics and trends
- Compliance status reporting

### Security Scanning Scripts

#### PowerShell Script (`scripts/security-scan.ps1`)
**Features:**
- Cross-platform Windows support
- Automated tool installation via Chocolatey
- Comprehensive vulnerability scanning
- Security gate enforcement
- HTML and Markdown report generation

**Usage:**
```powershell
.\scripts\security-scan.ps1 -DockerImage "myapp" -DockerTag "v1.0" -CriticalThreshold 0
```

#### Bash Script (`scripts/security-scan.sh`)
**Features:**
- Linux/Unix environment support
- Automated tool installation
- Parallel scanning capabilities
- JSON report aggregation
- Security metrics calculation

**Usage:**
```bash
export DOCKER_IMAGE="myapp"
export DOCKER_TAG="v1.0"
./scripts/security-scan.sh
```

## 🧪 Manual Security Testing

### Running Individual Scans

#### Secret Detection
```bash
# Gitleaks scan
gitleaks detect --source . --report-format json --report-path gitleaks-report.json

# detect-secrets scan  
detect-secrets scan --baseline .secrets.baseline
```

#### SAST Analysis
```bash
# Semgrep security scan
semgrep --config=auto --json --output=semgrep-report.json .

# Bandit Python scan
bandit -r . -f json -o bandit-report.json
```

#### Container Security
```bash
# Trivy vulnerability scan
trivy image --format json --output trivy-report.json myapp:latest

# Trivy configuration scan
trivy config --format json --output trivy-config-report.json .
```

#### Infrastructure Security
```bash
# Checkov IaC scan
checkov -d k8s/ --framework kubernetes --output json

# kube-score analysis
kube-score score k8s/*.yaml
```

### Security Report Locations
- **Reports Directory**: `security-reports/`
- **Individual Reports**: `*-report.json`
- **Summary Reports**: `security-summary.html`, `SECURITY_SUMMARY.md`
- **Jenkins Artifacts**: Archived in build artifacts

## 📜 Security Policies

### Configuration Files
- **Trivy Config**: `security/trivy-config.yaml`
- **Gitleaks Config**: `.gitleaks.toml`
- **Security Policies**: `security/security-policies.yaml`
- **Trivy Ignore**: `.trivyignore`

### Policy Enforcement
- **Automated Enforcement**: CI/CD pipeline security gates
- **Manual Review**: Security team approval for exceptions
- **Regular Updates**: Monthly policy review and updates

### Compliance Standards
- **CIS Kubernetes Benchmark v1.6.0**
- **NIST Cybersecurity Framework v1.1**
- **OWASP Top 10 2021**
- **CWE Top 25**

## 🚨 Incident Response

### Immediate Actions for Security Issues

#### Critical Vulnerabilities Detected
1. **Stop Deployment**: Halt pipeline execution
2. **Assess Impact**: Determine affected systems
3. **Apply Patches**: Update vulnerable components
4. **Verify Fix**: Re-run security scans
5. **Document**: Record incident and resolution

#### Secrets Detected in Repository
1. **Rotate Credentials**: Immediately invalidate exposed secrets
2. **Update Secret Managers**: Deploy new credentials
3. **Clean Git History**: Remove secrets from repository history
4. **Audit Access**: Review who had access to exposed secrets
5. **Implement Prevention**: Strengthen secret detection

### Git History Cleanup
```bash
# Using git-filter-repo (recommended)
git filter-repo --invert-paths --path k8s/product-service/01-secrets.yaml

# Using BFG Repo Cleaner
java -jar bfg.jar --delete-files secrets.yaml repo.git
```

### Emergency Contacts
- **Security Team**: security@company.com
- **DevOps Team**: devops@company.com
- **On-call Engineer**: +1-XXX-XXX-XXXX

## 🔧 Configuration Management

### Tool Versions
- **Gitleaks**: v8.18.0
- **Trivy**: v0.46.0
- **Hadolint**: v2.12.0
- **Semgrep**: Latest
- **Checkov**: v2.4.9

### Update Schedule
- **Security Tools**: Monthly updates
- **Vulnerability Database**: Daily updates
- **Policy Rules**: Quarterly review

### Environment Variables
```bash
# Docker configuration
DOCKER_IMAGE="eknathdj/devops-sample-app"
DOCKER_TAG="latest"

# Security thresholds
CRITICAL_THRESHOLD=0
HIGH_THRESHOLD=5
MEDIUM_THRESHOLD=10

# Tool configuration
TRIVY_CACHE_DIR=".trivy"
SECURITY_REPORTS_DIR="security-reports"
```

## 📊 Security Metrics & Monitoring

### Key Performance Indicators (KPIs)
- **Mean Time to Detection (MTTD)**: < 1 hour
- **Mean Time to Resolution (MTTR)**: < 4 hours
- **Security Scan Coverage**: 100%
- **False Positive Rate**: < 5%

### Monitoring Dashboards
- **Vulnerability Trends**: Track vulnerability counts over time
- **Security Gate Success Rate**: Monitor pipeline security gate pass/fail rates
- **Tool Performance**: Scan duration and success metrics
- **Compliance Status**: Real-time compliance posture

### Alerting
- **Critical Vulnerabilities**: Immediate Slack/email alerts
- **Security Gate Failures**: Pipeline failure notifications
- **Tool Failures**: Monitoring system alerts
- **Policy Violations**: Security team notifications

## 🎓 Security Training & Best Practices

### Developer Guidelines
1. **Never commit secrets** - Use environment variables or secret managers
2. **Regular dependency updates** - Keep libraries and base images current
3. **Secure coding practices** - Follow OWASP guidelines
4. **Code review focus** - Include security considerations in reviews
5. **Incident reporting** - Report security concerns immediately

### Security Champions Program
- **Monthly Security Reviews**: Team security discussions
- **Security Training**: Regular security awareness sessions
- **Threat Modeling**: Application security design reviews
- **Security Testing**: Hands-on security tool training

---

## 📞 Support & Resources

### Documentation
- [OWASP DevSecOps Guideline](https://owasp.org/www-project-devsecops-guideline/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Controls](https://www.cisecurity.org/controls/)

### Internal Resources
- **Security Wiki**: `https://wiki.company.com/security`
- **DevSecOps Playbook**: `https://playbook.company.com/devsecops`
- **Security Training**: `https://training.company.com/security`

### Tool Documentation
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Gitleaks Documentation](https://github.com/zricethezav/gitleaks)
- [Semgrep Documentation](https://semgrep.dev/docs/)
- [Checkov Documentation](https://www.checkov.io/1.Welcome/Quick%20Start.html)

---

*Last Updated: October 28, 2025*  
*Document Version: 2.0*  
*Next Review: January 28, 2026*
