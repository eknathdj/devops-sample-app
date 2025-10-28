# DevSecOps Security Scanning PowerShell Script for Windows
# Simplified version for Windows environment

param(
    [string]$DockerImage = "eknathdj/devops-sample-app",
    [string]$DockerTag = "latest",
    [string]$ReportsDir = "security-reports"
)

# Set error action preference
$ErrorActionPreference = "Continue"

# Create reports directory
if (!(Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
}

# Logging functions
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Install-SecurityTools {
    Write-Info "Installing security scanning tools for Windows..."
    
    # Check if Chocolatey is installed
    if (!(Test-Command "choco")) {
        Write-Warning "Chocolatey not found. Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
    
    # Install basic tools via Chocolatey
    $tools = @("git", "jq")
    foreach ($tool in $tools) {
        if (!(Test-Command $tool)) {
            Write-Info "Installing $tool..."
            choco install $tool -y
        }
    }
    
    # Install Python tools
    if (Test-Command "pip") {
        Write-Info "Installing Python security tools..."
        pip install detect-secrets semgrep checkov bandit safety
    } else {
        Write-Warning "Python/pip not found. Please install Python first."
    }
    
    # Download Gitleaks for Windows
    if (!(Test-Path "gitleaks.exe")) {
        Write-Info "Downloading Gitleaks for Windows..."
        $gitleaksUrl = "https://github.com/zricethezav/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_windows_x64.zip"
        Invoke-WebRequest -Uri $gitleaksUrl -OutFile "gitleaks.zip"
        Expand-Archive -Path "gitleaks.zip" -DestinationPath "." -Force
        Remove-Item "gitleaks.zip"
    }
    
    # Download Trivy for Windows
    if (!(Test-Path "trivy.exe")) {
        Write-Info "Downloading Trivy for Windows..."
        $trivyUrl = "https://github.com/aquasecurity/trivy/releases/download/v0.46.0/trivy_0.46.0_windows-64bit.zip"
        Invoke-WebRequest -Uri $trivyUrl -OutFile "trivy.zip"
        Expand-Archive -Path "trivy.zip" -DestinationPath "." -Force
        Remove-Item "trivy.zip"
    }
    
    # Download Hadolint for Windows
    if (!(Test-Path "hadolint.exe")) {
        Write-Info "Downloading Hadolint for Windows..."
        $hadolintUrl = "https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Windows-x86_64.exe"
        Invoke-WebRequest -Uri $hadolintUrl -OutFile "hadolint.exe"
    }
    
    Write-Success "Security tools installation completed"
}

function Test-SecretScan {
    Write-Info "🔐 Running secret detection scans..."
    
    # Check for gitleaks
    if (Test-Path "gitleaks.exe") {
        Write-Info "Running gitleaks scan..."
        try {
            & .\gitleaks.exe detect --source . --report-format json --report-path "$ReportsDir\gitleaks-report.json" --exit-code 0
            Write-Success "Gitleaks scan completed"
        }
        catch {
            Write-Warning "Gitleaks scan had issues, but continuing..."
        }
    } else {
        Write-Warning "Gitleaks not found. Please run Install-SecurityTools first."
    }
    
    # detect-secrets scan
    if (Test-Command "detect-secrets") {
        Write-Info "Running detect-secrets scan..."
        try {
            detect-secrets scan --baseline .secrets.baseline --force-use-all-plugins
            Write-Success "detect-secrets scan completed"
        }
        catch {
            Write-Warning "detect-secrets scan had issues, but continuing..."
        }
    }
    
    Write-Success "Secret detection completed"
}

function Test-SASTScan {
    Write-Info "📋 Running Static Application Security Testing (SAST)..."
    
    # Semgrep scan
    if (Test-Command "semgrep") {
        Write-Info "Running Semgrep SAST scan..."
        try {
            semgrep --config=auto --json --output="$ReportsDir\semgrep-report.json" .
            Write-Success "Semgrep scan completed"
        }
        catch {
            Write-Warning "Semgrep scan had issues, but continuing..."
        }
    }
    
    # Bandit scan for Python
    if ((Get-ChildItem -Recurse -Filter "*.py").Count -gt 0 -and (Test-Command "bandit")) {
        Write-Info "Running Bandit Python security scan..."
        try {
            bandit -r . -f json -o "$ReportsDir\bandit-report.json"
            Write-Success "Bandit scan completed"
        }
        catch {
            Write-Warning "Bandit scan had issues, but continuing..."
        }
    }
    
    Write-Success "SAST scanning completed"
}

function Test-DockerfileScan {
    Write-Info "🐳 Scanning Dockerfile security..."
    
    # Check if hadolint is available
    if (Test-Path "hadolint.exe") {
        Write-Info "Running Hadolint Dockerfile scan..."
        try {
            & .\hadolint.exe Dockerfile --format json > "$ReportsDir\hadolint-report.json"
            Write-Success "Hadolint scan completed"
        }
        catch {
            Write-Warning "Hadolint scan had issues, but continuing..."
        }
    } else {
        Write-Warning "Hadolint not found. Please run Install-SecurityTools first."
    }
    
    Write-Success "Dockerfile scanning completed"
}

function Test-ContainerScan {
    Write-Info "🔍 Scanning container image for vulnerabilities..."
    
    if (!$DockerImage) {
        Write-Error "DockerImage parameter not set"
        return
    }
    
    # Check if Trivy is available
    if (Test-Path "trivy.exe") {
        Write-Info "Running Trivy vulnerability scan on ${DockerImage}:${DockerTag}..."
        
        try {
            # Configuration scan (works without Docker image)
            & .\trivy.exe config --format json --output "$ReportsDir\trivy-config-report.json" --severity CRITICAL,HIGH .
            Write-Success "Trivy configuration scan completed"
        }
        catch {
            Write-Warning "Trivy config scan had issues, but continuing..."
        }
        
        # Try vulnerability scan if Docker image exists
        try {
            docker image inspect "${DockerImage}:${DockerTag}" | Out-Null
            & .\trivy.exe image --format json --output "$ReportsDir\trivy-vuln-report.json" --severity CRITICAL,HIGH,MEDIUM "${DockerImage}:${DockerTag}"
            Write-Success "Trivy vulnerability scan completed"
        }
        catch {
            Write-Warning "Docker image not found or Trivy vulnerability scan failed, skipping..."
        }
    } else {
        Write-Warning "Trivy not found. Please run Install-SecurityTools first."
    }
    
    Write-Success "Container scanning completed"
}

function Test-InfrastructureScan {
    Write-Info "🛡️ Scanning Infrastructure as Code..."
    
    # Checkov scan
    if (Test-Command "checkov") {
        Write-Info "Running Checkov IaC scan..."
        try {
            if (Test-Path "k8s") {
                checkov -d k8s\ --framework kubernetes --output json --output-file "$ReportsDir\checkov-k8s-report.json"
            }
            if (Test-Path "Dockerfile") {
                checkov -f Dockerfile --framework dockerfile --output json --output-file "$ReportsDir\checkov-docker-report.json"
            }
            Write-Success "Checkov scan completed"
        }
        catch {
            Write-Warning "Checkov scan had issues, but continuing..."
        }
    }
    
    Write-Success "Infrastructure scanning completed"
}

function New-SecurityReport {
    Write-Info "📊 Generating security report..."
    
    $reportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Generate simple text report
    $report = @"
# DevSecOps Security Report

Generated: $reportDate
Image: ${DockerImage}:${DockerTag}

## Scan Results

"@
    
    # Check for report files
    $reportFiles = @(
        "gitleaks-report.json",
        "semgrep-report.json", 
        "trivy-vuln-report.json",
        "trivy-config-report.json",
        "hadolint-report.json",
        "checkov-k8s-report.json",
        "checkov-docker-report.json"
    )
    
    foreach ($file in $reportFiles) {
        $status = if (Test-Path "$ReportsDir\$file") { "✅ Generated" } else { "❌ Missing" }
        $report += "- $file : $status`n"
    }
    
    $report += @"

## Next Steps

1. Review individual JSON reports in the security-reports/ directory
2. Address any critical or high severity findings
3. Update security baselines as needed
4. Integrate with CI/CD pipeline

Generated by DevSecOps Security Scanner (Windows)
"@
    
    $report | Out-File "$ReportsDir\SECURITY_SUMMARY.md" -Encoding UTF8
    
    Write-Success "Security report generated at $ReportsDir\SECURITY_SUMMARY.md"
}

# Main execution
function Start-SecurityScan {
    Write-Info "🚀 Starting DevSecOps security scanning on Windows..."
    
    # Install tools
    Install-SecurityTools
    
    # Run scans
    Test-SecretScan
    Test-SASTScan
    Test-DockerfileScan
    Test-InfrastructureScan
    Test-ContainerScan
    
    # Generate report
    New-SecurityReport
    
    Write-Success "🎉 Security scanning completed! Check $ReportsDir\ for results."
    
    # Show summary
    if (Test-Path "$ReportsDir\SECURITY_SUMMARY.md") {
        Write-Info "📋 Security Summary:"
        Get-Content "$ReportsDir\SECURITY_SUMMARY.md"
    }
}

# Run if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Start-SecurityScan
}