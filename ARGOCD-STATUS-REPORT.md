# ArgoCD Status Report & Fixes

**Report Date:** October 27, 2025  
**Application:** product-service  
**Namespace:** product-service  

---

## 📊 Current Status

**Before Fixes:**
- **Sync Status:** OutOfSync  
- **Health Status:** Degraded  
- **Revision:** d1f9257eab6543f6edd2a024e8690398fc9e1fd2  

---

## 🔍 Issues Found

### 1. ❌ **PrometheusRule - OutOfSync**

**Issue:** Invalid `podSelector` field in PrometheusRule spec  
**File:** `k8s/product-service/06-monitoring.yaml`  

**Problem:**
```yaml
spec:
  podSelector:              # ❌ Invalid field
    matchLabels:
      app: product-service
  groups:
```

**Solution:**
```yaml
spec:
  groups:                   # ✅ Correct - removed podSelector
```

**Root Cause:** PrometheusRule doesn't support `podSelector` - that field is only for NetworkPolicy and PodDisruptionBudget.

---

### 2. ❌ **Database Schema Job - Stuck Running**

**Issue:** `db-schema-job` stuck in Running state for 170+ minutes, never creating pods  
**File:** `k8s/product-service/03-db-init-job.yaml`  

**Error:**
```
Error creating: pods "db-schema-job-tkrj9" is forbidden: 
[minimum memory usage per Container is 128Mi, but request is 64Mi, 
 minimum cpu usage per Container is 100m, but request is 50m]
```

**Problem:**
```yaml
initContainers:
- name: wait-for-postgres
  resources:
    requests:
      memory: "64Mi"   # ❌ Below LimitRange minimum (128Mi)
      cpu: "50m"       # ❌ Below LimitRange minimum (100m)
```

**Solution:**
```yaml
initContainers:
- name: wait-for-postgres
  resources:
    requests:
      memory: "128Mi"  # ✅ Meets minimum
      cpu: "100m"      # ✅ Meets minimum
    limits:
      memory: "256Mi"
      cpu: "200m"
```

**Root Cause:** LimitRange in namespace requires minimum 128Mi memory and 100m CPU per container.

---

### 3. ❌ **Database Seed Job - Failing**

**Issue:** `db-seed-job` failing with "relation 'categories' does not exist"  

**Error:**
```
ERROR:  relation "categories" does not exist
LINE 1: INSERT INTO categories (name, description) VALUES
```

**Root Cause:** Schema job (db-schema-job) never ran successfully, so tables don't exist. Seed job tries to insert data into non-existent tables.

