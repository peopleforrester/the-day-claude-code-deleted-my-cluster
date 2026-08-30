# SSH Setup Documentation for Kubernetes Cluster Upgrade

## Overview
This document provides comprehensive instructions for setting up SSH access between the Ansible control node and all Kubernetes cluster nodes for automated upgrade operations.

## Prerequisites
- Ansible control node (your workstation or dedicated automation server)
- Root or sudo access on all Kubernetes nodes
- Network connectivity to all nodes (192.168.0.50-58)

## Step 1: Generate SSH Keys on Ansible Control Node

### Option A: ED25519 Keys (Recommended - Most Secure)
```bash
# Generate ED25519 key pair (recommended for security and performance)
ssh-keygen -t ed25519 -C "ansible@homelab-k8s-upgrade" -f ~/.ssh/ansible_k8s_ed25519

# Set appropriate permissions
chmod 600 ~/.ssh/ansible_k8s_ed25519
chmod 644 ~/.ssh/ansible_k8s_ed25519.pub
```

### Option B: RSA Keys (Alternative - Wider Compatibility)
```bash
# Generate RSA key pair (4096 bits for enhanced security)
ssh-keygen -t rsa -b 4096 -C "ansible@homelab-k8s-upgrade" -f ~/.ssh/ansible_k8s_rsa

# Set appropriate permissions
chmod 600 ~/.ssh/ansible_k8s_rsa
chmod 644 ~/.ssh/ansible_k8s_rsa.pub
```

## Step 2: Configure SSH Config File

Create or update `~/.ssh/config` for easier management:

```bash
cat >> ~/.ssh/config << 'EOF'
# Kubernetes Cluster Nodes
Host k8s01 k8s-master-1
    HostName 192.168.0.50
    User root
    IdentityFile ~/.ssh/ansible_k8s_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile ~/.ssh/known_hosts

Host k8s02 k8s-master-2
    HostName 192.168.0.51
    User root
    IdentityFile ~/.ssh/ansible_k8s_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile ~/.ssh/known_hosts

Host k8s03 k8s-master-3
    HostName 192.168.0.52
    User root
    IdentityFile ~/.ssh/ansible_k8s_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile ~/.ssh/known_hosts

Host k8s04 k8s-worker-1
    HostName 192.168.0.53
    User root
    IdentityFile ~/.ssh/ansible_k8s_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile ~/.ssh/known_hosts

Host k8s05 k8s-worker-2
    HostName 192.168.0.54
    User root
    IdentityFile ~/.ssh/ansible_k8s_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile ~/.ssh/known_hosts

Host k8s06 k8s-worker-3
    HostName 192.168.0.55
    User root
    IdentityFile ~/.ssh/ansible_k8s_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile ~/.ssh/known_hosts

Host k8s07 k8s-worker-4
    HostName 192.168.0.56
    User root
    IdentityFile ~/.ssh/ansible_k8s_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile ~/.ssh/known_hosts

Host k8s08 k8s-worker-5
    HostName 192.168.0.57
    User root
    IdentityFile ~/.ssh/ansible_k8s_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile ~/.ssh/known_hosts

Host k8s09 k8s-worker-6
    HostName 192.168.0.58
    User root
    IdentityFile ~/.ssh/ansible_k8s_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile ~/.ssh/known_hosts

# Global settings for k8s nodes
Host k8s*
    Port 22
    Protocol 2
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
    Compression yes
    LogLevel ERROR
EOF

chmod 600 ~/.ssh/config
```

## Step 3: Distribute SSH Keys to All Nodes

