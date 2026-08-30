# Kubernetes Fresh Cluster Deployment - August 2025

## Cluster Specifications

### Infrastructure
- **Control Plane**: k8s01 (.50), k8s02 (.51), k8s03 (.52)
- **Worker Nodes**: k8s04 (.53), k8s05 (.54), k8s06 (.55), k8s07/k8s08 (.56/.57), k8s09 (.58)
- **VIP for HA**: 192.168.0.199
- **OS**: Ubuntu 24.04 LTS (cgroup v2)

### Software Versions (EXACT - No Substitutions)
- **Kubernetes**: v1.33.4
- **containerd**: v2.1.4 (v1.7.x EOL May 5, 2025)
- **Cilium**: Latest stable (2025)
- **Longhorn**: Latest stable (2025)
- **kube-vip**: v1.0.0
- **metrics-server**: v0.8.0
- **Dashboard**: v7.13.0 (Helm-only, Kong gateway)
- **Ingress-NGINX**: v1.13.1 (CVE-2025-1974 fixed)

## Deployment Process

Each step follows strict git workflow:
1. Create feature branch
2. Discovery phase
3. Implementation with EXACT versions
4. Verification
5. Documentation
6. Commit and merge

## Critical Requirements
- NO version substitutions
- NO workarounds without permission
- Complete documentation of every action
- Full verification at each step
- Ask when stuck - don't assume