# Kubernetes Cluster Upgrade Guide

## Overview
This guide provides detailed instructions for upgrading a Kubernetes cluster from v1.31.x to v1.32.x using the provided Ansible automation.

## Pre-Upgrade Checklist

- [ ] Verify SSH access to all nodes
- [ ] Confirm current cluster version is 1.31.x
- [ ] Check that all nodes are in Ready state
- [ ] Ensure sufficient disk space on all nodes (>10GB free)
- [ ] Review application compatibility with Kubernetes 1.32
- [ ] Schedule maintenance window (expect 1-2 hours for 9 nodes)
- [ ] Have rollback plan ready

## Upgrade Process

### 1. Preparation

```bash
# Navigate to the upgrade directory
cd kubernetes-upgrade/

# Verify inventory
ansible-inventory -i inventory/hosts.yml --graph

# Test connectivity
ansible all -i inventory/hosts.yml -m ping

# Run pre-upgrade validation
ansible-playbook -i inventory/hosts.yml playbooks/00-pre-upgrade-validation.yml
```

### 2. Add Kubernetes 1.32 Repository

The upgrade playbooks will automatically add the required repository, but you can do it manually:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/00-add-k8s-repo.yml
```

### 3. Backup Current State

```bash
# Create comprehensive backup
ansible-playbook -i inventory/hosts.yml playbooks/01-backup-cluster.yml
```

### 4. Upgrade Control Plane

Control plane nodes are upgraded one at a time:

```bash
# Upgrade all control plane nodes sequentially
ansible-playbook -i inventory/hosts.yml playbooks/02-upgrade-control-plane.yml

# Or upgrade specific control plane node
ansible-playbook -i inventory/hosts.yml playbooks/02-upgrade-control-plane.yml --limit k8s01
```

### 5. Upgrade Worker Nodes

Worker nodes are upgraded in batches (default: 2 at a time):

```bash
# Upgrade all worker nodes
ansible-playbook -i inventory/hosts.yml playbooks/03-upgrade-workers.yml

# Upgrade with custom batch size
ansible-playbook -i inventory/hosts.yml playbooks/03-upgrade-workers.yml -e "serial=3"

# Upgrade specific workers
ansible-playbook -i inventory/hosts.yml playbooks/03-upgrade-workers.yml --limit k8s04,k8s05
```

### 6. Post-Upgrade Validation

```bash
# Run validation tests
ansible-playbook -i inventory/hosts.yml playbooks/04-post-upgrade-validation.yml

# Verify all nodes are upgraded
ansible -i inventory/hosts.yml all -m shell -a "kubectl version --client --short" 
```

## Automated Full Upgrade

For a complete automated upgrade with all safety checks:

```bash
./upgrade-cluster.sh
```

Options:
- `--skip-tests`: Skip pre-upgrade tests (not recommended)
- `--skip-backup`: Skip backup creation (dangerous)
- `--batch-size N`: Number of workers to upgrade simultaneously (default: 2)
- `--dry-run`: Perform validation only

## Troubleshooting

### Common Issues

#### 1. Drain Operation Timeout
If node drain times out:
- Check for pods with PodDisruptionBudgets
- Look for stateful workloads that can't be evicted
- Manually investigate stuck pods: `kubectl get pods --all-namespaces --field-selector spec.nodeName=NODE_NAME`

#### 2. Package Version Conflicts
If APT package conflicts occur:
- Ensure the correct repository is configured
- Check for held packages: `dpkg --get-selections | grep hold`
- Clear APT cache: `apt-get clean && apt-get update`

#### 3. Node Fails to Rejoin
If a node doesn't rejoin after upgrade:
- Check kubelet logs: `journalctl -u kubelet -f`
- Verify certificates: `kubeadm certs check-expiration`
- Restart kubelet: `systemctl restart kubelet`

### Manual Recovery

If automation fails, you can manually upgrade a node:

```bash
# On the node
apt-get update
apt-get install -y kubeadm=1.32.8-1.1
kubeadm upgrade node
apt-get install -y kubelet=1.32.8-1.1 kubectl=1.32.8-1.1
systemctl daemon-reload
systemctl restart kubelet

# From control plane
kubectl uncordon NODE_NAME
```

## Rollback Procedure

If issues occur during upgrade:

```bash
# Use the rollback playbook
ansible-playbook -i inventory/hosts.yml playbooks/99-rollback.yml

# Or use the automated script
./upgrade-cluster.sh --rollback
```

## Verification

After successful upgrade:

```bash
# Check all node versions
kubectl get nodes -o wide

# Verify cluster components
kubectl get cs

# Check system pods
kubectl get pods -n kube-system

# Test application functionality
kubectl get pods --all-namespaces
```

## Important Notes

1. **Never skip the backup step** unless you have recent external backups
2. **Control plane must be upgraded before workers**
3. **Upgrade cannot be reversed once completed** (only rollback from backup)
4. **Monitor cluster health throughout the process**
5. **Test in non-production environment first**

## Support

For issues or questions:
- Check the TROUBLESHOOTING.md guide
- Review ansible logs in `logs/`
- Verify cluster events: `kubectl get events --all-namespaces`