### Automated Distribution Script
```bash
#!/bin/bash
# save as: distribute_keys.sh

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
KEY_FILE="${HOME}/.ssh/ansible_k8s_ed25519.pub"
NODES=(
    "192.168.0.50"  # k8s01
    "192.168.0.51"  # k8s02
    "192.168.0.52"  # k8s03
    "192.168.0.53"  # k8s04
    "192.168.0.54"  # k8s05
    "192.168.0.55"  # k8s06
    "192.168.0.56"  # k8s07
    "192.168.0.57"  # k8s08
    "192.168.0.58"  # k8s09
)

# Check if key exists
if [ ! -f "$KEY_FILE" ]; then
    echo -e "${RED}Error: SSH key not found at $KEY_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}Starting SSH key distribution...${NC}"
echo "You will be prompted for the root password for each node."
echo ""

# Distribute keys
for i in "${!NODES[@]}"; do
    NODE="${NODES[$i]}"
    NODE_NAME="k8s0$((i+1))"
    
    echo -e "${YELLOW}[$((i+1))/9] Copying SSH key to $NODE_NAME ($NODE)...${NC}"
    
    ssh-copy-id -i "$KEY_FILE" root@"$NODE" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully copied key to $NODE_NAME${NC}"
    else
        echo -e "${RED}✗ Failed to copy key to $NODE_NAME${NC}"
    fi
    echo ""
done

echo -e "${GREEN}SSH key distribution complete!${NC}"
```

### Manual Distribution (Alternative)
```bash
# Copy SSH key to each node individually
for i in {50..58}; do
    echo "Copying key to 192.168.0.$i..."
    ssh-copy-id -i ~/.ssh/ansible_k8s_ed25519.pub root@192.168.0.$i
done
```

## Step 4: Test SSH Connectivity

### Quick Connectivity Test
```bash
#!/bin/bash
# save as: test_ssh.sh

echo "Testing SSH connectivity to all Kubernetes nodes..."
echo "=========================================="

for i in {1..9}; do
    NODE="k8s0$i"
    IP="192.168.0.$((49+i))"
    
    echo -n "Testing $NODE ($IP): "
    
    if ssh -o ConnectTimeout=5 -o BatchMode=yes root@$IP "echo 'SSH OK' && hostname" 2>/dev/null; then
        echo "✓ Connection successful"
    else
        echo "✗ Connection failed"
    fi
done
```

### Ansible Connectivity Test
```bash
# Test with ansible ping module
ansible all -i inventory/hosts.yml -m ping

# Test with gathering facts
ansible all -i inventory/hosts.yml -m setup -a "filter=ansible_hostname"
```

## Step 5: Security Best Practices

### 1. Use SSH Agent
```bash
# Start SSH agent
eval $(ssh-agent -s)

# Add key to agent
ssh-add ~/.ssh/ansible_k8s_ed25519

# Verify key is loaded
ssh-add -l
```

### 2. Configure SSH Agent Forwarding
```bash
# Add to ~/.ssh/config
Host k8s*
    ForwardAgent yes
```

### 3. Implement SSH Key Rotation
```bash
#!/bin/bash
# Rotate SSH keys quarterly
# save as: rotate_keys.sh

DATE=$(date +%Y%m%d)
OLD_KEY="~/.ssh/ansible_k8s_ed25519"
NEW_KEY="~/.ssh/ansible_k8s_ed25519_${DATE}"

# Generate new key
ssh-keygen -t ed25519 -C "ansible@homelab-k8s-upgrade-${DATE}" -f $NEW_KEY

# Distribute new key (using old key for auth)
for i in {50..58}; do
    cat ${NEW_KEY}.pub | ssh -i $OLD_KEY root@192.168.0.$i \
        "cat >> ~/.ssh/authorized_keys"
done

# Update ansible.cfg to use new key
sed -i "s|private_key_file.*|private_key_file = ${NEW_KEY}|" ansible.cfg

echo "Key rotation complete. Test connectivity before removing old key."
```

### 4. Limit SSH Access
```bash
# On each Kubernetes node, configure sshd_config
cat >> /etc/ssh/sshd_config.d/10-ansible.conf << 'EOF'
# Ansible automation user restrictions
Match User root Address 192.168.0.0/24
    PermitRootLogin prohibit-password
    PubkeyAuthentication yes
    PasswordAuthentication no
    X11Forwarding no
    AllowAgentForwarding yes
    PermitTunnel no
    
# Log all ansible activities
Match User root
    LogLevel VERBOSE
EOF

# Restart SSH service
systemctl reload sshd
```

### 5. Implement Fail2ban for SSH Protection
```bash
# Install on all nodes
apt-get update && apt-get install -y fail2ban

# Configure fail2ban for SSH
cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
ignoreip = 192.168.0.0/24
EOF

# Start fail2ban
systemctl enable fail2ban
systemctl start fail2ban
```

## Step 6: SSH Key Backup

