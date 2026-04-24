---
kind: unit
title: "Lab 0b: Hands-on Helm"
name: helm-hands-on
---

# Lab 0b: Hands-on Helm

> **Duration:** 12 minutes
> **Goal:** Understand Helm — charts, values, releases, upgrades, and rollbacks — because
> Flux's HelmRelease CR automates exactly this workflow.

## Why Helm Before Flux?

Flux's helm-controller runs `helm install` and `helm upgrade` under the hood, driven by
a `HelmRelease` custom resource. If you know Helm, you'll immediately understand what
Flux is doing when it reconciles a HelmRelease.

Helm gives you:
- **Charts** — packaged applications (templates + default values)
- **Values** — per-environment customization without editing templates
- **Releases** — versioned, named deployments you can upgrade and roll back
- **Repositories** — registries of charts (like npm/Docker Hub for K8s apps)

## Step 1: Add a Helm Repository

```bash
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo update
```

Search for available charts:

```bash
helm search repo podinfo
```

Inspect the chart's default values (this is what you'll override):

```bash
helm show values podinfo/podinfo | head -40
```

## Step 2: Install a Chart

```bash
kubectl create namespace helm-demo

helm install podinfo podinfo/podinfo \
  --namespace helm-demo \
  --set replicaCount=1 \
  --set ui.message="Hello from Helm!"
```

Check what Helm created:

```bash
# The release
helm list -n helm-demo

# The actual Kubernetes resources
kubectl get all -n helm-demo

# The app is running
kubectl port-forward -n helm-demo svc/podinfo 9898:9898 &
sleep 2
curl -s http://localhost:9898 | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['message'])"
kill %1 2>/dev/null
```

## Step 3: Upgrade with New Values

Change the replica count and message:

```bash
helm upgrade podinfo podinfo/podinfo \
  --namespace helm-demo \
  --set replicaCount=3 \
  --set ui.message="Upgraded via Helm!" \
  --set ui.color="#2196F3"
```

Verify:

```bash
helm list -n helm-demo
kubectl get pods -n helm-demo
kubectl get deployment podinfo -n helm-demo -o jsonpath='{.spec.replicas}'
echo " replicas"
```

Check the revision history:

```bash
helm history podinfo -n helm-demo
```

## Step 4: Rollback

Oops, wrong color. Roll back to revision 1:

```bash
helm rollback podinfo 1 -n helm-demo
helm history podinfo -n helm-demo
```

The replicas went back to 1 and the message is "Hello from Helm!" again. Helm tracks state.

## Step 5: Values Files (the Production Way)

In practice, you don't pass `--set` flags. You use values files:

```bash
cat > ~/values-staging.yaml << 'EOF'
replicaCount: 2
ui:
  message: "Staging environment"
  color: "#FF9800"
resources:
  requests:
    cpu: 100m
    memory: 64Mi
EOF

cat > ~/values-production.yaml << 'EOF'
replicaCount: 5
ui:
  message: "Production"
  color: "#4CAF50"
resources:
  requests:
    cpu: 500m
    memory: 256Mi
  limits:
    cpu: "1"
    memory: 512Mi
EOF
```

```bash
helm upgrade podinfo podinfo/podinfo \
  --namespace helm-demo \
  -f ~/values-staging.yaml

kubectl get deployment podinfo -n helm-demo -o jsonpath='{.spec.replicas}'
echo " replicas (staging)"
```

These values files are what you'll put in Git and reference from Flux's HelmRelease.

## Step 6: What Helm Doesn't Do

Try this:

```bash
# Manually scale down
kubectl scale deployment podinfo -n helm-demo --replicas=0
kubectl get pods -n helm-demo
```

Nothing happened — Helm doesn't watch the cluster. It's a one-shot tool.
The drift stays until you manually run `helm upgrade` again.

```bash
# Fix it manually
helm upgrade podinfo podinfo/podinfo -n helm-demo -f ~/values-staging.yaml
kubectl get pods -n helm-demo
```

**This is the gap Flux fills.** Flux's helm-controller:
1. Watches the HelmRelease CR for changes
2. Runs `helm upgrade` automatically on every reconciliation
3. Detects and corrects drift
4. Reads values from Git (ConfigMaps, Secrets, or inline)

## Clean Up

```bash
helm uninstall podinfo -n helm-demo
kubectl delete namespace helm-demo
```

> **Next:** Bootstrap Flux so both Kustomize and Helm workflows happen automatically via GitOps.