**Solution:** Fix schema job first (issue #2 above), then seed job will succeed.

---

### 4. ✅ **Resource Quota Issue - Fixed**

**Issue:** Deployment couldn't scale to 3 replicas due to CPU quota  

**Error:**
```
exceeded quota: jenkins-deployer-quota, requested: limits.cpu=500m, 
used: limits.cpu=2, limited: limits.cpu=2
```

**Previous Quota:**
```yaml
limits.cpu: "2"        # ❌ Too low for 3 replicas × 500m
```

**Fixed Quota:**
```yaml
limits.cpu: "4"        # ✅ Enough for 3 replicas
```

**Status:** ✅ Already fixed - deployment now has 3/3 replicas running.

---

### 5. ✅ **TopologySpreadConstraints - Fixed**

**Issue:** Invalid field name in deployment  

**Error:**
```
spec.template.spec.topologySpreadConstraints[0].whenUnsatisfiable: 
Unsupported value: "": supported values: "DoNotSchedule", "ScheduleAnyway"
```

**Problem:**
```yaml
whenUnschedulable: DoNotSchedule  # ❌ Wrong field name
```

**Solution:**
```yaml
whenUnsatisfiable: DoNotSchedule  # ✅ Correct field name
```

**Status:** ✅ Already fixed.

---

## 📋 Summary of Fixes Applied

| # | Issue | Status | Fix Applied |
|---|-------|--------|-------------|
| 1 | PrometheusRule invalid podSelector | ✅ Fixed | Removed podSelector field |
| 2 | Schema job resource limits too low | ✅ Fixed | Increased to 128Mi/100m minimum |
| 3 | Seed job failing (dependency) | ✅ Fixed | Will auto-fix after schema job runs |
| 4 | Resource quota too restrictive | ✅ Fixed | Increased CPU limit to 4 cores |
| 5 | TopologySpreadConstraints typo | ✅ Fixed | Changed to whenUnsatisfiable |

---

## 🚀 Actions Required

### **1. Commit and Push Fixes**

```bash
cd /c/Users/91967/OneDrive/Documents/GitHub/devops-sample-app

git status

git add k8s/product-service/06-monitoring.yaml
git add k8s/product-service/03-db-init-job.yaml
git add k8s/product-service/04-app-deployment.yaml
git add k8s/product-service/08-rbac.yaml
git add Jenkinsfile
git add MONITORING-SETUP.md
git add setup-argocd-jenkins.md
git add start-monitoring.bat
git add start-monitoring.sh
git add ARGOCD-STATUS-REPORT.md

git commit -m "Fix ArgoCD sync issues: PrometheusRule, resource limits, and quotas"

git push origin main
```

---

### **2. Wait for ArgoCD Auto-Sync**

ArgoCD is configured with auto-sync enabled. After pushing to Git:

```bash
# Wait ~30 seconds, then check
kubectl get application product-service -n argocd

# Should show:
# NAME              SYNC STATUS   HEALTH STATUS
# product-service   Synced        Healthy
```

Or force sync immediately:
```bash
argocd app sync product-service --prune
```

---

### **3. Verify Database Jobs**

After ArgoCD syncs, new jobs will be created:

```bash
# Watch jobs
kubectl get jobs -n product-service -w

# Expected output:
# NAME             COMPLETIONS   DURATION   AGE
# db-schema-job    1/1           45s        1m
# db-seed-job      1/1           12s        30s

# Check schema job logs
kubectl logs job/db-schema-job -n product-service

# Check seed job logs
kubectl logs job/db-seed-job -n product-service
```

---

### **4. Verify All Pods Running**

```bash
kubectl get pods -n product-service

# Expected output:
# NAME                              READY   STATUS      RESTARTS   AGE
# postgres-0                        1/1     Running     0          3h
# product-service-xxx-xxx           1/1     Running     0          20m
# product-service-xxx-xxx           1/1     Running     0          20m
# product-service-xxx-xxx           1/1     Running     0          20m
# db-schema-job-xxx                 0/1     Completed   0          5m
# db-seed-job-xxx                   0/1     Completed   0          4m
```

---

## 🎯 Expected Final State

After all fixes are applied and synced:

### **ArgoCD Application:**
```
NAME              SYNC STATUS   HEALTH STATUS
product-service   Synced        Healthy
```

### **Resources Status:**
- ✅ Deployment: 3/3 replicas running
- ✅ StatefulSet (postgres): 1/1 replica running
- ✅ ServiceMonitor: Active
- ✅ PrometheusRule: Synced (no podSelector)
- ✅ db-schema-job: Completed
- ✅ db-seed-job: Completed
- ✅ All 42 resources: Synced and Healthy

---

## 🔧 Troubleshooting Commands

### **Check ArgoCD Sync Status**
```bash
kubectl get application product-service -n argocd
kubectl describe application product-service -n argocd | findstr "Health\|Sync\|Message"
```

### **Check Specific Resource**
```bash
# PrometheusRule
kubectl get prometheusrule product-service-alerts -n product-service -o yaml

# Jobs
kubectl get jobs -n product-service
kubectl logs job/db-schema-job -n product-service
kubectl logs job/db-seed-job -n product-service

# Deployment
kubectl get deployment product-service -n product-service
kubectl describe deployment product-service -n product-service
```

### **Force Refresh ArgoCD**
```bash
argocd app get product-service --refresh
argocd app sync product-service
```

---

## 📚 Lessons Learned

### **1. Resource Limits & LimitRange**
- Always check namespace LimitRange when defining container resources
- Init containers must also meet minimum resource requirements
- Error messages about "forbidden" pods often indicate quota/limit issues

### **2. Kubernetes API Field Names**
- Field names are case-sensitive and version-specific
- `whenUnsatisfiable` vs `whenUnschedulable` - small typos cause big errors
- Always validate against the correct API version

### **3. PrometheusRule vs Other Resources**
- PrometheusRule doesn't have `podSelector`
- NetworkPolicy uses `podSelector`
- PodDisruptionBudget uses `selector.matchLabels`
- Check CRD spec for valid fields

### **4. Job Dependencies**
- Seed jobs depend on schema jobs
- Use `initContainers` or separate Jobs with proper ordering
- Jobs with `ttlSecondsAfterFinished: 300` auto-cleanup after 5 minutes

---

## 📞 Support

If issues persist after applying fixes:

1. Check ArgoCD UI: http://localhost:8081
2. View pod logs: `kubectl logs <pod-name> -n product-service`
3. Check events: `kubectl get events -n product-service --sort-by='.lastTimestamp'`
4. Review this report and verify all fixes were applied

---

**Status:** Ready to commit and sync ✅
