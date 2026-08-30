# Kubernetes 1.33.4 Cluster Build

## Project Overview
Building a production-ready Kubernetes v1.33.4 cluster with High Availability, multiple CNI support, and comprehensive monitoring.

## Cluster Architecture
- **Control Plane**: 3 nodes (192.168.0.50-52) with HA via kube-vip
- **Worker Nodes**: 6 nodes (192.168.0.53-58)
- **VIP**: 192.168.0.200 for API server HA
- **OS**: Ubuntu 24.04 LTS (cgroup v2)

## Component Versions (August 2025)
| Component | Version | Notes |
|-----------|---------|-------|
| Kubernetes | v1.33.4 | Latest GA |
| containerd | v2.1.4 | v1.7.x EOL May 5, 2025 |
| Multus CNI | v4.2.2 | Meta CNI plugin |
| Cilium CNI | v1.18.0 | Non-exclusive mode (cni.exclusive=false) |
| Longhorn | v1.9.0 | Distributed storage |
| KubeVirt | v1.5.0 | VM support via bridged networking |
| kube-vip | v1.0.0 | HA virtual IP |
| metrics-server | v0.8.0 | Resource metrics |
| Dashboard | v7.13.0 | Helm-only, uses Kong gateway |
| Ingress-NGINX | v1.13.1 | CVE-2025-1974 fixed |

## Node Inventory
| Node | IP | Role | CPU | Memory | Storage |
|------|-----|------|-----|--------|---------|
| k8s01 | 192.168.0.50 | Control Plane | 4x Intel N5105 | 15.4GB | 466GB |
| k8s02 | 192.168.0.51 | Control Plane | 4x Intel N5105 | 15.4GB | 466GB |
| k8s03 | 192.168.0.52 | Control Plane | 4x Intel N5105 | 15.4GB | 466GB |
| k8s04 | 192.168.0.53 | Worker | 4x Intel N5105 | 15.4GB | 466GB |
| k8s05 | 192.168.0.54 | Worker | 4x Intel N5105 | 15.4GB | 466GB |
| k8s06 | 192.168.0.55 | Worker | 4x Intel i5-3427U | 7.7GB | 437GB |
| k8s07 | 192.168.0.56 | Worker | 8x Intel i5-1135G7 | 15GB | 466GB |
| k8s08 | 192.168.0.57 | Worker | 4x Intel i7-7500U | 15GB | 466GB |
| k8s09 | 192.168.0.58 | Worker | 12x AMD Ryzen 5 5600H | 62GB | 1.8TB |

## Deployment Process

### Git Workflow
Each step follows this process:
1. Create feature branch: `git checkout -b step-XX-description`
2. Discovery phase - check current state
3. Implementation phase - execute with exact versions
4. Verification phase - comprehensive testing
5. Documentation phase - record all commands and decisions
6. Commit & merge to main if tests pass

### Critical Requirements
- **NO VERSION SUBSTITUTIONS**: Use exact versions specified
- **NO WORKAROUNDS**: Ask for permission before any workaround
- **DOCUMENT EVERYTHING**: Every command, output, and decision
- **DISCOVERY FIRST**: Investigate thoroughly before fixes
- **INTERACTIVE RESOLUTION**: Pause and ask when stuck

### Deployment Steps
1. **Step 01**: Initial Connectivity & Inventory
2. **Step 02**: System Prerequisites
3. **Step 03**: Container Runtime (containerd v2.1.4)
4. **Step 04**: Kubernetes Packages (v1.33.4)
5. **Step 05**: HA Infrastructure Setup
6. **Step 06**: Initialize First Master
7. **Step 07**: Join Control Planes
8. **Step 08**: Install Multus CNI (v4.2.2)
9. **Step 09**: Install Cilium CNI (v1.18.0)
10. **Step 10**: Install Longhorn (v1.9.0)
11. **Step 11**: Join Workers
12. **Step 12**: Install KubeVirt (v1.5.0)
13. **Step 13**: Core Monitoring
14. **Step 14**: Ingress & Dashboard
15. **Step 15**: Test Applications
16. **Step 16**: Final Validation & Documentation

## Repository Structure
```
k8s-cluster-build/
├── README.md (this file)
├── VERSIONS.md (component version tracking)
├── steps/ (documentation for each step)
├── configs/ (all deployed configurations)
├── scripts/ (automation and validation scripts)
├── docs/ (architecture and operations documentation)
└── tests/ (test cases and results)
```

## Network Configuration
- Pod CIDR: 10.244.0.0/16
- Service CIDR: 10.96.0.0/12
- Cluster DNS: 10.96.0.10
- API Server VIP: 192.168.0.200:6443

## Security Features
- Pod Security Admission (PSA) enabled
- Audit logging configured
- ETCD encryption at rest
- Least-privilege RBAC
- Network policies enforced
- Certificate rotation enabled

## Storage & Virtualization
- **Longhorn**: Distributed block storage with 3 replicas
- **KubeVirt**: VM support with bridged networking via Multus

## Monitoring & Access
- metrics-server for resource metrics
- kube-state-metrics for cluster metrics
- Kubernetes Dashboard via Kong gateway
- Ingress-NGINX for external access

## Validation Criteria
- All nodes Ready (9 total)
- Kubernetes v1.33.4 confirmed
- All component versions match specification
- Zero pods in Error/CrashLoop
- ETCD latency <10ms p99
- API latency <100ms p99
- DNS resolution working
- Dashboard accessible
- CIS benchmark score >95%

## Important Notes
1. **containerd v2.1.4**: v1.7.x reached EOL May 5, 2025
2. **Cilium**: Must use cni.exclusive=false for Multus compatibility
3. **Dashboard v7**: No kubectl apply support, Helm-only with Kong
4. **Ubuntu 24.04**: Uses cgroup v2 and systemd by default
5. **PSA**: Pod Security Admission is stable and enabled

## Git Tags
- v0.1-infrastructure-ready (after step 02)
- v0.2-runtime-ready (after step 03)
- v0.5-ha-configured (after step 05)
- v1.0-cluster-initialized (after step 07)
- v1.2-networking-ready (after step 09)
- v1.3-storage-ready (after step 10)
- v1.5-workers-joined (after step 11)
- v1.6-virtualization-ready (after step 12)
- v2.0-monitoring-enabled (after step 13)
- v2.5-ingress-ready (after step 14)
- v3.0-production-ready (after step 16)

---
*Started: August 2025*
*Target: Kubernetes v1.33.4 Production Cluster*
