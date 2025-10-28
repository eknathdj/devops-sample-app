#!/bin/bash

# DevSecOps Security Scanning Script
# This script runs comprehensive security scans for the DevOps pipeline

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_IMAGE="${DOCKER_IMAGE:-eknathdj/devops-sample-app}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
SECURITY_REPORTS_DIR="security-reports"
TRIVY_CACHE_DIR=".trivy"

# Security thresholds
CRITICAL_THRESHOLD=0
HIGH_THRESHOLD=5
MEDIUM_THRESHOLD=10

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_tool() {
    local tool=$1
    local install_cmd=$2
    
    if ! command -v "$tool" &> /dev/null; then
        log_warning "$tool not found. Installing..."
        eval "$install_cmd"
    else
        log_info "$tool is available"
    fi
}

install_security_tools() {
    log_info "Installing security scanning tools..."
    
    # Create reports directory
    mkdir -p "$SECURITY_REPORTS_DIR"
    mkdir -p "$TRIVY_CACHE_DIR"
    
    # Install gitleaks
    check_tool "gitleaks" "curl -sSfL https://github.com/zricethezav/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz | tar -xz && sudo mv gitleaks /usr/local/bin/"
    
    # Install trivy
    check_tool "trivy" "curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.46.0"
    
    # Install hadolint
    check_tool "hadolint" "wget -O hadolint https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64 && chmod +x hadolint && sudo mv hadolint /usr/local/bin/"
    
    # Install Python tools
    pip3 install --user detect-secrets semgrep checkov bandit safety || log_warning "Some Python tools failed to install"
    
    log_success "Security tools installation completed"
}

scan_secrets() {
    log_info "🔐 Running secret detection scans..."
    
    # Gitleaks scan
    log_info "Running gitleaks scan..."
    if gitleaks detect --source . --report-format json --report-path "$SECURITY_REPORTS_DIR/gitleaks-report.json" --exit-code 1; then
        log_success "No secrets detected by gitleaks"
    else
        log_error "Secrets detected by gitleaks! Check the report."
        return 1
    fi
    
    # detect-secrets scan
    log_info "Running detect-secrets scan..."
    if detect-secrets scan --baseline .secrets.baseline --force-use-all-plugins; then
        log_success "detect-secrets scan passed"
    else
        log_error "New secrets detected by detect-secrets!"
        return 1
    fi
    
    log_success "Secret detection completed"
}

scan_sast() {
    log_info "📋 Running Static Application Security Testing (SAST)..."
    
    # Semgrep scan
    log_info "Running Semgrep SAST scan..."
    semgrep --config=auto --json --output="$SECURITY_REPORTS_DIR/semgrep-report.json" . || log_warning "Semgrep found issues"
    
    # Count issues
    if [ -f "$SECURITY_REPORTS_DIR/semgrep-report.json" ]; then
        CRITICAL_COUNT=$(jq '[.results[] | select(.extra.severity == "ERROR")] | length' "$SECURITY_REPORTS_DIR/semgrep-report.json" 2>/dev/null || echo "0")
        HIGH_COUNT=$(jq '[.results[] | select(.extra.severity == "WARNING")] | length' "$SECURITY_REPORTS_DIR/semgrep-report.json" 2>/dev/null || echo "0")
        
        log_info "SAST Results: Critical: $CRITICAL_COUNT, High: $HIGH_COUNT"
        
        if [ "$CRITICAL_COUNT" -gt "$CRITICAL_THRESHOLD" ]; then
            log_error "Critical SAST issues exceed threshold ($CRITICAL_COUNT > $CRITICAL_THRESHOLD)"
            return 1
        fi
    fi
    
    # Bandit scan for Python (if applicable)
    if find . -name "*.py" -type f | head -1 | grep -q .; then
        log_info "Running Bandit Python security scan..."
        bandit -r . -f json -o "$SECURITY_REPORTS_DIR/bandit-report.json" || log_warning "Bandit found issues"
    fi
    
    log_success "SAST scanning completed"
}

scan_dockerfile() {
    log_info "🐳 Scanning Dockerfile security..."
    
    # Hadolint scan
    log_info "Running Hadolint Dockerfile scan..."
    hadolint Dockerfile --format json > "$SECURITY_REPORTS_DIR/hadolint-report.json" || log_warning "Dockerfile issues found"
    
    log_success "Dockerfile scanning completed"
}

