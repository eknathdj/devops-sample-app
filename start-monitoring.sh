#!/bin/bash

# Product Service Monitoring - Quick Start Script

echo "=========================================="
echo "Product Service Monitoring Quick Start"
echo "=========================================="
echo ""

# Check if Prometheus is installed
echo "🔍 Checking Prometheus installation..."
if kubectl get prometheus -n monitoring &> /dev/null; then
    echo "✅ Prometheus is installed"
else
    echo "❌ Prometheus not found. Install with:"
    echo "   helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace"
    exit 1
fi

# Check if ServiceMonitor exists
echo "🔍 Checking ServiceMonitor..."
if kubectl get servicemonitor product-service-metrics -n product-service &> /dev/null; then
    echo "✅ ServiceMonitor configured"
else
    echo "❌ ServiceMonitor not found"
    exit 1
fi

# Get Grafana password
echo ""
echo "🔐 Getting Grafana credentials..."
GRAFANA_PASSWORD=$(kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
echo "   Username: admin"
echo "   Password: $GRAFANA_PASSWORD"

# Port-forward services
echo ""
echo "🚀 Starting port-forwards..."
echo "   Press Ctrl+C to stop all services"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping all port-forwards..."
    jobs -p | xargs kill 2>/dev/null
    exit 0
}

trap cleanup EXIT INT TERM

# Start port-forwards
echo "📊 Grafana:    http://localhost:3000"
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &> /dev/null &

echo "📈 Prometheus: http://localhost:9090"
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &> /dev/null &

echo "🔔 AlertManager: http://localhost:9093"
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093 &> /dev/null &

echo ""
echo "=========================================="
echo "✅ All services started!"
echo "=========================================="
echo ""
echo "📚 Quick Links:"
echo "   • Grafana Dashboard: http://localhost:3000 (admin / $GRAFANA_PASSWORD)"
echo "   • Prometheus Targets: http://localhost:9090/targets"
echo "   • Prometheus Alerts: http://localhost:9090/alerts"
echo "   • AlertManager: http://localhost:9093"
echo ""
echo "🔍 Next steps:"
echo "   1. Login to Grafana: http://localhost:3000"
echo "   2. Add Prometheus data source:"
echo "      URL: http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090"
echo "   3. Import dashboard from k8s/product-service/06-monitoring.yaml"
echo ""
echo "Press Ctrl+C to stop..."
echo ""

# Wait for Ctrl+C
wait
