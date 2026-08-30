# ABOUTME: Kubernetes 1.33.4 HA Cluster Deployment
# ABOUTME: Production-ready multi-master setup with comprehensive documentation

# Kubernetes 1.33.4 HA Cluster Build
**Production-Ready Multi-Master Kubernetes Deployment**

## Overview
This repository documents the complete deployment of a production-ready Kubernetes v1.33.4 HA cluster with the following specifications:

### Cluster Architecture
- **3 Control Plane Nodes**: 192.168.0.100, 192.168.0.101, 192.168.0.102
- **2 Worker Nodes**: 192.168.0.103, 192.168.0.104
- **Virtual IP (VIP)**: 192.168.0.199 (managed by kube-vip)
- **Operating System**: Ubuntu 24.04 LTS (cgroup v2)

### Software Versions
| Component | Version | Notes |
|-----------|---------|-------|
| Kubernetes | v1.33.4 | Latest GA release |
| containerd | v2.1.4 | v1.7.x EOL May 5, 2025 |
| Calico CNI | v3.30.3 | eBPF support available |
| kube-vip | v1.0.0 | HA load balancer |
| metrics-server | v0.8.0 | Released July 2025 |
| Dashboard | v7.13.0 | Helm-only, uses Kong |
| Ingress-NGINX | v1.13.1 | CVE-2025-1974 fixed |

## Deployment Process

### Git Workflow
Each major step is implemented in a dedicated feature branch, thoroughly tested, and merged to main upon successful validation.

### Steps Overview
1. **Initial Connectivity & Inventory** - Verify VM access and system requirements
2. **System Prerequisites** - Configure kernel, networking, and system settings
3. **Container Runtime** - Install and configure containerd v2.1.4
4. **Kubernetes Packages** - Install kubeadm, kubelet, kubectl v1.33.4
5. **HA Infrastructure Setup** - Configure kube-vip and prepare for HA
6. **Initialize First Master** - Bootstrap the first control plane node
7. **Join Control Planes** - Add additional masters for HA
8. **Configure Networking** - Deploy Calico CNI v3.30.3
9. **Join Workers** - Add worker nodes to the cluster
10. **Core Monitoring** - Deploy metrics-server and monitoring components
11. **Ingress & Dashboard** - Install Ingress controller and Dashboard
12. **Test Applications** - Deploy and validate test workloads
13. **Final Validation** - Comprehensive cluster validation and documentation

## Repository Structure
```
k8s-cluster-build/
├── README.md                  # This file
├── VERSIONS.md               # Component version tracking
├── steps/                    # Step-by-step documentation
│   ├── 01-connectivity/
│   ├── 02-prerequisites/
│   ├── 03-containerd/
│   └── ...
├── configs/                  # All deployed configurations
├── scripts/                  # Utility and validation scripts
├── docs/                     # Additional documentation
└── tests/                    # Test results and reports
```

## Key Features
- **High Availability**: 3-master setup with etcd quorum
- **Security**: PSA policies, audit logging, NetworkPolicies
- **Monitoring**: Built-in metrics and observability
- **Production Ready**: CIS benchmark compliant, resource limits, PodDisruptionBudgets
- **Disaster Recovery**: Automated etcd backups, documented restore procedures

## Requirements
- 5 Ubuntu 24.04 LTS VMs
- Control Plane: 4GB RAM minimum
- Workers: 2GB RAM minimum
- Network connectivity between all nodes
- SSH root access from deployment host

## Quick Start
Follow the git history to see the complete deployment process:
```bash
git log --oneline --graph --all
```

Each step includes:
- Detailed command logs
- Configuration files as deployed
- Test results and validation
- Issues encountered and resolutions

## Access Information
After successful deployment:
- **API Server**: https://192.168.0.199:6443
- **Dashboard**: See `steps/11-dashboard/access-guide.md`
- **Kubectl Config**: `configs/admin.conf`

## Validation
Run the comprehensive validation script:
```bash
./scripts/validate-cluster.sh
```

## Support
For issues or questions about this deployment, refer to:
- `docs/troubleshooting.md`
- `docs/disaster-recovery.md`
- Individual step documentation in `steps/`

---
*Deployment Date: August 23, 2025*
*Kubernetes Version: 1.33.4*
