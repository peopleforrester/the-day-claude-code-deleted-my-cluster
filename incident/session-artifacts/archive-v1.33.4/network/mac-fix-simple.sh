#!/bin/bash
# Simplified MAC fix script - no dependencies required
# Run with nohup or systemd-run to survive disconnect

NODE_IP=$(hostname -I | awk '{print $1}')
NODE_OCTET=${NODE_IP##*.}
NEW_MAC="52:54:00:00:00:${NODE_OCTET}"
OLD_MAC=$(ip link show br0 | grep ether | awk '{print $2}')

echo "$(date): Starting MAC change on ${NODE_IP}" >> /var/log/mac-change.log
echo "Old MAC: ${OLD_MAC}, New MAC: ${NEW_MAC}" >> /var/log/mac-change.log

# Create a rollback script that will run after 120 seconds
(
  sleep 120
  # Check if we can still ping gateway
  if ! ping -c 2 -W 2 192.168.0.1 > /dev/null 2>&1; then
    echo "$(date): No connectivity after 120s, rolling back" >> /var/log/mac-change.log
    ip link set br0 down
    ip link set br0 address ${OLD_MAC}
    ip link set br0 up
    # Re-add IP if needed
    ip addr add ${NODE_IP}/24 dev br0 2>/dev/null
    ip route add default via 192.168.0.1 dev br0 2>/dev/null
    echo "$(date): Rollback completed" >> /var/log/mac-change.log
  else
    echo "$(date): Connectivity OK, keeping new MAC" >> /var/log/mac-change.log
  fi
) &
ROLLBACK_PID=$!

# Change the MAC
ip link set br0 down
ip link set br0 address ${NEW_MAC}
ip link set br0 up

# Ensure IP stays
sleep 2
if ! ip addr show br0 | grep -q "${NODE_IP}"; then
  ip addr add ${NODE_IP}/24 dev br0
fi

# Ensure route stays
if ! ip route | grep -q default; then
  ip route add default via 192.168.0.1 dev br0
fi

# Clear ARP
ip neigh flush all

echo "$(date): MAC change applied, new MAC: $(ip link show br0 | grep ether | awk '{print $2}')" >> /var/log/mac-change.log

# Quick test
sleep 3
if ping -c 2 -W 2 192.168.0.1 > /dev/null 2>&1; then
  echo "$(date): SUCCESS - Gateway reachable" >> /var/log/mac-change.log
  # Kill the rollback process
  kill $ROLLBACK_PID 2>/dev/null
else
  echo "$(date): WARNING - Gateway not reachable, rollback will occur in <2 minutes" >> /var/log/mac-change.log
fi
