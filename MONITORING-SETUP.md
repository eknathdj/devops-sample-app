# 📊 Monitoring Setup Guide - Product Service

## 🎯 Overview

Your monitoring stack is **already installed** with:
- ✅ **Prometheus** - Metrics collection and alerting
- ✅ **Grafana** - Visualization dashboards
- ✅ **AlertManager** - Alert routing and notification
- ✅ **ServiceMonitor** - Auto-discovery of product-service metrics
- ✅ **PrometheusRule** - Pre-configured alerts

---

## 🔍 Current Status

```bash
# Check Prometheus Operator
kubectl get prometheus -n monitoring

# Check monitoring pods
kubectl get pods -n monitoring

# Check ServiceMonitor (scrapes product-service metrics)
kubectl get servicemonitor -n product-service

# Check PrometheusRule (alerts)
kubectl get prometheusrule -n product-service
```

**Expected Output:**
```
NAME                                    VERSION   DESIRED   READY
prometheus-kube-prometheus-prometheus   v3.7.1    1         1
```

---

## 📈 Accessing Dashboards

### **1. Access Grafana**

```bash
# Port-forward Grafana to localhost
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Open browser: http://localhost:3000
```

**Default Credentials:**
- Username: `admin`
- Password: Get with this command:
```bash
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode && echo
```

---

### **2. Access Prometheus UI**

```bash
# Port-forward Prometheus to localhost
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Open browser: http://localhost:9090
```

---

### **3. Access AlertManager**

```bash
# Port-forward AlertManager
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093

# Open browser: http://localhost:9093
```

---

## 🎨 Setting Up Grafana Dashboard

### **Option 1: Import Pre-configured Dashboard (Recommended)**

The product-service dashboard is already deployed as a ConfigMap.