### Backup Strategy
```bash
#!/bin/bash
# save as: backup_keys.sh

BACKUP_DIR="${HOME}/ssh_key_backups/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup SSH keys
cp ~/.ssh/ansible_k8s_* "$BACKUP_DIR/"
cp ~/.ssh/config "$BACKUP_DIR/"
cp ~/.ssh/known_hosts "$BACKUP_DIR/"

# Encrypt backup
tar czf - "$BACKUP_DIR" | \
    openssl enc -aes-256-cbc -salt -out "${BACKUP_DIR}.tar.gz.enc"

# Store encryption password securely
echo "Backup created at: ${BACKUP_DIR}.tar.gz.enc"
echo "Store the encryption password in a secure password manager"
```

## Step 7: Troubleshooting

### Common Issues and Solutions

#### Issue 1: Permission Denied
```bash
# Check key permissions
ls -la ~/.ssh/ansible_k8s_*

# Fix permissions
chmod 600 ~/.ssh/ansible_k8s_ed25519
chmod 644 ~/.ssh/ansible_k8s_ed25519.pub
```

#### Issue 2: Host Key Verification Failed
```bash
# Remove old host key
ssh-keygen -R 192.168.0.50

# Accept new host key
ssh-keyscan -H 192.168.0.50 >> ~/.ssh/known_hosts
```

#### Issue 3: Connection Timeout
```bash
# Test network connectivity
ping -c 3 192.168.0.50

# Test SSH port
nc -zv 192.168.0.50 22

# Check firewall rules
sudo iptables -L -n | grep 22
```

#### Issue 4: Too Many Authentication Failures
```bash
# Specify exact key file
ssh -o IdentitiesOnly=yes -i ~/.ssh/ansible_k8s_ed25519 root@192.168.0.50
```

## Step 8: Ansible Integration

### Configure Ansible to Use SSH Keys
```yaml
# In ansible.cfg
[defaults]
host_key_checking = False
private_key_file = ~/.ssh/ansible_k8s_ed25519
remote_user = root

[ssh_connection]
ssh_args = -C -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
```

### Test Ansible Connectivity
```bash
# Test single host
ansible k8s01 -i inventory/hosts.yml -m ping

# Test group
ansible control_plane -i inventory/hosts.yml -m ping

# Test all hosts
ansible all -i inventory/hosts.yml -m ping

# Run ad-hoc command
ansible all -i inventory/hosts.yml -a "uname -r"
```

## Security Audit Checklist

- [ ] SSH keys are ED25519 or RSA 4096-bit minimum
- [ ] Private keys have 600 permissions
- [ ] Public keys have 644 permissions
- [ ] SSH agent is being used
- [ ] Keys are backed up securely
- [ ] Password authentication is disabled on all nodes
- [ ] Root login is restricted to key-based auth only
- [ ] SSH access is limited to management network
- [ ] Fail2ban is configured and active
- [ ] SSH logs are being monitored
- [ ] Key rotation schedule is established
- [ ] Known_hosts file is maintained
- [ ] Ansible vault is used for sensitive data

## Maintenance Schedule

| Task | Frequency | Command/Action |
|------|-----------|----------------|
| Test connectivity | Daily | `ansible all -m ping` |
| Rotate SSH keys | Quarterly | Run `rotate_keys.sh` |
| Audit authorized_keys | Monthly | Check for unauthorized keys |
| Update known_hosts | As needed | After node rebuilds |
| Backup keys | Weekly | Run `backup_keys.sh` |
| Review SSH logs | Weekly | Check `/var/log/auth.log` |

## Emergency Procedures

### Lost SSH Key Recovery
1. Access node via console (iDRAC/IPMI/Physical)
2. Generate new key pair on control node
3. Manually add public key to `/root/.ssh/authorized_keys`
4. Test connectivity
5. Update all nodes with new key

### Locked Out of Node
1. Boot into single-user mode
2. Mount root filesystem
3. Edit `/root/.ssh/authorized_keys`
4. Add emergency access key
5. Reboot and verify access

## References
- [OpenSSH Documentation](https://www.openssh.com/manual.html)
- [Ansible SSH Connection Plugin](https://docs.ansible.com/ansible/latest/plugins/connection/ssh.html)
- [SSH Security Best Practices](https://www.ssh.com/academy/ssh/security)