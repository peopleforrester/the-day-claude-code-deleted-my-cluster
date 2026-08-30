# Kubernetes Cluster Architecture Summary

## Overview

This document provides a comprehensive overview of the Kubernetes cluster architecture, focusing on the deployed services, their relationships, and data flows.

## Cluster Infrastructure

### Networking Layer
- **CNI**: Cilium (providing network policies and observability)
- **Load Balancer**: MetalLB
  - IP Pool: 192.168.0.180-192.168.0.199
  - L2 Advertisement mode
- **Ingress Controller**: NGINX Ingress
  - External IP: 192.168.0.188
  - Handles all HTTP/HTTPS traffic routing

### Storage
- **Storage Provider**: Longhorn
  - Distributed block storage across cluster nodes
  - Web UI: 192.168.0.184 (longhorn.k8s.local)
  - Provides persistent volumes for stateful applications

### DNS
- **Internal DNS**: CoreDNS (kube-system)
- **External DNS**: PiHole
  - DNS Service: 192.168.0.186:53
  - Web UI: 192.168.0.187 (pihole.k8s.local)

## Service Architecture

### 1. Observability Stack

#### Metrics Collection & Visualization
- **Prometheus** (monitoring namespace)
  - External Access: via Grafana
  - Internal Endpoint: 10.0.8.115:9090
  - Collects metrics from:
    - Node exporters on all cluster nodes
    - Kubernetes API server
    - Application metrics endpoints
    - OpenTelemetry Collector exports

- **Grafana** (monitoring namespace)
  - External IP: 192.168.0.182
  - Ingress: grafana.k8s.local
  - Data Sources:
    - Prometheus (metrics)
    - Loki (logs)
    - Jaeger (traces)

#### Distributed Tracing
- **Jaeger** (observability namespace)
  - External IP: 192.168.0.181
  - Ingress: jaeger.k8s.local
  - Receives traces from:
    - OpenTelemetry Collector
    - Application instrumentation

#### Log Aggregation
- **Loki** (monitoring namespace)
  - Internal endpoint: 10.0.8.37:3100
  - Collects logs from all pods
  - Integrated with Grafana for visualization

#### Telemetry Pipeline
- **OpenTelemetry Collector** (default namespace)
  - Status: Currently in CrashLoopBackOff
  - Configured to:
    - Receive OTLP data (traces, metrics, logs)
    - Forward traces to Jaeger
    - Export metrics for Prometheus scraping
    - Scrape metrics from GitHub runners and banking backend

### 2. Applications

#### Banking Application
- **Banking Backend with OTEL** (default namespace)
  - 2 replicas running
  - Instrumented with OpenTelemetry
  - Exposes metrics on port 8000
  - Service: banking-backend-otel-service

#### Demo Applications
- **Frontend** (default namespace)
  - External access via NodePort: 30567
  - Service: frontend-service

- **Backend Services**:
  - Demo Backend: 2 replicas (demo-backend-service)
  - Observability Demo Backend: 1 replica (backend-service)

- **Database**:
  - PostgreSQL: Single instance
  - Service: postgres-service (port 5432)

### 3. DevOps Tools

#### CI/CD
- **ArgoCD** (argocd namespace)
  - External IP: 192.168.0.180
  - Ingress: argocd.k8s.local
  - Managing applications:
    - observability-demo-backend
    - observability-demo-frontend
    - observability-demo-otel-collector
    - observability-demo-postgres

- **GitHub Runners** (github-runners namespace)
  - 2 self-hosted runners
  - Integrated with OpenTelemetry for metrics collection
  - Annotations for Prometheus scraping

#### Container Registry
- **Harbor** (harbor-system namespace)
  - External IP: 192.168.0.185
  - Ingress: harbor.k8s.local
  - Components:
    - Core API
    - Registry service
    - Portal UI
    - Trivy scanner for vulnerability scanning
    - Redis cache
    - PostgreSQL database

### 4. Security Services

