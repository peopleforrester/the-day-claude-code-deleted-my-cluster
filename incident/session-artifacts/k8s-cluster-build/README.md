# Kubernetes Cluster Build with Git History

This repository documents the complete build process of a highly available Kubernetes cluster using kubeadm, with every step tracked in Git.

## Cluster Architecture

- **Control Plane Nodes (3)**: 192.168.0.100, 192.168.0.101, 192.168.0.102
- **Worker Nodes (2)**: 192.168.0.103, 192.168.0.104
- **OS**: Ubuntu 24.04 LTS
- **Container Runtime**: containerd with systemd cgroup driver
- **CNI**: Calico with eBPF dataplane
- **Ingress**: NGINX Ingress Controller
- **Monitoring**: Metrics Server

## Build Process Overview

Each major step is executed in its own Git branch, tested, and merged to main upon success.

### Steps Completed

1. **Step 01: Initial Connectivity** - Verify SSH access to all nodes
2. **Step 02: System Prerequisites** - Configure kernel modules, sysctl, disable swap
3. **Step 03: Container Runtime** - Install and configure containerd
4. **Step 04: Kubernetes Packages** - Install kubeadm, kubelet, kubectl
5. **Step 05: Initialize First Master** - Bootstrap the first control plane node
6. **Step 06: Join Control Planes** - Add remaining master nodes for HA
7. **Step 07: Configure Networking** - Deploy Calico CNI
8. **Step 08: Join Workers** - Add worker nodes to the cluster
9. **Step 09: Metrics Server** - Deploy metrics collection
10. **Step 10: Ingress Controller** - Install NGINX ingress
11. **Step 11: Dashboard** - Deploy Kubernetes dashboard with RBAC
12. **Step 12: Test Application** - Deploy and test sample application
13. **Step 13: Final Validation** - Comprehensive cluster testing

## Repository Structure

```
k8s-cluster-build/
├── README.md                  # This file
├── steps/                     # Step-by-step progress tracking
│   ├── 01-connectivity/       # SSH connectivity verification
│   ├── 02-prerequisites/      # System configuration
│   └── ...                    # One directory per step
├── configs/                   # All configuration files used
├── state/                     # Cluster state snapshots
├── logs/                      # Operation logs
└── tests/                     # Test scripts and results
```

## How to Use This Repository

1. **Follow the Build**: Check out each step's branch to see what was done
2. **Reproduce**: Use the configs and commands to rebuild the cluster
3. **Troubleshoot**: Review logs and test results for each step
4. **Access Cluster**: See `state/cluster-access-info.txt` for connection details

## Git Workflow

Each step follows this pattern:
```bash
git checkout -b step-XX-description
# Execute work and capture results
git add -A
git commit -m "Step XX: Description of what was done"
git checkout main
git merge step-XX-description
```

## Cluster Access

After completion, access information will be available in:
- `state/cluster-access-info.txt` - Contains kubeconfig and dashboard access
- `configs/admin.conf` - Admin kubeconfig file
- `validate-cluster.sh` - Script to verify cluster health

## Tags

- `v1.0-cluster-initialized` - Basic cluster is up
- `v2.0-monitoring-added` - Monitoring components deployed
- `v3.0-complete` - Full cluster with all components

---

*This cluster build process is fully tracked in Git for reproducibility and troubleshooting.*
