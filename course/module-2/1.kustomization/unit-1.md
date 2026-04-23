---
kind: unit
title: "Lab 2: Deploy with GitRepository + Kustomization"
name: lab2-gitrepo-kustomization
---

# Lab 2: Deploy with GitRepository + Kustomization

**Duration:** 15 minutes
**Goal:** Deploy a sample application using Flux's core reconciliation loop

## What You'll Do

1. Add application manifests to your Git repo
2. Create a Flux Kustomization to deploy them
3. Make a change in Git and watch Flux apply it
4. Introduce manual drift and see Flux correct it

## Step 1: Add the Application Manifests

We'll deploy [podinfo](https://github.com/stefanprodan/podinfo), a tiny Go app built
specifically for Kubernetes demos.

```bash
cd ~/workshop/flux-workshop

# Create the apps directory structure (may already exist)
mkdir -p apps/base apps/staging
```

Create `apps/base/deployment.yaml`:

```bash
cat > apps/base/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: podinfo
  template:
    metadata:
      labels:
        app: podinfo
    spec:
      containers:
        - name: podinfo
          image: ghcr.io/stefanprodan/podinfo:6.7.0
          ports:
            - containerPort: 9898
              name: http
          resources:
            requests:
              cpu: 100m
              memory: 64Mi
          livenessProbe:
            httpGet:
              path: /healthz
              port: http
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
EOF
```

Create `apps/base/service.yaml`:

```bash
cat > apps/base/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: podinfo
spec:
  type: ClusterIP
  selector:
    app: podinfo
  ports:
    - name: http
      port: 9898
      targetPort: http
EOF
```

Create `apps/base/kustomization.yaml`:

```bash
cat > apps/base/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: apps
resources:
  - deployment.yaml
  - service.yaml
EOF
```

## Step 2: Tell Flux to Deploy These Manifests

Create the namespace and Flux Kustomization in your cluster config:

```bash
cat > clusters/staging/apps.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: apps
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps
  namespace: flux-system
spec:
  interval: 1m
  path: ./apps/base
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  targetNamespace: apps
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: podinfo
      namespace: apps
EOF
```

Commit and push:

```bash
git add -A
git commit -m "Add podinfo app with Flux Kustomization"
git push
```

## Step 3: Watch the Deployment

```bash
# Trigger immediate reconciliation (or wait ~1 min for the interval)
flux reconcile source git flux-system

# Watch the Kustomization status
flux get kustomizations -w
```

Press `Ctrl+C` once you see the `apps` Kustomization show `Ready True`.

```bash
# Check the pods
kubectl get pods -n apps

# Verify the service
kubectl port-forward -n apps svc/podinfo 9898:9898 &
curl http://localhost:9898
```

You should see podinfo running with 2 replicas and a JSON response from the API.

## Step 4: Update via Git

Change the replica count in Git:

```bash
# Edit the deployment — scale from 2 to 3
sed -i 's/replicas: 2/replicas: 3/' apps/base/deployment.yaml

git add -A
git commit -m "Scale podinfo to 3 replicas"
git push

# Trigger reconciliation
flux reconcile source git flux-system

# Watch pods scale up
kubectl get pods -n apps -w
```

No `kubectl scale`, no `kubectl apply`. Just Git push, Flux applies. Press `Ctrl+C` once you see 3 pods running.

## Step 5: Break It — Drift Detection

Now let's prove drift detection works:

```bash
# Manually scale down (bypassing GitOps)
kubectl scale deployment podinfo -n apps --replicas=1

# Verify — only 1 pod
kubectl get pods -n apps

# Wait for reconciliation (or trigger it)
flux reconcile kustomization apps

# Watch Flux restore to 3 replicas
kubectl get pods -n apps -w
```

Flux detects the drift between desired state (3 replicas in Git) and actual state (1 replica)
and corrects it automatically. Press `Ctrl+C` once restored.

::remark-box
**Key Learning:** The Git → Cluster reconciliation loop. Flux watches Git and converges the cluster.
Manual changes are ephemeral — Git always wins. This is the core of GitOps.
::

## Checkpoint

If you fell behind:
```bash
kubectl apply -f ~/workshop/checkpoints/lab2-complete.yaml
```

Kill any port-forward before moving on:
```bash
kill %1 2>/dev/null || true
```
