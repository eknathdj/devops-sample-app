@echo off
echo ==========================================
echo Product Service Monitoring Quick Start
echo ==========================================
echo.

echo Checking Prometheus installation...
kubectl get prometheus -n monitoring >nul 2>&1
if errorlevel 1 (
    echo ERROR: Prometheus not found
    echo Install with: helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
    exit /b 1
)
echo [OK] Prometheus is installed
echo.

echo Getting Grafana credentials...
for /f "delims=" %%i in ('kubectl get secret -n monitoring prometheus-grafana -o jsonpath^="{.data.admin-password}"') do set ENCODED_PASS=%%i
echo Username: admin
echo Password: (decoding...)
echo %ENCODED_PASS% > temp_pass.txt
certutil -decode temp_pass.txt decoded_pass.txt >nul 2>&1
set /p GRAFANA_PASSWORD=<decoded_pass.txt
del temp_pass.txt decoded_pass.txt
echo Password: %GRAFANA_PASSWORD%
echo.

echo ==========================================
echo Starting port-forwards...
echo ==========================================
echo.
echo Grafana:      http://localhost:3000
echo Prometheus:   http://localhost:9090
echo AlertManager: http://localhost:9093
echo.

echo Starting Grafana...
start /B kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

echo Starting Prometheus...
start /B kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

echo Starting AlertManager...
start /B kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093

echo.
echo ==========================================
echo ALL SERVICES STARTED!
echo ==========================================
echo.
echo Quick Links:
echo   - Grafana:    http://localhost:3000 (admin / %GRAFANA_PASSWORD%)
echo   - Prometheus: http://localhost:9090/targets
echo   - Alerts:     http://localhost:9090/alerts
echo.
echo Press any key to stop all services...
pause >nul

echo.
echo Stopping port-forwards...
taskkill /FI "WINDOWTITLE eq kubectl*" /F >nul 2>&1
echo Done!
