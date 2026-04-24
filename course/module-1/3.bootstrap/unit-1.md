---
kind: unit
title: "Lab 1: Bootstrap Flux"
name: lab1-bootstrap-flux
---

# Lab 1: Bootstrap Flux

**Duration:** 15 minutes
**Goal:** Install Flux on your cluster and understand the self-managing GitOps loop

## What You'll Do

1. Bootstrap Flux using the `flux` CLI with your local Gitea repo
2. Inspect what Flux installed — pods, CRDs, the self-managing loop
3. See Flux manage *itself* through GitOps
4. Break something and watch Flux heal it

## Step 1: Bootstrap Flux

The `flux bootstrap` command does three things:
1. Installs Flux controllers in the cluster
2. Configures a Git repository as the source of truth
3. Commits Flux's own manifests to the repo — making Flux manage itself

We'll use `flux bootstrap git` with our local Gitea server:

```bash
cd ~/workshop/flux-workshop

flux bootstrap git \
  --url=http://localhost:3000/workshop/flux-workshop.git \
  --branch=main \
  --path=clusters/staging \
  --username=workshop \
  --password=workshop \
  --token-auth=true
```

Watch the bootstrap process. It takes about 60 seconds.

::remark-box
**Using GitHub instead?** If you prefer to use your own GitHub repo:
```bash
export GITHUB_TOKEN=<your-token>
export GITHUB_USER=<your-username>
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=flux-workshop \
  --branch=main \
  --path=clusters/staging \
  --personal
```
::

## Step 2: Inspect What Was Created

### In the cluster

```bash
# See all Flux components
kubectl get pods -n flux-system

# Check the CRDs Flux installed
kubectl get crd | grep flux

# See the self-managing GitRepository and Kustomization
flux get sources git
flux get kustomizations
```

You should see:
- **source-controller** — watches your Git repo
- **kustomize-controller** — applies manifests from the repo
- **helm-controller** — manages Helm releases (we'll use this in Lab 3)
- **notification-controller** — handles alerts and webhooks

### In your Git repo

Check what Flux committed to Gitea:

```bash
# Pull the changes Flux made
git pull

# See the structure
find clusters/staging -type f
```

Flux created a `flux-system/` directory under your path with:
- `gotk-components.yaml` — all Flux controller definitions (~30,000 lines of YAML)
- `gotk-sync.yaml` — the GitRepository + Kustomization that keeps Flux in sync
- `kustomization.yaml` — Kustomize entry point

You can also browse this in the **Gitea** tab — navigate to the `clusters/staging/flux-system/` directory.

**This is the GitOps loop**: Flux reads its own definition from Git and reconciles it.

## Step 3: See the Self-Healing

Let's prove Flux manages itself. Delete the source-controller and watch what happens:

```bash
# Delete a Flux component
kubectl delete deployment source-controller -n flux-system

# Watch it come back (takes 30-60 seconds)
kubectl get pods -n flux-system -w
```

The kustomize-controller notices the desired state (from Git) doesn't match the actual state
(missing deployment) and recreates it. That's GitOps in action.

Press `Ctrl+C` to stop watching once the pod is back.

## Step 4: Check Overall Flux Health

```bash
# Overall health check
flux check

# Detailed status of all resources
flux get all

# See Flux logs
flux logs --all-namespaces --since=5m
```

::remark-box
**Key Learning:** Flux manages itself through GitOps. The bootstrap creates a self-referencing
loop where Flux watches its own configuration in Git. Delete something, and it comes back.
This is the foundation everything else builds on.
::

## Checkpoint

If you got stuck, the bootstrap is hard to skip — you really need a working `flux bootstrap`.
Ask for help if the bootstrap failed.

If the cluster has Flux running but your Git repo is out of sync:
```bash
git pull  # Fetch what Flux committed
```

Next: let's deploy an actual application.
