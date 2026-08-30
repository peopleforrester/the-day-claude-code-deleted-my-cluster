#!/bin/bash
# ABOUTME: Downloads and installs sshpass locally without sudo
# ABOUTME: Creates a local installation in the current directory

set -e

echo "Installing sshpass locally..."

# Create local directories
mkdir -p ./local/bin
mkdir -p ./local/src

# Download sshpass source
cd ./local/src
wget https://sourceforge.net/projects/sshpass/files/sshpass/1.10/sshpass-1.10.tar.gz
tar -xzf sshpass-1.10.tar.gz
cd sshpass-1.10

# Configure and compile
./configure --prefix=$(pwd)/../../
make
make install

cd ../../../

# Make it available
export PATH=$(pwd)/local/bin:$PATH

echo "sshpass installed locally at: $(pwd)/local/bin/sshpass"
echo "Run this to add to PATH: export PATH=$(pwd)/local/bin:\$PATH"
