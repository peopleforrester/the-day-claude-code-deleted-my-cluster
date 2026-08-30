#!/bin/bash
# Enhanced cluster test with verbose output and pod issue detection
# Usage: ./test-cluster-verbose.sh [master-ip]

MASTER=${1:-192.168.0.100}
SSH="ssh -o StrictHostKeyChecking=no root@$MASTER"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${BOLD}🔍 Testing Kubernetes cluster at $MASTER...${NC}"
echo "================================================"

# 1. Node Test
echo -e "\n${YELLOW}1. NODE STATUS TEST${NC}"
echo "   Checking if all 5 nodes (3 masters + 2 workers) are Ready..."
node_output=$($SSH 'kubectl get nodes')
total_nodes=$($SSH 'kubectl get nodes --no-headers | wc -l')
ready_nodes=$($SSH 'kubectl get nodes --no-headers | grep " Ready" | wc -l')
not_ready=$($SSH 'kubectl get nodes --no-headers | grep "NotReady" | wc -l')

if [ "$ready_nodes" -eq 5 ] && [ "$not_ready" -eq 0 ]; then
    echo -e "   ${GREEN}✅ PASSED${NC}: All $ready_nodes/$total_nodes nodes are Ready"
else
    echo -e "   ${RED}❌ FAILED${NC}: Only $ready_nodes/$total_nodes nodes Ready, $not_ready NotReady"
    echo "   Problem nodes:"
    $SSH 'kubectl get nodes | grep -E "NotReady|Unknown"' | sed 's/^/      /'
fi

# 2. Pod Health Test with Details
echo -e "\n${YELLOW}2. POD HEALTH TEST${NC}"
echo "   Checking all pods across all namespaces..."
total_pods=$($SSH 'kubectl get pods -A --no-headers | wc -l')
running_pods=$($SSH 'kubectl get pods -A --no-headers | grep -c "Running"')
completed_pods=$($SSH 'kubectl get pods -A --no-headers | grep -c "Completed"')
healthy_pods=$((running_pods + completed_pods))
problem_pods=$($SSH 'kubectl get pods -A --no-headers | grep -v "Running" | grep -v "Completed" | wc -l')

if [ "$problem_pods" -eq 0 ]; then
    echo -e "   ${GREEN}✅ PASSED${NC}: All $healthy_pods/$total_pods pods are healthy (Running/Completed)"
else
    echo -e "   ${RED}❌ FAILED${NC}: Found $problem_pods problematic pods out of $total_pods total"
    echo "   Problem pods:"
    $SSH 'kubectl get pods -A | grep -v "Running" | grep -v "Completed" | grep -v "NAME"' | head -10 | sed 's/^/      /'

    # Check specific issues
    error_pods=$($SSH 'kubectl get pods -A --no-headers | grep -c "Error"')
    crash_pods=$($SSH 'kubectl get pods -A --no-headers | grep -c "CrashLoopBackOff"')
    pending_pods=$($SSH 'kubectl get pods -A --no-headers | grep -c "Pending"')
    init_pods=$($SSH 'kubectl get pods -A --no-headers | grep -c "Init:"')

    [ "$error_pods" -gt 0 ] && echo "      - $error_pods pods in Error state"
    [ "$crash_pods" -gt 0 ] && echo "      - $crash_pods pods in CrashLoopBackOff"
    [ "$pending_pods" -gt 0 ] && echo "      - $pending_pods pods Pending"
    [ "$init_pods" -gt 0 ] && echo "      - $init_pods pods still Initializing"
fi

# 3. Metrics Server Test
echo -e "\n${YELLOW}3. METRICS SERVER TEST${NC}"
echo "   Checking if metrics-server is collecting node/pod metrics..."
if $SSH 'kubectl top nodes >/dev/null 2>&1'; then
    echo -e "   ${GREEN}✅ PASSED${NC}: Metrics server is working"
    avg_cpu=$($SSH 'kubectl top nodes --no-headers | awk "{sum+=\$2} END {print int(sum/NR)}"')
    avg_mem=$($SSH 'kubectl top nodes --no-headers | awk "{sum+=\$4} END {print int(sum/NR)}"')
    echo "      Average CPU: ${avg_cpu}% | Average Memory: ${avg_mem}%"
else
    echo -e "   ${RED}❌ FAILED${NC}: Metrics server not responding"
    metrics_pod=$($SSH 'kubectl get pods -n kube-system | grep metrics-server')
    echo "      Metrics pod status: $metrics_pod"
fi

# 4. Ingress Controller Test
echo -e "\n${YELLOW}4. INGRESS CONTROLLER TEST${NC}"
echo "   Checking NGINX ingress controller and NodePorts..."
ingress_pod=$($SSH 'kubectl get pods -n ingress-nginx | grep controller | grep -c Running')
ingress_svc=$($SSH 'kubectl get svc -n ingress-nginx ingress-nginx-controller --no-headers 2>/dev/null | wc -l')
http_port=$($SSH 'kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath="{.spec.ports[0].nodePort}" 2>/dev/null')
https_port=$($SSH 'kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath="{.spec.ports[1].nodePort}" 2>/dev/null')

