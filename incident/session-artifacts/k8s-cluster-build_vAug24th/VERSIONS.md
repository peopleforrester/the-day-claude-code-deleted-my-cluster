# ABOUTME: Component version tracking for Kubernetes cluster
# ABOUTME: Critical for ensuring exact version compliance

# Component Versions

## Core Components
| Component | Required Version | Status | Notes |
|-----------|-----------------|--------|-------|
| Kubernetes | v1.33.4 | Pending | Latest GA release |
| kubeadm | v1.33.4 | Pending | Must match K8s version |
| kubelet | v1.33.4 | Pending | Must match K8s version |
| kubectl | v1.33.4 | Pending | Must match K8s version |

## Container Runtime
| Component | Required Version | Status | Notes |
|-----------|-----------------|--------|-------|
| containerd | v2.1.4 | Pending | v1.7.x EOL May 5, 2025 |
| runc | Latest stable | Pending | Will be installed with containerd |

## Networking
| Component | Required Version | Status | Notes |
|-----------|-----------------|--------|-------|
| Calico CNI | v3.30.3 | Pending | eBPF support available |
| kube-vip | v1.0.0 | Pending | HA load balancer |

## Monitoring & Management
| Component | Required Version | Status | Notes |
|-----------|-----------------|--------|-------|
| metrics-server | v0.8.0 | Pending | Released July 2025 |
| Kubernetes Dashboard | v7.13.0 | Pending | Helm-only, uses Kong |
| Kong Gateway | Latest | Pending | Required by Dashboard v7 |

## Ingress
| Component | Required Version | Status | Notes |
|-----------|-----------------|--------|-------|
| Ingress-NGINX | v1.13.1 | Pending | CVE-2025-1974 fixed |
| cert-manager | Latest stable | Pending | For TLS certificates |

## System Requirements
| Component | Required Version | Status | Notes |
|-----------|-----------------|--------|-------|
| Ubuntu | 24.04 LTS | Pending | Verification needed |
| Linux Kernel | 5.15+ | Pending | For cgroup v2 |
| systemd | 245+ | Pending | For cgroup v2 driver |

## Version Compliance Policy
- **STRICT**: Only exact versions specified will be installed
- **NO SUBSTITUTIONS**: If a version is unavailable, stop and document
- **VERIFICATION**: Each component version must be verified post-installation
- **DOCUMENTATION**: Any version issues must be logged in `issues-XX.md`

## Update History
| Date | Component | Action | By |
|------|-----------|--------|-----|
| 2025-08-23 | Initial | Created version tracking | Setup |
