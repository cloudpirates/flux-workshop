#!/usr/bin/env bash
# Workshop environment setup / verification script
# Run this if the playground init didn't complete properly
set -euo pipefail

echo "========================================="
echo "  Flux GitOps Workshop — Setup"
echo "========================================="

# Check Kubernetes
echo ""
echo "=== Checking Kubernetes cluster ==="
if kubectl get nodes -o wide 2>/dev/null; then
  echo "Cluster OK"
else
  echo "ERROR: Kubernetes cluster not ready. Wait a moment and retry."
  exit 1
fi

# Check/install Flux CLI
echo ""
echo "=== Checking Flux CLI ==="
if command -v flux &>/dev/null; then
  flux --version
else
  echo "Installing Flux CLI..."
  curl -s https://fluxcd.io/install.sh | sudo bash
fi

# Validate Flux prerequisites
echo ""
echo "=== Flux Prerequisites ==="
flux check --pre

# Check Helm
echo ""
echo "=== Checking Helm ==="
if command -v helm &>/dev/null; then
  helm version --short
else
  echo "Installing Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Check Gitea
echo ""
echo "=== Checking Gitea ==="
if curl -sf http://localhost:3000/api/v1/version >/dev/null 2>&1; then
  echo "Gitea OK: $(curl -sf http://localhost:3000/api/v1/version | python3 -c "import sys,json; print(json.load(sys.stdin)['version'])")"
else
  echo "WARNING: Gitea not available at localhost:3000"
  echo "You can use GitHub instead — export GITHUB_TOKEN and GITHUB_USER"
fi

# Check Git config
echo ""
echo "=== Git config ==="
git config --global user.email "${GIT_EMAIL:-workshop@devoxx.gr}"
git config --global user.name "${GIT_NAME:-Workshop Participant}"
echo "Git user: $(git config --global user.name) <$(git config --global user.email)>"

# Check workshop directory
echo ""
echo "=== Workshop directory ==="
if [ -d ~/workshop/flux-workshop/.git ]; then
  echo "Workshop repo exists at ~/workshop/flux-workshop"
  cd ~/workshop/flux-workshop
  git log --oneline -3
else
  echo "Cloning workshop repo..."
  mkdir -p ~/workshop
  cd ~/workshop
  git clone http://workshop:workshop@localhost:3000/workshop/flux-workshop.git 2>/dev/null || \
    echo "WARNING: Could not clone from Gitea. Clone manually or use GitHub."
fi

echo ""
echo "========================================="
echo "  Environment ready!"
echo ""
echo "  Flux:    $(flux --version 2>/dev/null || echo 'not installed')"
echo "  Helm:    $(helm version --short 2>/dev/null || echo 'not installed')"
echo "  Cluster: $(kubectl get nodes --no-headers 2>/dev/null | awk '{print $1, $2}' | head -1)"
echo ""
echo "  Workshop repo: ~/workshop/flux-workshop"
echo "  Gitea UI:      http://localhost:3000"
echo "  Login:         workshop / workshop"
echo "========================================="
