---
kind: unit
title: "Lab 3: Helm Releases with HelmRelease"
name: lab3-helm-releases
---

# Lab 3: Helm Releases with HelmRelease

**Duration:** 15 minutes
**Goal:** Manage a Helm chart entirely through GitOps — no more `helm install` or `helm upgrade`

## What You'll Do

1. Create a HelmRepository source pointing to a Helm chart repo
2. Deploy podinfo via HelmRelease with custom values
3. Update values through Git and see the upgrade happen automatically
4. See what happens when someone runs `helm upgrade` manually

## Step 1: Create the HelmRelease

Create a single file that defines the namespace, HelmRepository, and HelmRelease:

```bash
cd ~/workshop/flux-workshop

cat > clusters/staging/helm-demo.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: helm-demo
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: podinfo
  namespace: helm-demo
spec:
  interval: 1h
  url: https://stefanprodan.github.io/podinfo
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: podinfo
  namespace: helm-demo
spec:
  interval: 5m
  chart:
    spec:
      chart: podinfo
      version: "6.7.x"
      sourceRef:
        kind: HelmRepository
        name: podinfo
      interval: 5m
  values:
    replicaCount: 2
    ui:
      color: "#1a73e8"
      message: "Hello from Flux HelmRelease!"
    resources:
      requests:
        cpu: 100m
        memory: 64Mi
EOF
```

Notice the version `"6.7.x"` — this semver range means Flux will automatically pick up
patch releases (6.7.1, 6.7.2, etc.) while staying on 6.7.

Commit and push:

```bash
git add clusters/staging/helm-demo.yaml
git commit -m "Add podinfo HelmRelease"
git push

# Trigger reconciliation
flux reconcile source git flux-system
```

## Step 2: Watch the Install

```bash
# Watch Flux install the Helm release
flux get helmreleases -n helm-demo -w
```

Press `Ctrl+C` once you see `Ready True`.

```bash
# Check pods
kubectl get pods -n helm-demo

# Check the Helm release (Flux uses Helm SDK under the hood)
helm list -n helm-demo

# Verify the custom values
kubectl port-forward -n helm-demo svc/podinfo 8080:9898 &
curl http://localhost:8080
```

Notice the custom UI color and message from our values in the JSON response.

## Step 3: Update Values via Git

Let's change the UI color and scale up:

```bash
# Edit the HelmRelease values directly
sed -i 's/replicaCount: 2/replicaCount: 3/' clusters/staging/helm-demo.yaml
sed -i 's/#1a73e8/#e8341a/' clusters/staging/helm-demo.yaml
sed -i 's/Hello from Flux HelmRelease!/Updated via GitOps!/' clusters/staging/helm-demo.yaml

git add -A
git commit -m "Update podinfo: red theme, scale to 3"
git push

flux reconcile source git flux-system

# Watch the upgrade happen
flux get helmreleases -n helm-demo -w
```

Press `Ctrl+C` once upgraded. Verify:

```bash
curl http://localhost:8080
kubectl get pods -n helm-demo
```

No `helm upgrade`. Just Git push.

## Step 4: Break It — Manual Helm Upgrade

What happens when someone bypasses GitOps?

```bash
# Manual Helm upgrade (the "wrong" way)
helm upgrade podinfo podinfo/podinfo -n helm-demo \
  --set replicaCount=1 \
  --set ui.message="I bypassed GitOps!" 2>/dev/null || \
helm upgrade podinfo oci://ghcr.io/stefanprodan/charts/podinfo -n helm-demo \
  --set replicaCount=1 \
  --set ui.message="I bypassed GitOps!"

# Check — it worked temporarily
kubectl get pods -n helm-demo
```

Now wait for Flux to notice (or trigger it):

```bash
# Force Flux to reconcile
flux reconcile helmrelease podinfo -n helm-demo

# Check again — Flux reverted to Git state
kubectl get pods -n helm-demo
curl http://localhost:8080
```

The message is back to "Updated via GitOps!" and replicas are back to 3.
Flux's helm-controller detected the drift and performed an upgrade back to the values in Git.

## Step 5: Explore Helm Release Details

```bash
# Full status of all Flux-managed Helm releases
flux get helmreleases -A

# See all Flux-managed resources in the namespace
flux get all -n helm-demo

# Check the resolved Helm values
kubectl get helmrelease podinfo -n helm-demo -o jsonpath='{.spec.values}' | python3 -m json.tool
```

::remark-box
**Key Learning:** No more `helm install/upgrade` from CI pipelines or terminals. Declare the chart,
version, and values in Git. Flux handles the lifecycle. Manual `helm upgrade` gets reverted.
In the D2 architecture, all infrastructure add-ons (monitoring, ingress, cert-manager)
are managed this way.
::

## Checkpoint

If you fell behind:
```bash
kubectl apply -f ~/workshop/checkpoints/lab3-complete.yaml
```

Kill port-forward:
```bash
kill %1 2>/dev/null || true
```
