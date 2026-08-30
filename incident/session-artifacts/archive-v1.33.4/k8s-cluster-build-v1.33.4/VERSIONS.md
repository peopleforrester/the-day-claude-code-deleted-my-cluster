# Component Version Tracking

## Core Components
| Component | Required Version | Installed Version | Date Installed | Notes |
|-----------|-----------------|-------------------|----------------|-------|
| Kubernetes | v1.33.4 | - | - | Latest GA as of Aug 2025 |
| containerd | v2.1.4 | - | - | v1.7.x EOL May 5, 2025 |
| kubeadm | v1.33.4 | - | - | Must match K8s version |
| kubelet | v1.33.4 | - | - | Must match K8s version |
| kubectl | v1.33.4 | - | - | Must match K8s version |

## Networking
| Component | Required Version | Installed Version | Date Installed | Notes |
|-----------|-----------------|-------------------|----------------|-------|
| Multus CNI | v4.2.2 | - | - | Meta CNI plugin |
| Cilium | v1.18.0 | - | - | cni.exclusive=false required |
| kube-vip | v1.0.0 | - | - | HA virtual IP |
| Ingress-NGINX | v1.13.1 | - | - | CVE-2025-1974 fixed |

## Storage
| Component | Required Version | Installed Version | Date Installed | Notes |
|-----------|-----------------|-------------------|----------------|-------|
| Longhorn | v1.9.0 | - | - | Distributed storage |

## Virtualization
| Component | Required Version | Installed Version | Date Installed | Notes |
|-----------|-----------------|-------------------|----------------|-------|
| KubeVirt | v1.5.0 | - | - | VM support |

## Monitoring & Management
| Component | Required Version | Installed Version | Date Installed | Notes |
|-----------|-----------------|-------------------|----------------|-------|
| metrics-server | v0.8.0 | - | - | Released July 2025 |
| Dashboard | v7.13.0 | - | - | Helm-only, Kong gateway |
| kube-state-metrics | latest | - | - | Cluster metrics |
| node-exporter | latest | - | - | Node metrics |

## Supporting Tools
| Component | Required Version | Installed Version | Date Installed | Notes |
|-----------|-----------------|-------------------|----------------|-------|
| Helm | v3.x | - | - | For Dashboard, Cilium |
| cert-manager | latest | - | - | TLS certificates |
| Kong | required by Dashboard | - | - | Gateway for Dashboard v7 |

## Version Compliance Rules
1. **EXACT VERSIONS ONLY**: No substitutions without explicit permission
2. **EOL AWARENESS**: containerd v1.7.x is EOL, must use v2.1.4
3. **COMPATIBILITY**: All K8s components must be v1.33.4
4. **DEPENDENCIES**: Dashboard v7 requires Kong gateway
5. **CNI CHAINING**: Cilium must be non-exclusive for Multus

## Version Verification Commands
```bash
# Kubernetes components
kubeadm version
kubectl version --client
kubelet --version

# Container runtime
containerd --version

# CNI plugins
kubectl get pods -n kube-system | grep multus
kubectl get pods -n kube-system | grep cilium
cilium version

# Storage
kubectl get pods -n longhorn-system
kubectl get crd | grep longhorn

# Virtualization
kubectl get pods -n kubevirt
kubectl get crd | grep kubevirt

# Monitoring
kubectl get deployment metrics-server -n kube-system -o jsonpath='{.spec.template.spec.containers[0].image}'
helm list -n kubernetes-dashboard
```

## Update Log
| Date | Component | From Version | To Version | Reason |
|------|-----------|--------------|------------|--------|
| - | - | - | - | Initial deployment |

---
*This file tracks all component versions to ensure compliance with specifications*
