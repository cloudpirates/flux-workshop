#!/bin/bash
# Catch-up script: ensures Gitea + Flux + repo are ready
# Run this at the start of any lab if you have a fresh playground
set -eu

# Check if already set up
if [ -d ~/workshop/flux-workshop ] && flux check 2>/dev/null | grep -q "all checks passed"; then
  echo "Environment already set up. Skipping."
  exit 0
fi

echo "=== Setting up workshop environment ==="

# Step 1: Flux CLI
if ! command -v flux &>/dev/null; then
  echo "Installing Flux CLI..."
  FLUX_VERSION=$(curl -sf https://api.github.com/repos/fluxcd/flux2/releases/latest | grep tag_name | cut -d'"' -f4)
  curl -sL "https://github.com/fluxcd/flux2/releases/download/${FLUX_VERSION}/flux_${FLUX_VERSION#v}_linux_amd64.tar.gz" | sudo tar xz -C /usr/local/bin
fi

# Step 2: Gitea
if ! kubectl get namespace gitea &>/dev/null; then
  echo "Installing Gitea..."
  helm repo add gitea-charts https://dl.gitea.com/charts/ 2>/dev/null
  helm repo update
  helm install gitea gitea-charts/gitea \
    --namespace gitea --create-namespace \
    --set gitea.admin.username=workshop \
    --set gitea.admin.password=workshop \
    --set service.http.type=NodePort \
    --set service.http.nodePort=30080 \
    --set persistence.size=1Gi \
    --set redis-cluster.enabled=false \
    --set postgresql-ha.enabled=false \
    --set postgresql.enabled=true \
    --set postgresql.global.postgresql.auth.password=gitea
  kubectl wait --for=condition=Ready -n gitea pod -l app.kubernetes.io/name=gitea --timeout=300s
fi

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
GITEA_URL="http://${NODE_IP}:30080"

# Wait for Gitea API
for i in $(seq 1 30); do
  curl -sf ${GITEA_URL}/api/v1/version >/dev/null 2>&1 && break
  sleep 2
done

# Step 3: Repo
if [ ! -d ~/workshop/flux-workshop ]; then
  echo "Creating workshop repo..."
  curl -sf -X POST ${GITEA_URL}/api/v1/user/repos \
    -H "Content-Type: application/json" \
    -u "workshop:workshop" \
    -d '{"name":"flux-workshop","default_branch":"main","auto_init":true}' > /dev/null 2>&1 || true

  git config --global user.email "workshop@devoxx.gr"
  git config --global user.name "Workshop Participant"
  git config --global credential.helper store
  echo "http://workshop:workshop@${NODE_IP}:30080" > ~/.git-credentials

  mkdir -p ~/workshop && cd ~/workshop
  git clone ${GITEA_URL}/workshop/flux-workshop.git
  cd flux-workshop
  mkdir -p clusters/staging apps/base apps/staging infra/base infra/staging tenants/base tenants/team-a
  git add . && git commit -m "Initial directory structure" --allow-empty && git push
fi

# Step 4: Flux
if ! flux check 2>/dev/null | grep -q "all checks passed"; then
  echo "Installing Flux..."
  flux install --components-extra=image-reflector-controller,image-automation-controller
  kubectl wait --for=condition=Ready -n flux-system pods --all --timeout=180s

  GITEA_CLUSTER_URL="http://gitea-http.gitea.svc.cluster.local:3000"

  kubectl create secret generic flux-system \
    --namespace=flux-system \
    --from-literal=username=workshop \
    --from-literal=password=workshop 2>/dev/null || true

  cat <<EOF | kubectl apply -f -
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 1m
  url: ${GITEA_CLUSTER_URL}/workshop/flux-workshop.git
  ref:
    branch: main
  secretRef:
    name: flux-system
EOF

  cat <<EOF | kubectl apply -f -
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./clusters/staging
  prune: true
EOF

  flux reconcile source git flux-system
fi

echo "=== Environment ready ==="
echo "Gitea: ${GITEA_URL}"
echo "Repo: ~/workshop/flux-workshop"
flux check
