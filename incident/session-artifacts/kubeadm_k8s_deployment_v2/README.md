# Kubernetes Cluster Build with Git History

This repository documents the complete build process of a highly available Kubernetes cluster using kubeadm, with every step tracked in Git history.

## Cluster Architecture

- **Control Plane**: 3 master nodes (HA configuration)
  - master1: 192.168.0.183
  - master2: 192.168.0.194
  - master3: 192.168.0.196
- **Worker Nodes**: 2 worker nodes
  - worker1: 192.168.0.197
  - worker2: 192.168.0.198
- **Virtual IP**: 192.168.0.180 (API server endpoint)
- **OS**: Ubuntu 24.04 LTS on all nodes

## Build Process

Each major step in the cluster build is executed in its own Git branch, tested, and then merged to main. This provides:
- Complete audit trail of all changes
- Ability to rollback to any previous state
- Clear documentation of what was done when
- Reproducible build process

## Progress Tracking

| Step | Description | Status | Branch |
|------|-------------|--------|--------|
| 01 | Verify connectivity to all nodes | ✅ Complete | step-01-verify-connectivity |
| 02 | Configure system prerequisites | ✅ Complete | step-02-system-prerequisites |
| 03 | Install containerd runtime | ✅ Complete | step-03-containerd-install |
| 04 | Install Kubernetes packages | ✅ Complete | step-04-kubernetes-packages |
| 05 | Configure kube-vip for HA | ✅ Complete | step-05-kube-vip-setup |
| 06 | Initialize first master | ⏳ Pending | step-06-init-first-master |
| 07 | Join additional control planes | ⏳ Pending | step-07-join-control-planes |
| 08 | Install Calico CNI | ⏳ Pending | step-08-calico-cni |
| 09 | Join worker nodes | ⏳ Pending | step-09-join-workers |
| 11 | Deploy metrics server | ⏳ Pending | step-11-metrics-server |
| 12 | Install nginx ingress | ⏳ Pending | step-12-nginx-ingress |
| 13 | Deploy Kubernetes dashboard | ⏳ Pending | step-13-kubernetes-dashboard |
| 14 | Deploy test application | ⏳ Pending | step-14-test-deployment |
| 15 | Run final validation | ⏳ Pending | step-15-cluster-validation |

## Repository Structure

```
k8s-cluster-build/
├── steps/           # Step-by-step build artifacts
├── configs/         # All configuration files used
├── state/           # Cluster state snapshots
├── logs/            # Build and test logs
└── tests/           # Test scripts and results
```

## How to Use This Repository

1. **Follow the build**: Check out each branch to see what was done at each step
2. **Reproduce the cluster**: Use the configs and commands in each step
3. **Learn from history**: Use `git log` to understand the evolution
4. **Troubleshoot issues**: Compare your setup with the committed state

## Current Status

🚧 **Build in Progress** - Step 06 blocked by network configuration issues.

### Latest Updates
- ✅ Step 01: All nodes verified and inventory created
- ✅ Step 02: System prerequisites configured (swap, kernel modules, sysctl)
- ✅ Step 03: Containerd v1.7.27 installed and configured
- ✅ Step 04: Kubernetes v1.31.11 packages installed
- ✅ Step 05: kube-vip v0.8.7 configured for HA
- ❌ Step 06: Master initialization blocked:
  - VMs are behind NAT (all show internal IP 10.0.2.2)
  - Cannot bind to external IPs (192.168.0.x)
  - etcd fails to start due to address binding error
  - Moved containerd to /data to resolve space issues

### Current Issue
The VMs appear to be behind NAT/proxy and cannot directly use the 192.168.0.x addresses
for Kubernetes components. This requires either:
1. Reconfiguring VM networking
2. Finding the actual inter-VM network
3. Using a different approach for the cluster setup

---
*Last Updated: 2025-08-03 15:50 UTC*
