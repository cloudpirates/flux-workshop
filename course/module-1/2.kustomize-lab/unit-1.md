---
kind: unit
title: "Lab 0: Hands-on Kustomize"
name: kustomize-hands-on
---

# Lab 0: Hands-on Kustomize

> **Duration:** 12 minutes
> **Goal:** Understand Kustomize — base/overlay pattern, patches, and generators — because
> this is exactly what Flux automates for you in the next labs.

## Why Kustomize First?

Flux's Kustomization controller runs `kustomize build` under the hood. If you understand
Kustomize, you understand half of Flux. So let's learn it standalone first.

Kustomize lets you:
- Define a **base** set of manifests (your app)
- Create **overlays** per environment (staging, production) without copying YAML
- Apply **patches** to change specific fields (replicas, images, resource limits)
- Generate ConfigMaps and Secrets from files

No templates. No Helm charts. Just plain Kubernetes YAML + a `kustomization.yaml` file.

## Step 1: Create a Base Application

```bash
mkdir -p ~/kustomize-demo/base
cd ~/kustomize-demo
```

Create the base deployment:

```bash
cat > base/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo
spec:
  replicas: 1
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
          image: ghcr.io/stefanprodan/podinfo:6.5.0
          ports:
            - containerPort: 9898
          resources:
            requests:
              cpu: 100m
              memory: 64Mi
EOF
```

Create a service:

```bash
cat > base/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: podinfo
spec:
  selector:
    app: podinfo
  ports:
    - port: 80
      targetPort: 9898
EOF
```

Create the kustomization file (tells Kustomize what resources to include):

```bash
cat > base/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
commonLabels:
  app.kubernetes.io/managed-by: kustomize
EOF
```

Preview what Kustomize generates:

```bash
kubectl kustomize base/
```

Notice how `commonLabels` was injected into every resource — deployments, services, selectors — without editing the originals.

Deploy the base:

```bash
kubectl apply -k base/
kubectl get pods
kubectl get svc podinfo
```

## Step 2: Create a Staging Overlay

Now create a staging environment that changes the replica count and adds a namespace:

```bash
mkdir -p overlays/staging
```

```bash
cat > overlays/staging/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: staging
resources:
  - ../../base
patches:
  - target:
      kind: Deployment
      name: podinfo
    patch: |
      - op: replace
        path: /spec/replicas
        value: 3
      - op: replace
        path: /spec/template/spec/containers/0/image
        value: ghcr.io/stefanprodan/podinfo:6.6.0
EOF
```

Preview the diff:

```bash
# See the base
kubectl kustomize base/
echo "---"
# See the staging overlay
kubectl kustomize overlays/staging/
```

Key differences:
- `namespace: staging` added to all resources
- `replicas: 1` → `replicas: 3`
- Image tag `6.5.0` → `6.6.0`
- **The base files are untouched**

Deploy staging:

```bash
kubectl create namespace staging
kubectl apply -k overlays/staging/
kubectl get pods -n staging
kubectl get deployment podinfo -n staging -o jsonpath='{.spec.replicas}'
echo " replicas"
```

## Step 3: Create a Production Overlay

```bash
mkdir -p overlays/production
```

```bash
cat > overlays/production/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: production
resources:
  - ../../base
patches:
  - target:
      kind: Deployment
      name: podinfo
    patch: |
      - op: replace
        path: /spec/replicas
        value: 5
      - op: add
        path: /spec/template/spec/containers/0/resources/limits
        value:
          cpu: 500m
          memory: 256Mi
namePrefix: prod-
EOF
```

```bash
kubectl create namespace production
kubectl apply -k overlays/production/
kubectl get deployment -n production
```

Notice `namePrefix: prod-` renamed the deployment to `prod-podinfo`. One base, three different deployments — no duplicated YAML.

## Step 4: ConfigMap Generators

Kustomize can generate ConfigMaps from files or literals:

```bash
echo "FEATURE_FLAG=true" > base/config.env
echo "LOG_LEVEL=debug" >> base/config.env
```

```bash
cat > base/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
commonLabels:
  app.kubernetes.io/managed-by: kustomize
configMapGenerator:
  - name: podinfo-config
    envs:
      - config.env
EOF
```

```bash
kubectl kustomize base/
```

Notice the ConfigMap name has a hash suffix (e.g., `podinfo-config-k89dm2`) — this is intentional.
When the config changes, the hash changes, triggering a rollout. **Immutable config by default.**

## The "Aha" Moment

You just did manually what Flux does automatically:
1. You ran `kubectl kustomize` → Flux's kustomize-controller does this
2. You ran `kubectl apply -k` → Flux applies the output to the cluster
3. You checked the result → Flux reports status on the Kustomization CR

The difference: **Flux watches your Git repo and runs this loop every few minutes automatically.**
When someone pushes a change to the overlay, Flux applies it. When someone manually edits the
cluster (drift), Flux corrects it.

That's what we'll set up in the next lab.

## Clean Up

```bash
kubectl delete -k base/
kubectl delete -k overlays/staging/
kubectl delete -k overlays/production/
kubectl delete namespace staging production
```

> **Next:** Bootstrap Flux and connect it to a Git repo so all of this happens automatically.