scan_dependencies() {
    log_info "📦 Scanning dependencies for vulnerabilities..."
    
    # Safety scan for Python
    if [ -f "requirements.txt" ]; then
        log_info "Running Safety scan for Python dependencies..."
        safety check --json --output "$SECURITY_REPORTS_DIR/safety-report.json" || log_warning "Python dependency vulnerabilities found"
    fi
    
    # npm audit for Node.js
    if [ -f "package.json" ]; then
        log_info "Running npm audit for Node.js dependencies..."
        npm audit --json > "$SECURITY_REPORTS_DIR/npm-audit-report.json" || log_warning "Node.js dependency vulnerabilities found"
    fi
    
    # Go mod scan
    if [ -f "go.mod" ]; then
        log_info "Running Go module vulnerability scan..."
        go list -json -deps ./... | nancy sleuth > "$SECURITY_REPORTS_DIR/nancy-report.json" || log_warning "Go dependency vulnerabilities found"
    fi
    
    log_success "Dependency scanning completed"
}

scan_infrastructure() {
    log_info "🛡️ Scanning Infrastructure as Code..."
    
    # Checkov scan
    log_info "Running Checkov IaC scan..."
    checkov -d k8s/ --framework kubernetes --output json --output-file "$SECURITY_REPORTS_DIR/checkov-k8s-report.json" || log_warning "Kubernetes IaC issues found"
    checkov -f Dockerfile --framework dockerfile --output json --output-file "$SECURITY_REPORTS_DIR/checkov-docker-report.json" || log_warning "Dockerfile IaC issues found"
    
    # kube-score scan
    if command -v kube-score &> /dev/null; then
        log_info "Running kube-score analysis..."
        find k8s/ -name "*.yaml" -exec kube-score score {} \; > "$SECURITY_REPORTS_DIR/kube-score-report.txt" || log_warning "Kubernetes best practice issues found"
    fi
    
    log_success "Infrastructure scanning completed"
}

scan_container() {
    log_info "🔍 Scanning container image for vulnerabilities..."
    
    if [ -z "$DOCKER_IMAGE" ]; then
        log_error "DOCKER_IMAGE not set"
        return 1
    fi
    
    # Trivy vulnerability scan
    log_info "Running Trivy vulnerability scan on $DOCKER_IMAGE:$DOCKER_TAG..."
    trivy image \
        --cache-dir "$TRIVY_CACHE_DIR" \
        --format json \
        --output "$SECURITY_REPORTS_DIR/trivy-vuln-report.json" \
        --severity CRITICAL,HIGH,MEDIUM \
        "$DOCKER_IMAGE:$DOCKER_TAG"
    
    # Trivy configuration scan
    log_info "Running Trivy configuration scan..."
    trivy config \
        --cache-dir "$TRIVY_CACHE_DIR" \
        --format json \
        --output "$SECURITY_REPORTS_DIR/trivy-config-report.json" \
        --severity CRITICAL,HIGH \
        .
    
    # Check vulnerability counts
    if [ -f "$SECURITY_REPORTS_DIR/trivy-vuln-report.json" ]; then
        CRITICAL_VULNS=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "$SECURITY_REPORTS_DIR/trivy-vuln-report.json" 2>/dev/null || echo "0")
        HIGH_VULNS=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "$SECURITY_REPORTS_DIR/trivy-vuln-report.json" 2>/dev/null || echo "0")
        MEDIUM_VULNS=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM")] | length' "$SECURITY_REPORTS_DIR/trivy-vuln-report.json" 2>/dev/null || echo "0")
        
        log_info "Vulnerability Summary: Critical: $CRITICAL_VULNS, High: $HIGH_VULNS, Medium: $MEDIUM_VULNS"
        
        # Security gate checks
        if [ "$CRITICAL_VULNS" -gt "$CRITICAL_THRESHOLD" ]; then
            log_error "Critical vulnerabilities exceed threshold ($CRITICAL_VULNS > $CRITICAL_THRESHOLD)"
            return 1
        fi
        
        if [ "$HIGH_VULNS" -gt "$HIGH_THRESHOLD" ]; then
            log_error "High vulnerabilities exceed threshold ($HIGH_VULNS > $HIGH_THRESHOLD)"
            return 1
        fi
    fi
    
    log_success "Container scanning completed"
}