if [ "$ingress_pod" -eq 1 ] && [ "$ingress_svc" -eq 1 ]; then
    echo -e "   ${GREEN}✅ PASSED${NC}: Ingress controller running"
    echo "      HTTP NodePort: $http_port | HTTPS NodePort: $https_port"
else
    echo -e "   ${RED}❌ FAILED${NC}: Ingress controller issues"
    [ "$ingress_pod" -eq 0 ] && echo "      - Controller pod not running"
    [ "$ingress_svc" -eq 0 ] && echo "      - Service not found"
fi

# 5. Dashboard Test
echo -e "\n${YELLOW}5. KUBERNETES DASHBOARD TEST${NC}"
echo "   Checking dashboard deployment and accessibility..."
dashboard_pods=$($SSH 'kubectl get pods -n kubernetes-dashboard --no-headers | grep -c Running')
dashboard_total=$($SSH 'kubectl get pods -n kubernetes-dashboard --no-headers | wc -l')
dashboard_svc=$($SSH 'kubectl get svc -n kubernetes-dashboard kubernetes-dashboard --no-headers 2>/dev/null | wc -l')

if [ "$dashboard_pods" -eq "$dashboard_total" ] && [ "$dashboard_pods" -ge 2 ]; then
    echo -e "   ${GREEN}✅ PASSED${NC}: Dashboard running ($dashboard_pods/$dashboard_total pods)"
    echo "      Access: https://$MASTER:32676 or https://dashboard.k8s.local"
else
    echo -e "   ${RED}❌ FAILED${NC}: Dashboard issues ($dashboard_pods/$dashboard_total pods running)"
    $SSH 'kubectl get pods -n kubernetes-dashboard' | grep -v Running | sed 's/^/      /'
fi

# 6. Test Application
echo -e "\n${YELLOW}6. TEST APPLICATION CHECK${NC}"
echo "   Checking nginx test app deployment and HPA..."
app_pods=$($SSH 'kubectl get pods -n test-app --no-headers | grep -c Running')
app_total=$($SSH 'kubectl get pods -n test-app --no-headers | wc -l')
app_nodes=$($SSH 'kubectl get pods -n test-app -o jsonpath="{.items[*].spec.nodeName}" | tr " " "\n" | sort -u | wc -l')
hpa_status=$($SSH 'kubectl get hpa -n test-app nginx-test --no-headers 2>/dev/null | awk "{print \$2,\$3,\$5}"')

if [ "$app_pods" -eq "$app_total" ] && [ "$app_pods" -ge 3 ]; then
    echo -e "   ${GREEN}✅ PASSED${NC}: Test app running ($app_pods/$app_total pods)"
    echo "      Distribution: Pods on $app_nodes different nodes"
    echo "      HPA status: $hpa_status"
else
    echo -e "   ${RED}❌ FAILED${NC}: Test app issues ($app_pods/$app_total pods running)"
    $SSH 'kubectl get pods -n test-app' | grep -v Running | sed 's/^/      /'
fi

# 7. CNI (Calico) Test
echo -e "\n${YELLOW}7. CALICO CNI TEST${NC}"
echo "   Checking Calico networking components..."
calico_nodes=$($SSH 'kubectl get pods -n calico-system -l k8s-app=calico-node --no-headers | grep -c Running')
calico_total_nodes=$($SSH 'kubectl get pods -n calico-system -l k8s-app=calico-node --no-headers | wc -l')
calico_controller=$($SSH 'kubectl get pods -n calico-system | grep calico-kube-controllers | grep -c Running')

if [ "$calico_nodes" -eq 5 ] && [ "$calico_controller" -ge 1 ]; then
    echo -e "   ${GREEN}✅ PASSED${NC}: Calico CNI operational"
    echo "      Calico nodes: $calico_nodes/$calico_total_nodes running"
    echo "      Controller: Active"
else
    echo -e "   ${RED}❌ FAILED${NC}: Calico CNI issues"
    echo "      Calico nodes: $calico_nodes/$calico_total_nodes running"
    [ "$calico_controller" -eq 0 ] && echo "      - Controller not running"
fi

# 8. etcd Cluster Test
echo -e "\n${YELLOW}8. ETCD CLUSTER TEST${NC}"
echo "   Checking etcd cluster health..."
etcd_pods=$($SSH 'kubectl get pods -n kube-system | grep etcd | grep -c Running')
if [ "$etcd_pods" -eq 3 ]; then
    echo -e "   ${GREEN}✅ PASSED${NC}: etcd cluster healthy (3 members)"
else
    echo -e "   ${RED}❌ FAILED${NC}: etcd issues (only $etcd_pods/3 members running)"
fi

echo -e "\n${BOLD}================================================${NC}"
echo -e "${BOLD}🏁 Test Summary:${NC}"
echo "   Cluster: $MASTER"
echo "   Time: $(date)"
echo -e "${BOLD}================================================${NC}\n"
