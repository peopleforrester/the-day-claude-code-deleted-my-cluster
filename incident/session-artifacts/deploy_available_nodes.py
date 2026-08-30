#!/usr/bin/env python3
# ABOUTME: Deploy Kubernetes to available nodes only
# ABOUTME: Skips nodes that are not accessible

import paramiko
import time
import sys
import os
from datetime import datetime
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
import socket

# VM configuration
ALL_VMS = {
    "master": "192.168.0.183",
    "worker1": "192.168.0.191",
    "worker2": "192.168.0.194",
    "worker3": "192.168.0.196",
    "worker4": "192.168.0.197"
}

SSH_USER = "root"
SSH_PASS = "demo123"

# Color codes
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'

def print_status(message, color=Colors.GREEN):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"{color}[{timestamp}]{Colors.END} {message}")

def print_error(message):
    print_status(f"ERROR: {message}", Colors.RED)

def print_warning(message):
    print_status(f"WARNING: {message}", Colors.YELLOW)

def check_port(host, port=22, timeout=2):
    """Check if port is open"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    try:
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except:
        return False

def test_connectivity():
    """Test SSH connectivity and return available nodes"""
    print_status("Testing connectivity to all nodes...")
    available_vms = {}

    for node, ip in ALL_VMS.items():
        if check_port(ip):
            try:
                client = paramiko.SSHClient()
                client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
                client.connect(ip, username=SSH_USER, password=<REDACTED-PASSWORD>, timeout=5)
                stdin, stdout, stderr = client.exec_command("echo 'Connected'")
                output = stdout.read().decode('utf-8')
                if "Connected" in output:
                    print_status(f"✓ {node} ({ip}) is available")
                    available_vms[node] = ip
                client.close()
            except Exception as e:
                print_warning(f"{node} ({ip}) SSH failed: {str(e)}")
        else:
            print_warning(f"{node} ({ip}) is not accessible")

    return available_vms

def execute_ssh_command(hostname, command, get_output=False):
    """Execute command on remote host via SSH"""
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        client.connect(hostname, username=SSH_USER, password=<REDACTED-PASSWORD>, timeout=10)
        stdin, stdout, stderr = client.exec_command(command, get_pty=True)

        if get_output:
            output = stdout.read().decode('utf-8')
            error = stderr.read().decode('utf-8')
            return output, error
        else:
            # Stream output in real-time
            for line in iter(stdout.readline, ""):
                print(line, end="")
            stdout.channel.recv_exit_status()

        return True
    except Exception as e:
        print_error(f"SSH command failed on {hostname}: {str(e)}")
        return False if not get_output else ("", str(e))
    finally:
        client.close()

def copy_file_to_remote(hostname, local_path, remote_path):
    """Copy file to remote host via SCP"""
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        client.connect(hostname, username=SSH_USER, password=<REDACTED-PASSWORD>, timeout=10)
        sftp = client.open_sftp()
        sftp.put(local_path, remote_path)
        sftp.close()
        return True
    except Exception as e:
        print_error(f"File copy failed to {hostname}: {str(e)}")
        return False
    finally:
        client.close()

def install_prerequisites_on_node(node, ip):
    """Install Kubernetes prerequisites on a single node"""
    print_status(f"Installing prerequisites on {node}...")

    # Copy installation script
    if not copy_file_to_remote(ip, "install_k8s_prerequisites.sh", "/tmp/install_k8s_prerequisites.sh"):
        return False

    # Make executable and run
    commands = [
        "chmod +x /tmp/install_k8s_prerequisites.sh",
        "sudo /tmp/install_k8s_prerequisites.sh"
    ]

    for cmd in commands:
        if not execute_ssh_command(ip, cmd):
            return False

    print_status(f"✓ Prerequisites installed on {node}")
    return True

def initialize_master(master_ip):
    """Initialize Kubernetes master node"""
    print_status("Initializing Kubernetes master node...")

    # Copy initialization script
    if not copy_file_to_remote(master_ip, "init_master.sh", "/tmp/init_master.sh"):
        return False, ""

    # Run initialization
    commands = [
        "chmod +x /tmp/init_master.sh",
        "sudo /tmp/init_master.sh"
    ]

    for cmd in commands:
        if not execute_ssh_command(master_ip, cmd):
            return False, ""

    # Get join command
    print_status("Retrieving join command...")
    join_cmd, _ = execute_ssh_command(master_ip, "cat /root/kubeadm_join_command.sh", get_output=True)

    if not join_cmd:
        print_error("Failed to retrieve join command")
        return False, ""

    print_status("✓ Master node initialized")
    return True, join_cmd.strip()

def join_worker(node, ip, join_command):
    """Join a worker node to the cluster"""
    print_status(f"Joining {node} to the cluster...")

    if execute_ssh_command(ip, f"sudo {join_command}"):
        print_status(f"✓ {node} joined successfully")
        return True
    else:
        print_error(f"Failed to join {node}")
        return False

def verify_cluster(master_ip):
    """Verify cluster status"""
    print_status("Verifying cluster status...")

    # Wait for nodes to be ready
    print_status("Waiting for nodes to be ready...")
    time.sleep(30)

    # Get node status
    output, _ = execute_ssh_command(master_ip, "kubectl get nodes", get_output=True)
    print("\nCluster status:")
    print(output)

    # Copy kubeconfig
    print_status("Copying kubeconfig to local machine...")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        client.connect(master_ip, username=SSH_USER, password=<REDACTED-PASSWORD>
        sftp = client.open_sftp()
        sftp.get("/root/.kube/config", "./kubeconfig")
        sftp.close()

        with open("setup_kubectl.sh", "w") as f:
            f.write(f"export KUBECONFIG={os.getcwd()}/kubeconfig\n")
        os.chmod("setup_kubectl.sh", 0o755)

        print_status("✓ Kubeconfig copied successfully")
    except Exception as e:
        print_error(f"Failed to copy kubeconfig: {str(e)}")
    finally:
        client.close()

def main():
    print_status("Starting Kubernetes cluster deployment", Colors.BLUE)

    # Step 1: Test connectivity and get available nodes
    available_vms = test_connectivity()

    if "master" not in available_vms:
        print_error("Master node is not available. Cannot proceed.")
        sys.exit(1)

    worker_vms = {k: v for k, v in available_vms.items() if k != "master"}

    print()
    print_status(f"Deploying to {len(available_vms)} available nodes", Colors.BLUE)
    print_status(f"Master: {available_vms['master']}")
    print_status(f"Workers: {', '.join(worker_vms.keys())}")
    print()

    # Step 2: Install prerequisites on all available nodes
    print_status("Installing prerequisites on all nodes...")
    with ThreadPoolExecutor(max_workers=len(available_vms)) as executor:
        futures = {}
        for node, ip in available_vms.items():
            future = executor.submit(install_prerequisites_on_node, node, ip)
            futures[future] = node

        for future in as_completed(futures):
            node = futures[future]
            if not future.result():
                print_error(f"Failed to install prerequisites on {node}")
                # Continue with other nodes

    # Step 3: Initialize master
    print_status("Initializing master node...")
    success, join_command = initialize_master(available_vms["master"])
    if not success:
        print_error("Master initialization failed")
        sys.exit(1)

    # Step 4: Join available workers
    if worker_vms:
        print_status("Joining worker nodes...")
        with ThreadPoolExecutor(max_workers=len(worker_vms)) as executor:
            futures = {}
            for node, ip in worker_vms.items():
                future = executor.submit(join_worker, node, ip, join_command)
                futures[future] = node

            for future in as_completed(futures):
                node = futures[future]
                if not future.result():
                    print_warning(f"Failed to join {node}")
    else:
        print_warning("No worker nodes available")

    # Step 5: Verify cluster
    verify_cluster(available_vms["master"])

    print()
    print_status("✨ Kubernetes cluster deployment complete!", Colors.GREEN)
    print_status("To use kubectl locally, run: source ./setup_kubectl.sh")
    print()
    print_status("Deployed nodes:")
    for node, ip in available_vms.items():
        print_status(f"  {node}: {ip}")
    print_status("Network Plugin: Calico")
    print_status("Pod Network CIDR: 10.244.0.0/16")

if __name__ == "__main__":
    main()