generate_report() {
    log_info "📊 Generating comprehensive security report..."
    
    cat > "$SECURITY_REPORTS_DIR/security-summary.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>DevSecOps Security Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f4f4f4; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border-left: 4px solid #007cba; }
        .success { border-left-color: #28a745; }
        .warning { border-left-color: #ffc107; }
        .error { border-left-color: #dc3545; }
        .metric { display: inline-block; margin: 10px; padding: 10px; background: #f8f9fa; border-radius: 3px; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🛡️ DevSecOps Security Scan Report</h1>
        <p><strong>Generated:</strong> $(date)</p>
        <p><strong>Image:</strong> ${DOCKER_IMAGE}:${DOCKER_TAG}</p>
    </div>
EOF
    
    # Add scan results to HTML report
    echo '<div class="section success"><h2>✅ Completed Scans</h2>' >> "$SECURITY_REPORTS_DIR/security-summary.html"
    
    # Check which scans completed successfully
    for report in gitleaks semgrep trivy-vuln hadolint checkov-k8s; do
        if [ -f "$SECURITY_REPORTS_DIR/${report}-report.json" ]; then
            echo "<p>✅ $report scan completed</p>" >> "$SECURITY_REPORTS_DIR/security-summary.html"
        else
            echo "<p>❌ $report scan missing</p>" >> "$SECURITY_REPORTS_DIR/security-summary.html"
        fi
    done
    
    echo '</div>' >> "$SECURITY_REPORTS_DIR/security-summary.html"
    echo '</body></html>' >> "$SECURITY_REPORTS_DIR/security-summary.html"
    
    # Generate markdown summary
    cat > "$SECURITY_REPORTS_DIR/SECURITY_SUMMARY.md" << EOF
# 🛡️ DevSecOps Security Report

**Date:** $(date)  
**Image:** ${DOCKER_IMAGE}:${DOCKER_TAG}  
**Scan Status:** $([ $? -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")

## 📊 Security Metrics

| Scan Type | Status | Critical | High | Medium |
|-----------|--------|----------|------|--------|
| Secrets | $([ -f "$SECURITY_REPORTS_DIR/gitleaks-report.json" ] && echo "✅" || echo "❌") | - | - | - |
| SAST | $([ -f "$SECURITY_REPORTS_DIR/semgrep-report.json" ] && echo "✅" || echo "❌") | $([ -f "$SECURITY_REPORTS_DIR/semgrep-report.json" ] && jq '[.results[] | select(.extra.severity == "ERROR")] | length' "$SECURITY_REPORTS_DIR/semgrep-report.json" 2>/dev/null || echo "0") | $([ -f "$SECURITY_REPORTS_DIR/semgrep-report.json" ] && jq '[.results[] | select(.extra.severity == "WARNING")] | length' "$SECURITY_REPORTS_DIR/semgrep-report.json" 2>/dev/null || echo "0") | - |
| Container | $([ -f "$SECURITY_REPORTS_DIR/trivy-vuln-report.json" ] && echo "✅" || echo "❌") | $([ -f "$SECURITY_REPORTS_DIR/trivy-vuln-report.json" ] && jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' "$SECURITY_REPORTS_DIR/trivy-vuln-report.json" 2>/dev/null || echo "0") | $([ -f "$SECURITY_REPORTS_DIR/trivy-vuln-report.json" ] && jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' "$SECURITY_REPORTS_DIR/trivy-vuln-report.json" 2>/dev/null || echo "0") | $([ -f "$SECURITY_REPORTS_DIR/trivy-vuln-report.json" ] && jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM")] | length' "$SECURITY_REPORTS_DIR/trivy-vuln-report.json" 2>/dev/null || echo "0") |
| IaC | $([ -f "$SECURITY_REPORTS_DIR/checkov-k8s-report.json" ] && echo "✅" || echo "❌") | - | - | - |

## 🎯 Security Gates

- **Critical Vulnerabilities:** ≤ $CRITICAL_THRESHOLD
- **High Vulnerabilities:** ≤ $HIGH_THRESHOLD  
- **Medium Vulnerabilities:** ≤ $MEDIUM_THRESHOLD

## 📋 Recommendations

1. **Keep Dependencies Updated:** Regularly update base images and application dependencies
2. **Implement Secret Management:** Use external secret managers (HashiCorp Vault, AWS Secrets Manager)
3. **Enable Runtime Security:** Deploy runtime security monitoring tools
4. **Network Segmentation:** Implement Kubernetes network policies
5. **Access Controls:** Apply RBAC and least-privilege principles

---
*Generated by DevSecOps Security Scanner*
EOF
    
    log_success "Security report generated at $SECURITY_REPORTS_DIR/"
}

# Main execution
main() {
    log_info "🚀 Starting DevSecOps security scanning..."
    
    local exit_code=0
    
    # Install tools
    install_security_tools
    
    # Run scans
    scan_secrets || exit_code=1
    scan_sast || exit_code=1
    scan_dockerfile || exit_code=1
    scan_dependencies || exit_code=1
    scan_infrastructure || exit_code=1
    
    # Container scan only if image exists
    if docker image inspect "$DOCKER_IMAGE:$DOCKER_TAG" &> /dev/null; then
        scan_container || exit_code=1
    else
        log_warning "Docker image $DOCKER_IMAGE:$DOCKER_TAG not found, skipping container scan"
    fi
    
    # Generate report
    generate_report
    
    if [ $exit_code -eq 0 ]; then
        log_success "🎉 All security scans completed successfully!"
    else
        log_error "💥 Some security scans failed. Check the reports for details."
    fi
    
    return $exit_code
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi