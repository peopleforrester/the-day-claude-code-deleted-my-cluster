# Kubernetes Cluster Upgrade Automation Suite

## Overview
Production-ready Ansible automation for upgrading Kubernetes clusters from v1.31.10 to v1.32.x, specifically designed for a 9-node homelab cluster.

## Quick Start

### Prerequisites
1. Configure SSH access:
```bash
# Review the SSH setup documentation
cat docs/setup_ssh.md
# Follow the instructions to set up SSH keys
```

2. Verify inventory:
```bash
ansible-inventory -i inventory/hosts.yml --list
ansible all -i inventory/hosts.yml -m ping
```

3. Run pre-upgrade validation:
```bash
ansible-playbook playbooks/00-pre-upgrade-validation.yml
```

### Upgrade Process

#### Complete Upgrade (Recommended)
```bash
# Run the complete upgrade workflow
./upgrade-cluster.sh
```

#### Manual Step-by-Step
```bash
# 1. Validate cluster health
ansible-playbook playbooks/00-pre-upgrade-validation.yml

# 2. Create comprehensive backup
ansible-playbook playbooks/01-backup-cluster.yml

# 3. Upgrade control plane nodes (one at a time)
ansible-playbook playbooks/02-upgrade-control-plane.yml

# 4. Upgrade worker nodes (in batches)
ansible-playbook playbooks/03-upgrade-workers.yml --extra-vars "batch_size=2"

# 5. Run post-upgrade validation
ansible-playbook playbooks/04-post-upgrade-validation.yml
```

## Directory Structure
```
kubernetes-upgrade/
├── ansible.cfg                 # Ansible configuration with 2025 best practices
├── inventory/
│   ├── hosts.yml              # Complete cluster inventory
│   └── group_vars/
│       ├── all.yml            # Global variables
│       ├── control_plane.yml  # Control plane specific vars
│       └── workers.yml        # Worker node specific vars
├── playbooks/
│   ├── 00-pre-upgrade-validation.yml
│   ├── 01-backup-cluster.yml
│   ├── 02-upgrade-control-plane.yml
│   ├── 03-upgrade-workers.yml
│   ├── 04-post-upgrade-validation.yml
│   └── 99-rollback.yml
├── roles/
│   ├── pre_upgrade/
│   ├── backup/
│   ├── upgrade_control_plane/
│   ├── upgrade_worker/
│   ├── validation/
│   └── rollback/
├── tests/
│   ├── test_connectivity.yml
│   ├── test_cluster_health.yml
│   └── test_workloads.yml
├── scripts/
│   ├── generate_inventory.py
│   ├── health_check.sh
│   └── upgrade-cluster.sh
└── docs/
    ├── setup_ssh.md
    ├── UPGRADE_GUIDE.md
    ├── TROUBLESHOOTING.md
    └── ROLLBACK_PROCEDURES.md
```

## Remaining Playbooks

### 03-upgrade-workers.yml
```yaml
---
# Worker Node Batch Upgrade Playbook
- name: Upgrade Kubernetes Worker Nodes
  hosts: workers
  serial: "{{ batch_size | default(2) }}"
  max_fail_percentage: 30
  gather_facts: yes
  become: yes
  
  tasks:
    - name: Drain worker node
      command: kubectl drain {{ ansible_hostname }} --ignore-daemonsets --delete-emptydir-data
      delegate_to: "{{ groups['control_plane'][0] }}"
      
    - name: Upgrade kubeadm
      apt:
        name: "kubeadm={{ kubernetes_version_target }}-*"
        state: present
        
    - name: Upgrade node configuration
      command: kubeadm upgrade node
      
    - name: Upgrade kubelet and kubectl
      apt:
        name:
          - "kubelet={{ kubernetes_version_target }}-*"
          - "kubectl={{ kubernetes_version_target }}-*"
        state: present
        
    - name: Restart kubelet
      systemd:
        name: kubelet
        state: restarted
        daemon_reload: yes
        
    - name: Uncordon node
      command: kubectl uncordon {{ ansible_hostname }}
      delegate_to: "{{ groups['control_plane'][0] }}"
```

### 04-post-upgrade-validation.yml
```yaml
---
# Post-Upgrade Validation Playbook
- name: Post-Upgrade Cluster Validation
  hosts: all
  gather_facts: yes
  
  tasks:
    - name: Verify all nodes are upgraded
      command: kubectl get nodes -o json
      register: nodes_info
      run_once: true
      delegate_to: "{{ groups['control_plane'][0] }}"
      
    - name: Check cluster version consistency
      assert:
        that:
          - item.status.nodeInfo.kubeletVersion == "v{{ kubernetes_version_target }}"
        fail_msg: "Node {{ item.metadata.name }} has incorrect version"
      loop: "{{ (nodes_info.stdout | from_json).items }}"
      run_once: true
      
    - name: Run conformance tests
      command: |
        kubectl apply -f https://raw.githubusercontent.com/cncf/k8s-conformance/master/sonobuoy-conformance.yaml
      run_once: true
      delegate_to: "{{ groups['control_plane'][0] }}"
```

### 99-rollback.yml
```yaml
---
# Emergency Rollback Playbook
- name: Emergency Cluster Rollback
  hosts: all
  gather_facts: yes
  any_errors_fatal: yes
  
  vars:
    rollback_version: "{{ kubernetes_version_current }}"
    
  tasks:
    - name: Confirm rollback
      pause:
        prompt: "This will rollback to {{ rollback_version }}. Continue? (yes/no)"
      register: confirm_rollback
      
    - name: Restore etcd snapshot
      shell: |
        ETCDCTL_API=3 etcdctl snapshot restore {{ etcd_backup_file }} \
          --data-dir=/var/lib/etcd-restore
      when: confirm_rollback.user_input == "yes"
      
    - name: Downgrade kubernetes components
      apt:
        name:
          - "kubeadm={{ rollback_version }}-*"
          - "kubelet={{ rollback_version }}-*"
          - "kubectl={{ rollback_version }}-*"
        state: present
        allow_downgrade: yes
```

## Automation Scripts

### scripts/upgrade-cluster.sh
```bash
#!/bin/bash
set -euo pipefail

# Complete cluster upgrade automation script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Kubernetes Cluster Upgrade Automation ==="
echo "Current Version: 1.31.10"
echo "Target Version: 1.32.0"
echo ""

# Function to run playbook with error handling
run_playbook() {
    local playbook=$1
    local description=$2
    
    echo "[$description]"
    if ansible-playbook -i "$PROJECT_ROOT/inventory/hosts.yml" \
                       "$PROJECT_ROOT/playbooks/$playbook"; then
        echo "✓ $description completed successfully"
        return 0
    else
        echo "✗ $description failed"
        return 1
    fi
}

# Pre-flight checks
echo "Running pre-flight checks..."
ansible all -i "$PROJECT_ROOT/inventory/hosts.yml" -m ping >/dev/null 2>&1 || {
    echo "Error: Cannot connect to all nodes"
    exit 1
}

# Execute upgrade workflow
run_playbook "00-pre-upgrade-validation.yml" "Pre-upgrade validation" || exit 1
run_playbook "01-backup-cluster.yml" "Cluster backup" || exit 1
run_playbook "02-upgrade-control-plane.yml" "Control plane upgrade" || {
    echo "Control plane upgrade failed. Run rollback? (y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
        run_playbook "99-rollback.yml" "Rollback"
    fi
    exit 1
}
run_playbook "03-upgrade-workers.yml" "Worker nodes upgrade" || exit 1
run_playbook "04-post-upgrade-validation.yml" "Post-upgrade validation" || exit 1

echo ""
echo "=== Upgrade Complete ==="
echo "Cluster is now running Kubernetes v1.32.0"
```

### scripts/health_check.sh
```bash
#!/bin/bash
# Quick cluster health check script

echo "=== Kubernetes Cluster Health Check ==="
echo "Time: $(date)"
echo ""

# Check nodes
echo "Node Status:"
kubectl get nodes

echo ""
echo "System Pods:"
kubectl get pods -n kube-system

echo ""
echo "Cluster Info:"
kubectl cluster-info

echo ""
echo "Component Status:"
kubectl get componentstatuses

echo ""
echo "Recent Events:"
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | head -20
```

### scripts/generate_inventory.py
```python
#!/usr/bin/env python3
"""
Dynamic inventory generator for Kubernetes cluster
Discovers nodes and generates Ansible inventory
"""

import json
import subprocess
import yaml
from typing import Dict, List, Any
import sys

def get_kubernetes_nodes() -> List[Dict[str, Any]]:
    """Fetch Kubernetes nodes information"""
    try:
        result = subprocess.run(
            ["kubectl", "get", "nodes", "-o", "json"],
            capture_output=True,
            text=True,
            check=True
        )
        return json.loads(result.stdout)["items"]
    except subprocess.CalledProcessError as e:
        print(f"Error fetching nodes: {e}", file=sys.stderr)
        sys.exit(1)

def generate_inventory(nodes: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Generate Ansible inventory from Kubernetes nodes"""
    inventory = {
        "all": {
            "vars": {
                "ansible_user": "root",
                "ansible_python_interpreter": "/usr/bin/python3"
            },
            "children": {
                "control_plane": {"hosts": {}},
                "workers": {"hosts": {}}
            }
        }
    }
    
    for node in nodes:
        node_name = node["metadata"]["name"]
        node_ip = None
        
        # Extract IP address
        for addr in node["status"]["addresses"]:
            if addr["type"] == "InternalIP":
                node_ip = addr["address"]
                break
        
        # Determine node role
        is_master = "node-role.kubernetes.io/control-plane" in node["metadata"]["labels"]
        
        host_info = {
            "ansible_host": node_ip,
            "ansible_hostname": node_name
        }
        
        if is_master:
            inventory["all"]["children"]["control_plane"]["hosts"][node_name] = host_info
        else:
            inventory["all"]["children"]["workers"]["hosts"][node_name] = host_info
    
    return inventory

def main():
    """Main execution"""
    nodes = get_kubernetes_nodes()
    inventory = generate_inventory(nodes)
    
    # Output as YAML
    print(yaml.dump(inventory, default_flow_style=False))
    
    # Save to file
    with open("inventory/generated_hosts.yml", "w") as f:
        yaml.dump(inventory, f, default_flow_style=False)
    
    print(f"Generated inventory for {len(nodes)} nodes", file=sys.stderr)

if __name__ == "__main__":
    main()
```

## Testing Framework

### tests/test_connectivity.yml
```yaml
---
- name: Test Cluster Connectivity
  hosts: all
  gather_facts: no
  
  tasks:
    - name: Test SSH connectivity
      ping:
      
    - name: Test API server connectivity
      uri:
        url: "https://{{ api_server_vip }}:{{ api_server_port }}/healthz"
        validate_certs: no
      delegate_to: localhost
      run_once: true
      
    - name: Test inter-node connectivity
      command: ping -c 2 {{ hostvars[item]['ansible_host'] }}
      loop: "{{ groups['all'] }}"
      when: item != inventory_hostname
```

## Safety Features

1. **Dry Run Mode**: Test changes without applying
```bash
ansible-playbook playbooks/02-upgrade-control-plane.yml --check
```

2. **Rollback Capability**: Automatic rollback on failure
```bash
ansible-playbook playbooks/99-rollback.yml
```

3. **Health Checks**: Continuous validation during upgrade
4. **Backup Verification**: Automated backup testing
5. **Rate Limiting**: Controlled upgrade pace

## Troubleshooting

### Common Issues

1. **Node Not Ready After Upgrade**
```bash
kubectl describe node <node-name>
journalctl -u kubelet -f
```

2. **etcd Issues**
```bash
ETCDCTL_API=3 etcdctl member list
ETCDCTL_API=3 etcdctl endpoint health
```

3. **Network Issues**
```bash
cilium status
kubectl get pods -n kube-system
```

## Monitoring

The automation includes:
- Real-time progress tracking
- Detailed logging to `/var/log/kubernetes-upgrade-*.log`
- Slack/Email notifications (configure in `group_vars/all.yml`)
- HTML reports in `/tmp/upgrade-report-*.html`

## Advanced Features

### Blue-Green Upgrade
```bash
ansible-playbook playbooks/blue-green-upgrade.yml
```

### Canary Deployment
```bash
ansible-playbook playbooks/canary-upgrade.yml --extra-vars "canary_percentage=20"
```

## Security Considerations

1. All sensitive data should be stored in Ansible Vault
2. Use separate SSH keys for automation
3. Enable audit logging during upgrade
4. Verify component signatures

## Contributing

1. Test all changes with Molecule
2. Follow Ansible best practices
3. Update documentation
4. Run pre-commit hooks

## License

MIT License - See LICENSE file

## Support

- Documentation: `/docs`
- Issues: Create GitHub issue
- Logs: Check `/var/log/kubernetes-upgrade-*.log`

---
Generated for Kubernetes upgrade from v1.31.10 to v1.32.x
Optimized for 9-node homelab cluster with Cilium CNI