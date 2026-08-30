#\!/bin/bash
# Gather system information from all nodes

NODES=(
  "192.168.0.183:master1:control-plane"
  "192.168.0.194:master2:control-plane"
  "192.168.0.196:master3:control-plane"
  "192.168.0.197:worker1:worker"
  "192.168.0.198:worker2:worker"
)

echo '{"cluster_name": "k8s-ha-cluster", "api_endpoint": "192.168.0.180:6443", "nodes": [' > steps/01-connectivity/inventory.json

first=true
for node_info in "${NODES[@]}"; do
  IFS=':' read -r ip hostname role <<< "$node_info"

  if [ "$first" = false ]; then
    echo "," >> steps/01-connectivity/inventory.json
  fi
  first=false

  # Gather node information
  cpu_cores=$(ssh -o StrictHostKeyChecking=no root@$ip "nproc" 2>/dev/null)
  memory_kb=$(ssh -o StrictHostKeyChecking=no root@$ip "grep MemTotal /proc/meminfo | awk '{print \$2}'" 2>/dev/null)
  memory_gb=$(( memory_kb / 1024 / 1024 ))
  kernel=$(ssh -o StrictHostKeyChecking=no root@$ip "uname -r" 2>/dev/null)

  cat >> steps/01-connectivity/inventory.json << JSON
  {
    "hostname": "$hostname",
    "ip": "$ip",
    "role": "$role",
    "os": "Ubuntu 24.04.2 LTS",
    "kernel": "$kernel",
    "cpu_cores": $cpu_cores,
    "memory_gb": $memory_gb,
    "status": "reachable"
  }
JSON
done

echo '],"timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"}'  >> steps/01-connectivity/inventory.json

# Pretty print the JSON
python3 -m json.tool steps/01-connectivity/inventory.json > steps/01-connectivity/inventory.json.tmp
mv steps/01-connectivity/inventory.json.tmp steps/01-connectivity/inventory.json
