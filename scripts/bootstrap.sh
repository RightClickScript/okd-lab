#!/bin/bash
# scripts/bootstrap.sh - The "Local Spark" for Morpheus Enterprise Datacenter
# Purpose: Prepare the Container Host Laptop with an isolated Ansible environment.

set -e # Exit on error

# Configuration
VENV_DIR=".venv"
REQUIRED_PACKAGES=("git" "python3" "python3-venv" "python3-pip")

echo "--- Phase 1: Local Spark Bootstrap ---"

# 1. Update package cache
echo "[1/5] Updating package cache..."
sudo apt-get update -qq

# 2. Install core system dependencies
echo "[2/5] Installing core dependencies: ${REQUIRED_PACKAGES[*]}..."
sudo apt-get install -y -qq "${REQUIRED_PACKAGES[@]}"

# 3. Create Python Virtual Environment
echo "[3/5] Creating isolated Python environment in $VENV_DIR..."
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi

# 4. Install Ansible inside the Virtual Environment
echo "[4/5] Installing Ansible and core collections..."
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install "ansible-core>=2.15.0" kubernetes PyYAML pywinrm requests passlib


# 5. Install required Ansible collections
echo "[5/5] Installing Ansible collections..."
ansible-galaxy collection install -r requirements.yml

echo "---------------------------------------"
echo "Bootstrap Complete!"
echo "To begin, activate the environment with:"
echo "  source $VENV_DIR/bin/activate"
echo "---------------------------------------"
