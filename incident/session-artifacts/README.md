# Kubernetes Cluster Deployment with kubeadm

This repository contains scripts to automatically deploy a Kubernetes cluster on Ubuntu 24.04 VMs using kubeadm.

## Cluster Configuration

- **Master Node**: 192.168.0.183
- **Worker Nodes**:
  - Worker1: 192.168.0.191
  - Worker2: 192.168.0.194
  - Worker3: 192.168.0.196
  - Worker4: 192.168.0.197

## Prerequisites

- Ubuntu 24.04 VMs with SSH access
- User: `claude` with password: <REDACTED-PASSWORD>
- `sshpass` installed on the deployment machine

## Quick Start

1. **Install sshpass** (if not already installed):
   ```bash
   sudo apt-get update && sudo apt-get install -y sshpass
   ```

2. **Run the deployment script**:
   ```bash
   ./deploy_k8s_cluster.sh
   ```

   This script will:
   - Test SSH connectivity to all nodes
   - Install Kubernetes prerequisites on all nodes
   - Initialize the master node
   - Join worker nodes to the cluster
   - Install Calico as the CNI plugin
   - Verify cluster status

3. **Access the cluster**:
   ```bash
   source ./setup_kubectl.sh
   kubectl get nodes
   ```

## Scripts Overview

- `deploy_k8s_cluster.sh` - Main deployment orchestration script
- `install_k8s_prerequisites.sh` - Installs containerd, kubeadm, kubelet, kubectl
- `init_master.sh` - Initializes the Kubernetes master node
- `verify_cluster.sh` - Runs verification tests on the deployed cluster
- `setup_ssh_keys.sh` - Sets up SSH keys for passwordless access (optional)

## Verification

After deployment, run the verification script:
```bash
./verify_cluster.sh
```

This will:
- Check node status
- Verify system pods
- Deploy a test application
- Test service connectivity
- Verify cluster DNS

## Network Configuration

- Pod Network CIDR: 10.244.0.0/16
- CNI Plugin: Calico v3.28.0

## Troubleshooting

If deployment fails:
1. Check SSH connectivity to all nodes
2. Ensure all VMs have internet access
3. Verify that swap is disabled on all nodes
4. Check system logs: `journalctl -xeu kubelet`

## Manual Installation

If you prefer to install manually on each node:

1. Copy and run `install_k8s_prerequisites.sh` on all nodes
2. On master: Run `init_master.sh`
3. On workers: Run the join command from `/home/claude/kubeadm_join_command.sh`
