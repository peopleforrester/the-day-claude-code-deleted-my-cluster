#!/usr/bin/env python3
# ABOUTME: Python script to deploy Kubernetes cluster using paramiko for SSH
# ABOUTME: No additional system packages required, uses pure Python

import paramiko
import time
import sys
import os
from datetime import datetime
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed

# VM configuration
VMS = {
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

def print_progress(current, total, message=""):
    percentage = (current * 100) // total
    bar_length = 40
    filled = (bar_length * current) // total
    bar = '█' * filled + '░' * (bar_length - filled)
    sys.stdout.write(f'\r[{bar}] {percentage}% - {message}')
    sys.stdout.flush()
    if current == total:
        print()

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

def test_connectivity():
    """Test SSH connectivity to all nodes"""
    print_status("Testing SSH connectivity to all nodes...")

    for node, ip in VMS.items():
        try:
            output, _ = execute_ssh_command(ip, "echo 'Connected successfully'", get_output=True)
            if "Connected successfully" in output:
                print_status(f"✓ Connected to {node} ({ip})")
            else:
                print_error(f"Failed to connect to {node} ({ip})")
                return False
        except:
            print_error(f"Failed to connect to {node} ({ip})")
            return False

    return True

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

def initialize_master():
    """Initialize Kubernetes master node"""
    master_ip = VMS["master"]
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

def verify_cluster():
    """Verify cluster status"""
    master_ip = VMS["master"]
    print_status("Verifying cluster status...")

    # Wait for nodes to be ready
    print_status("Waiting for all nodes to be ready...")
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
    print_status(f"Deploying to {len(VMS)} nodes")

    total_steps = 10
    current_step = 0

    # Step 1: Test connectivity
    print_progress(current_step, total_steps, "Testing connectivity")
    if not test_connectivity():
        print_error("Connectivity test failed")
        sys.exit(1)
    current_step += 1

    # Steps 2-6: Install prerequisites on all nodes in parallel
    print_progress(current_step, total_steps, "Installing prerequisites")
    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = {}
        for node, ip in VMS.items():
            future = executor.submit(install_prerequisites_on_node, node, ip)
            futures[future] = node

        for future in as_completed(futures):
            node = futures[future]
            if not future.result():
                print_error(f"Failed to install prerequisites on {node}")
                sys.exit(1)
            current_step += 1
            print_progress(current_step, total_steps, f"Installed on {node}")

    # Step 7: Initialize master
    print_progress(current_step, total_steps, "Initializing master")
    success, join_command = initialize_master()
    if not success:
        print_error("Master initialization failed")
        sys.exit(1)
    current_step += 1

    # Step 8-9: Join workers
    print_progress(current_step, total_steps, "Joining workers")
    worker_nodes = [(k, v) for k, v in VMS.items() if k != "master"]

    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = {}
        for node, ip in worker_nodes:
            future = executor.submit(join_worker, node, ip, join_command)
            futures[future] = node

        for future in as_completed(futures):
            node = futures[future]
            if not future.result():
                print_warning(f"Failed to join {node}")

    current_step += 2

    # Step 10: Verify cluster
    print_progress(current_step, total_steps, "Verifying cluster")
    verify_cluster()

    print()
    print_status("✨ Kubernetes cluster deployment complete!", Colors.GREEN)
    print_status("To use kubectl locally, run: source ./setup_kubectl.sh")
    print()
    print_status("Cluster summary:")
    print_status(f"  Master: {VMS['master']}")
    print_status(f"  Workers: {', '.join([VMS[w] for w in VMS if w != 'master'])}")
    print_status("  Network Plugin: Calico")
    print_status("  Pod Network CIDR: 10.244.0.0/16")

if __name__ == "__main__":
    try:
        # Check if paramiko is installed
        import paramiko
    except ImportError:
        print_error("paramiko is required. Installing...")
        os.system("pip install paramiko")
        import paramiko

    main()