#### Runtime Security
- **Falco** (falco namespace)
  - DaemonSet for kernel-level security monitoring
  - Falcosidekick for alert routing
  - Web UI: 192.168.0.183 (falco.k8s.local)

#### Policy Enforcement
- **Gatekeeper** (gatekeeper-system namespace)
  - OPA-based policy engine
  - 3 controller replicas for HA
  - Audit deployment for policy violations

#### Certificate Management
- **cert-manager** (cert-manager namespace)
  - Automated certificate provisioning
  - Webhook for admission control

### 5. Backup & Recovery
- **Velero** (velero namespace)
  - Cluster backup solution
  - Integrated with object storage

### 6. Object Storage
- **MinIO** (minio namespace)
  - S3-compatible object storage
  - Console UI: 192.168.0.189
  - Ingress: minio.k8s.local

## Data Flow Patterns

### Observability Data Flow
```
Applications → OpenTelemetry Collector → ┬→ Jaeger (traces)
                                        ├→ Prometheus (metrics)
                                        └→ Loki (logs)
                                              ↓
                                          Grafana (visualization)
```

### Application Traffic Flow
```
External Users → MetalLB LoadBalancer → NGINX Ingress → Application Services
                     ↓
                 Direct NodePort access (for specific services)
```

### CI/CD Flow
```
GitHub → GitHub Runners → Build/Test → Harbor Registry
                              ↓
                          ArgoCD → Deploy to Cluster
```

## External Access Points

All external access is provided through MetalLB LoadBalancer IPs:

| Service | External IP | Port | Purpose |
|---------|-------------|------|---------|
| ArgoCD | 192.168.0.180 | 80/443 | GitOps deployment |
| Jaeger | 192.168.0.181 | 16686 | Distributed tracing UI |
| Grafana | 192.168.0.182 | 80 | Monitoring dashboards |
| Falco UI | 192.168.0.183 | 2802 | Security events |
| Longhorn | 192.168.0.184 | 80 | Storage management |
| Harbor | 192.168.0.185 | 80 | Container registry |
| PiHole DNS | 192.168.0.186 | 53 | DNS resolution |
| PiHole Web | 192.168.0.187 | 80 | DNS management |
| NGINX Ingress | 192.168.0.188 | 80/443 | HTTP/HTTPS routing |
| MinIO | 192.168.0.189 | 9001 | Object storage console |

## Service Dependencies

### Critical Dependencies
1. **Longhorn** → Required by all stateful services for persistent storage
2. **CoreDNS/PiHole** → Required for service discovery and external DNS
3. **Cilium** → Required for pod networking and network policies
4. **MetalLB** → Required for external service access

### Observability Dependencies
- Applications → OpenTelemetry Collector → Jaeger/Prometheus
- All services → Prometheus (for metrics)
- All pods → Loki (for logs)
- Grafana → Prometheus, Loki, Jaeger (for data visualization)

### Security Dependencies
- All pods → Falco (runtime monitoring)
- All resources → Gatekeeper (policy enforcement)
- HTTPS services → cert-manager (TLS certificates)

## High Availability Considerations

### Redundant Services
- **Kubernetes Control Plane**: Multiple master nodes
- **Gatekeeper**: 3 controller replicas
- **Harbor**: Redundant registry instances (1 of 2 running)
- **CoreDNS**: 2 replicas
- **PiHole**: 2 replicas
- **Application backends**: Multiple replicas

### Single Points of Failure
- **Grafana**: Single instance
- **Jaeger**: Single instance
- **PostgreSQL**: Single instances (both default and Harbor)
- **MinIO**: Single instance configuration

## Current Issues

1. **OpenTelemetry Collector**: In CrashLoopBackOff state
2. **Harbor JobService**: Only 1 of 2 replicas running
3. **Backend Deployment**: One pod in ErrImagePull state

## Recommendations

1. **Fix OpenTelemetry Collector** to restore full observability pipeline
2. **Implement HA for critical single-instance services** (Grafana, Jaeger)
3. **Configure Network Policies** (currently none defined)
4. **Set up automated backups** using Velero
5. **Monitor and resolve** the failing pod deployments