1. **Login to Grafana** (http://localhost:3000)

2. **Add Prometheus Data Source:**
   - Click **⚙️ Configuration** → **Data Sources**
   - Click **Add data source**
   - Select **Prometheus**
   - URL: `http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090`
   - Click **Save & Test** (should show green success)

3. **Import Dashboard:**
   - Click **+** → **Import**
   - Click **Upload JSON file**
   - Copy the dashboard JSON from the ConfigMap:
     ```bash
     kubectl get configmap product-service-dashboard -n product-service -o jsonpath='{.data.product-service-dashboard\.json}' > dashboard.json
     ```
   - Upload `dashboard.json`
   - Select Prometheus data source
   - Click **Import**

---

### **Option 2: Use Community Dashboards**

**Kubernetes Cluster Monitoring:**
- Dashboard ID: **15757** (Kubernetes / Views / Global)
- Dashboard ID: **15758** (Kubernetes / Views / Namespaces)
- Dashboard ID: **15759** (Kubernetes / Views / Pods)

**PostgreSQL Monitoring:**
- Dashboard ID: **9628** (PostgreSQL Database)

**Import Steps:**
1. Grafana → **+** → **Import**
2. Enter Dashboard ID
3. Click **Load**
4. Select Prometheus data source
5. Click **Import**

---

## 🔔 Verify Metrics Collection

### **Check if Prometheus is scraping product-service**

```bash
# Port-forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Open: http://localhost:9090/targets
# Search for: product-service
# Status should be: UP (green)
```

### **Query metrics in Prometheus**

Go to http://localhost:9090/graph and try these queries:

```promql
# Check if metrics endpoint is reachable
up{job="product-service"}

# Request rate
rate(http_requests_total{job="product-service"}[5m])

# Error rate
sum(rate(http_requests_total{job="product-service", status=~"5.."}[5m])) 
/ 
sum(rate(http_requests_total{job="product-service"}[5m]))

# Pod memory usage
container_memory_working_set_bytes{namespace="product-service", pod=~"product-service-.*"}

# Pod CPU usage
rate(container_cpu_usage_seconds_total{namespace="product-service", pod=~"product-service-.*"}[5m])
```

---

## 🚨 Configured Alerts

Your product-service has these alerts pre-configured:

### **Critical Alerts:**
- ❌ **ServiceDown** - No instances reporting metrics
- ❌ **ErrorBudgetExhausted** - Error rate > 5%
- ❌ **InsufficientReplicas** - Less than 75% replicas available
- ❌ **DatabaseConnectionPoolExhausted** - No idle DB connections

### **Warning Alerts:**
- ⚠️ **ErrorBudgetBurnRateHigh** - Error rate > 2%
- ⚠️ **LatencySLOViolation** - p95 latency > 500ms
- ⚠️ **MemoryUsageHigh** - Memory > 85%
- ⚠️ **CPUThrottlingHigh** - CPU throttling > 10%
- ⚠️ **DatabaseSlowQueries** - p95 query time > 2s
- ⚠️ **OrderProcessingBacklog** - Queue > 100 orders

### **Info Alerts:**
- ℹ️ **LowInventoryAlert** - Product inventory < 10

---

## 🔧 Troubleshooting

### **Issue: ServiceMonitor not picking up targets**

**Check ServiceMonitor configuration:**
```bash
kubectl describe servicemonitor product-service-metrics -n product-service
```

**Verify Service has correct labels:**
```bash
kubectl get svc product-service -n product-service -o yaml
```

**Ensure metrics port is defined:**
```yaml
ports:
- port: 9090
  targetPort: 9090
  name: metrics  # Name must match ServiceMonitor spec.endpoints[].port
```

**Restart Prometheus to force reload:**
```bash
kubectl delete pod prometheus-prometheus-kube-prometheus-prometheus-0 -n monitoring
```

---

### **Issue: No metrics appearing in Prometheus**

**1. Check if product-service is exposing metrics:**
```bash
# Port-forward to product-service
kubectl port-forward -n product-service deployment/product-service 9090:9090

# Check metrics endpoint
curl http://localhost:9090/metrics
```

**Expected output:**
```
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",status="200"} 42

# HELP http_request_duration_seconds HTTP request latency
# TYPE http_request_duration_seconds histogram
...
```

**2. If metrics endpoint returns 404:**
Your application needs to expose Prometheus metrics. Add instrumentation to your app:

**For Node.js (Express):**
```javascript
const promClient = require('prom-client');

// Create metrics
const httpRequestsTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'status']
});

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request latency in seconds',
  labelNames: ['method', 'route']
});

// Expose metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', promClient.register.contentType);
  res.end(await promClient.register.metrics());
});
```

**For Python (Flask):**
```python
from prometheus_client import Counter, Histogram, generate_latest

http_requests_total = Counter('http_requests_total', 'Total HTTP requests', ['method', 'status'])
http_request_duration = Histogram('http_request_duration_seconds', 'HTTP request latency')

@app.route('/metrics')
def metrics():
    return generate_latest()
```

---

### **Issue: Grafana dashboard shows "No data"**

**1. Verify Prometheus data source:**
- Grafana → Configuration → Data Sources → Prometheus
- Click **Test** - should show green success
- URL should be: `http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090`

**2. Check query syntax:**
- Click on panel → Edit
- Try simple query: `up{job="product-service"}`
- If it returns data, your complex query might be wrong

**3. Check time range:**
- Ensure time range selector shows recent time (last 5 minutes)
- Click refresh button

---

### **Issue: Alerts not firing**

**1. Check PrometheusRule is loaded:**
```bash
kubectl get prometheusrule product-service-alerts -n product-service -o yaml
```

**2. Verify in Prometheus UI:**
- Go to http://localhost:9090/alerts
- Search for your alert name (e.g., "ServiceDown")
- Check if it's listed and its current state

**3. Check AlertManager:**
```bash
# Get AlertManager logs
kubectl logs -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager-0 -c alertmanager
```

---

## 📊 Key Metrics to Monitor

### **Golden Signals:**

1. **Latency** (Response Time)
   ```promql
   histogram_quantile(0.95, 
     sum(rate(http_request_duration_seconds_bucket{job="product-service"}[5m])) by (le)
   )
   ```

2. **Traffic** (Request Rate)
   ```promql
   sum(rate(http_requests_total{job="product-service"}[5m]))
   ```

3. **Errors** (Error Rate)
   ```promql
   sum(rate(http_requests_total{job="product-service", status=~"5.."}[5m])) 
   / 
   sum(rate(http_requests_total{job="product-service"}[5m])) * 100
   ```

4. **Saturation** (Resource Usage)
   ```promql
   # Memory
   container_memory_working_set_bytes{namespace="product-service"} 
   / 
   container_spec_memory_limit_bytes{namespace="product-service"} * 100
   
   # CPU
   rate(container_cpu_usage_seconds_total{namespace="product-service"}[5m]) * 100
   ```

---

## 🎯 Testing Monitoring Setup

### **Generate Test Metrics**

If your application doesn't generate metrics yet, you can test with a simple app:

```bash
# Deploy a metrics generator
kubectl run metrics-test --image=nginx:alpine -n product-service \
  --labels="app=product-service" \
  --port=9090 \
  -- sh -c "while true; do echo 'http_requests_total{status=\"200\"} 1' | nc -l -p 9090; done"

# Wait 1-2 minutes for Prometheus to scrape

# Check in Prometheus UI
```

### **Trigger Test Alerts**

**1. Test ServiceDown alert:**
```bash
# Scale down replicas to 0
kubectl scale deployment product-service -n product-service --replicas=0

# Wait 2 minutes, check AlertManager
# Restore:
kubectl scale deployment product-service -n product-service --replicas=3
```

**2. Test MemoryUsageHigh alert:**
```bash
# Create a pod that consumes memory
kubectl run memory-hog -n product-service \
  --image=polinux/stress \
  --labels="app=product-service" \
  -- stress --vm 1 --vm-bytes 400M
```

---

## 🔗 Useful Resources

### **Prometheus Queries Cheat Sheet:**
- [Prometheus Query Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/)

### **Grafana Dashboards:**
- [Grafana Dashboard Library](https://grafana.com/grafana/dashboards/)

### **Best Practices:**
- [Google SRE Book - Monitoring](https://sre.google/sre-book/monitoring-distributed-systems/)
- [The Four Golden Signals](https://sre.google/sre-book/monitoring-distributed-systems/#xref_monitoring_golden-signals)

---

## 📋 Quick Reference Commands

```bash
# === Access Dashboards ===
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093

# === Check Monitoring Resources ===
kubectl get servicemonitor -n product-service
kubectl get prometheusrule -n product-service
kubectl get prometheus -n monitoring
kubectl get pods -n monitoring

# === View Logs ===
kubectl logs -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0 -c prometheus
kubectl logs -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager-0
kubectl logs -n monitoring deployment/prometheus-grafana

# === Restart Monitoring Components ===
kubectl delete pod prometheus-prometheus-kube-prometheus-prometheus-0 -n monitoring
kubectl rollout restart deployment prometheus-grafana -n monitoring

# === Check Metrics Endpoint ===
kubectl port-forward -n product-service deployment/product-service 9090:9090
curl http://localhost:9090/metrics

# === Get Grafana Password ===
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode && echo
```

---

## 🎉 Next Steps

1. ✅ **Access Grafana** and add Prometheus data source
2. ✅ **Import product-service dashboard**
3. ✅ **Verify metrics are being collected** (check Prometheus targets)
4. ✅ **Configure AlertManager** for Slack/Email notifications
5. ✅ **Add application instrumentation** to expose custom metrics
6. ✅ **Create runbooks** for each alert
7. ✅ **Set up on-call rotation** for critical alerts

---

**Need Help?** Check the [troubleshooting section](#troubleshooting) or open an issue on GitHub.
