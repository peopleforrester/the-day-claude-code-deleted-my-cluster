#!/bin/bash
# Install essential troubleshooting and connectivity tools on all nodes

NODES=(50 51 52 53 54 55 56 57 58)
LOG_FILE="install-utilities.log"

echo "Installing troubleshooting utilities on all nodes" | tee $LOG_FILE
echo "Started: $(date)" | tee -a $LOG_FILE
echo "================================" | tee -a $LOG_FILE

# Essential packages to install
PACKAGES="
iputils-ping
netcat-openbsd
dnsutils
traceroute
tcpdump
net-tools
iptables
htop
vim
jq
curl
wget
telnet
nmap
iftop
iotop
sysstat
strace
lsof
bash-completion
software-properties-common
apt-transport-https
ca-certificates
gnupg
lsb-release
tree
tmux
rsync
"

for node in "${NODES[@]}"; do
    IP="192.168.0.$node"
    NODE_NAME="k8s$(printf '%02d' $((node - 49)))"

    echo "" | tee -a $LOG_FILE
    echo "Installing utilities on $NODE_NAME ($IP)..." | tee -a $LOG_FILE

    # Update package list first
    echo "  Updating package list..." | tee -a $LOG_FILE
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@$IP "apt-get update" >> $LOG_FILE 2>&1

    # Install packages
    echo "  Installing packages..." | tee -a $LOG_FILE
    ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=no root@$IP "DEBIAN_FRONTEND=noninteractive apt-get install -y $PACKAGES" >> $LOG_FILE 2>&1

    if [ $? -eq 0 ]; then
        echo "  ✓ Successfully installed utilities on $NODE_NAME" | tee -a $LOG_FILE
    else
        echo "  ✗ Failed to install some packages on $NODE_NAME" | tee -a $LOG_FILE
    fi

    # Quick verification
    echo "  Verifying key tools..." | tee -a $LOG_FILE
    ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$IP "which ping nc dig traceroute tcpdump jq" >> $LOG_FILE 2>&1
done

echo "" | tee -a $LOG_FILE
echo "================================" | tee -a $LOG_FILE
echo "Utility installation complete!" | tee -a $LOG_FILE
echo "Finished: $(date)" | tee -a $LOG_FILE

# Test connectivity between first two nodes
echo "" | tee -a $LOG_FILE
echo "Testing network tools..." | tee -a $LOG_FILE
ssh root@192.168.0.50 "ping -c 2 192.168.0.51" >> $LOG_FILE 2>&1 && echo "✓ Ping test successful" | tee -a $LOG_FILE
