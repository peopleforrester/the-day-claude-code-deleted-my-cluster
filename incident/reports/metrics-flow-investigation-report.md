# Banking Metrics Flow Investigation Report

**Date:** 2025-07-15
**Investigator:** Michael Assistant

## Executive Summary

After thorough investigation of the metric flow from banking app → Prometheus → Grafana, I've identified and fixed several configuration issues. The banking application is successfully generating metrics, and the ServiceMonitor has been properly configured.

## Investigation Findings

### 1. Banking Application (✅ Working)
- **Status:** Fully operational
- **Metrics Endpoint:** http://192.168.0.188/demo-backend/internal/metrics
- **Metrics Generated:**
  - `banking_transactions_total{scenario="normal",status="completed"}` = 40
  - `banking_transaction_duration_seconds` histogram with proper buckets
  - All expected banking metrics are being exposed

### 2. ServiceMonitor Configuration (✅ Fixed)
**Issues Found and Fixed:**
1. **Wrong metrics path**: Changed from `/metrics` to `/internal/metrics`
2. **Missing required label**: Added `app.kubernetes.io/instance=kube-prometheus-stack`
3. **Wrong port reference**: Changed from `http` to `metrics` port

**Current Configuration:**
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: banking-backend-otel
  namespace: monitoring
  labels:
    app: banking-backend
    release: kube-prometheus-stack
    app.kubernetes.io/instance: kube-prometheus-stack
spec:
  endpoints:
  - interval: 30s
    path: /internal/metrics
    port: metrics
    scheme: http
  namespaceSelector:
    matchNames:
    - default
  selector:
    matchLabels:
      app: banking-backend-otel
```

### 3. Kubernetes Service (✅ Verified)
- **Service Name:** banking-backend-otel-service
- **Namespace:** default
- **Labels:** `app: banking-backend-otel` (matches ServiceMonitor selector)
- **Ports:**
  - http: 8000 → 8000
  - metrics: 9090 → 8000 (correctly routes to app)
- **Endpoints:** Active with 2 pod IPs

### 4. Prometheus Target Discovery (⚠️ Status Unknown)
- ServiceMonitor has correct labels for Prometheus selector
- Service and endpoints are properly configured
- Unable to directly verify Prometheus targets due to access limitations

## Actions Taken

1. **Fixed ServiceMonitor Path**: Updated from `/metrics` to `/internal/metrics`
2. **Added Required Labels**: Added `app.kubernetes.io/instance=kube-prometheus-stack` label
3. **Fixed Port Reference**: Changed ServiceMonitor to use `metrics` port instead of `http`
4. **Generated Test Data**: Created 40 test transactions to ensure metrics are populated
5. **Verified Metric Generation**: Confirmed banking app is exposing metrics correctly

## Current Status

All components in the metric flow chain have been properly configured:
- ✅ Banking app generating metrics at `/internal/metrics`
- ✅ Kubernetes service properly exposing metrics port
- ✅ ServiceMonitor correctly configured with all required labels and selectors
- ✅ Service endpoints are healthy and reachable

## Next Steps for User

To verify metrics are now flowing to Grafana:

1. **Access Grafana**: http://192.168.0.182
2. **Navigate to Explore Tab**: Click the compass icon in left sidebar
3. **Select Prometheus Data Source**: Should be in the top dropdown
4. **Query Banking Metrics**: Try these queries:
   ```
   banking_transactions_total
   rate(banking_transactions_total[5m])
   histogram_quantile(0.95, rate(banking_transaction_duration_seconds_bucket[5m]))
   ```

5. **Check Banking Dashboard**:
   - Direct URL: http://192.168.0.182/d/banking-cicd-demo/banking-ci-cd-observability
   - If dashboard exists, it should now show data

## Troubleshooting Commands

If metrics still don't appear:

```bash
# Generate more test data
for i in {1..50}; do
  curl -X POST http://192.168.0.188/demo-backend/banking/transfer \
    -H "Content-Type: application/json" \
    -d "{\"from_account\": \"ACC$i\", \"to_account\": \"ACC$((i+1))\", \"amount\": $((RANDOM % 1000 + 100)), \"scenario\": \"normal\"}"
  sleep 0.1
done

# Verify metrics directly
curl -s http://192.168.0.188/demo-backend/internal/metrics | grep banking_

# Check ServiceMonitor status
kubectl get servicemonitor -n monitoring banking-backend-otel
kubectl describe servicemonitor -n monitoring banking-backend-otel

# Check service endpoints
kubectl get endpoints -n default banking-backend-otel-service
```

## Prometheus Configuration Note

The Prometheus instance is configured to select ServiceMonitors with:
- `release: kube-prometheus-stack` OR
- `app.kubernetes.io/instance: kube-prometheus-stack`

Our ServiceMonitor now has both labels to ensure compatibility.

---

**Note:** It may take up to 1-2 minutes for Prometheus to pick up the ServiceMonitor changes and start scraping the new configuration. If metrics don't appear immediately, wait a moment and try again.
