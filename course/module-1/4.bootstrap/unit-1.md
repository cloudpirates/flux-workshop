---
kind: unit
title: "Lab 1: Bootstrap Flux"
name: lab1-bootstrap-flux
---

# Lab 1: Bootstrap Flux

> **Duration:** 15 minutes
> **Goal:** Set up a Git server, install Flux, and see the self-managing GitOps loop in action.

## Step 1: Install Flux CLI

```bash
FLUX_VERSION=$(curl -sf https://api.github.com/repos/fluxcd/flux2/releases/latest | grep tag_name | cut -d'"' -f4)
curl -sL "https://github.com/fluxcd/flux2/releases/download/${FLUX_VERSION}/flux_${FLUX_VERSION#v}_linux_amd64.tar.gz" | sudo tar xz -C /usr/local/bin
flux --version
```

Check prerequisites:

```bash
flux check --pre
```

## Step 2: Install Gitea (In-Cluster Git Server)

We use Gitea so you don't need a GitHub account. It runs inside the cluster:

```bash
helm repo add gitea-charts https://dl.gitea.com/charts/
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
```

Wait for Gitea to be ready:

```bash
kubectl wait --for=condition=Ready -n gitea pod -l app.kubernetes.io/name=gitea --timeout=300s
```

Find the Gitea URL (on a cluster node's IP):

```bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
GITEA_URL="http://${NODE_IP}:30080"
echo "Gitea is at: ${GITEA_URL}"

# Verify
curl -sf ${GITEA_URL}/api/v1/version
```

## Step 3: Create the Workshop Repository

```bash
# Create repo via API
curl -sf -X POST ${GITEA_URL}/api/v1/user/repos \
  -H "Content-Type: application/json" \
  -u "workshop:workshop" \
  -d '{"name":"flux-workshop","default_branch":"main","auto_init":true}'

# Configure git credentials
git config --global user.email "workshop@devoxx.gr"
git config --global user.name "Workshop Participant"
git config --global credential.helper store
echo "http://workshop:workshop@${NODE_IP}:30080" > ~/.git-credentials

# Clone and set up directory structure
mkdir -p ~/workshop && cd ~/workshop
git clone ${GITEA_URL}/workshop/flux-workshop.git
cd flux-workshop
mkdir -p clusters/staging apps/base apps/staging infra/base infra/staging tenants/base tenants/team-a
git add . && git commit -m "Initial directory structure" --allow-empty && git push
```

## Step 4: Install Flux Controllers

```bash
flux install --components-extra=image-reflector-controller,image-automation-controller
```

Wait for all controllers to be ready:

```bash
kubectl wait --for=condition=Ready -n flux-system pods --all --timeout=180s
flux check
```

You should see 6 controllers running:
- **source-controller** — fetches from Git, Helm repos, OCI registries
- **kustomize-controller** — applies Kustomize overlays
- **helm-controller** — manages Helm releases
- **notification-controller** — alerts and webhooks
- **image-reflector-controller** — scans container registries
- **image-automation-controller** — auto-commits image updates

## Step 5: Connect Flux to Gitea

The source-controller runs inside the cluster, so it needs the **in-cluster** URL for Gitea:

```bash
GITEA_CLUSTER_URL="http://gitea-http.gitea.svc.cluster.local:3000"

# Create a secret with Gitea credentials
kubectl create secret generic flux-system \
  --namespace=flux-system \
  --from-literal=username=workshop \
  --from-literal=password=workshop
```

Create the GitRepository source:

```bash
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
```

Create the root Kustomization (tells Flux where to look for manifests):

```bash
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
```

Verify the connection:

```bash
flux reconcile source git flux-system
flux get sources git
flux get kustomizations
```

The GitRepository should show `Ready: True` with a fetched revision.
The Kustomization will show `Ready: False` with "path not found" — that's normal! The
`clusters/staging/` directory is empty. It will become Ready in Lab 2 when we add our first manifests.

## Step 6: Understanding the GitOps Loop

Flux is now watching your Git repo and applying whatever it finds at `clusters/staging/`.
Right now that path is empty, so Flux has nothing to do.

In the next lab, you'll add a Kustomization file to that path, push to Git, and watch
Flux automatically deploy it. That's the GitOps loop:

```
  You push to Git
       ↓
  source-controller detects the change
       ↓
  kustomize-controller applies the manifests
       ↓
  Your app is running
```

No `kubectl apply`. No CI/CD pipeline pushing to the cluster. Just Git.

## Checkpoint

Verify everything is working:

```bash
flux check
flux get sources git
flux get kustomizations
ls ~/workshop/flux-workshop/clusters/staging/
```

You should have:
- ✅ All Flux controllers running
- ✅ GitRepository `flux-system` → Ready
- ✅ Kustomization `flux-system` → `Ready: False` (expected — `clusters/staging/` is empty until Lab 2)
- ✅ A cloned repo at `~/workshop/flux-workshop`

> **Next:** Deploy an application through the GitOps pipeline.
