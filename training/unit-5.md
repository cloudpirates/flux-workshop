---
kind: unit
title: "Lab 4: Multi-Tenancy — The D2 Pattern"
name: lab4-multi-tenancy
---

# Lab 4: Multi-Tenancy — The D2 Pattern

**Duration:** 15 minutes
**Goal:** Separate platform and application concerns with RBAC isolation

## The D2 Separation of Concerns

In ControlPlane's D2 Reference Architecture, three repositories model three levels of privilege:

```
d2-fleet (cluster-admin)     → Bootstraps Flux, manages tenants
d2-infra (cluster-admin)     → Monitoring, ingress, cert-manager
d2-apps  (namespace-scoped)  → Application deployments per tenant
```

We'll implement this separation in a single repo using different directories and Kustomizations
with different service accounts.

## Step 1: Create the Tenant

Create the tenant namespace, service account, and RBAC:

Create `manifests/tenants/team-a/namespace.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: team-a
  labels:
    toolkit.fluxcd.io/tenant: team-a
```

Create `manifests/tenants/team-a/rbac.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: team-a
  namespace: team-a
  labels:
    toolkit.fluxcd.io/tenant: team-a
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: team-a-admin
  namespace: team-a
  labels:
    toolkit.fluxcd.io/tenant: team-a
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
  - kind: ServiceAccount
    name: team-a
    namespace: team-a
```

Create `manifests/tenants/team-a/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml
  - rbac.yaml
```

## Step 2: Create the Infrastructure Kustomization

This represents the platform team's infra layer (cluster-admin scope):

Add to `clusters/staging/infra.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: infra
  namespace: flux-system
spec:
  interval: 10m
  path: ./manifests/infra/base
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
```

## Step 3: Create the Tenant Onboarding Kustomization

Add to `clusters/staging/tenants.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: tenants
  namespace: flux-system
spec:
  interval: 5m
  path: ./manifests/tenants/team-a
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
```

## Step 4: Create the Tenant App Kustomization (with impersonation)

This is the key part — the app Kustomization runs as the tenant's service account:

Add to `clusters/staging/team-a-apps.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: team-a-apps
  namespace: flux-system
spec:
  dependsOn:
    - name: tenants
  interval: 5m
  path: ./manifests/apps/base
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  targetNamespace: team-a
  serviceAccountName: team-a
```

Notice:
- **`dependsOn: tenants`** — ensures the namespace and RBAC exist before deploying apps
- **`serviceAccountName: team-a`** — Flux impersonates this SA, limiting what it can do
- **`targetNamespace: team-a`** — all resources go into the tenant namespace

Commit and push:

```bash
git add -A
git commit -m "Add multi-tenancy: infra, tenants, team-a apps"
git push

flux reconcile source git flux-system
```

## Step 5: Verify the Isolation

```bash
# Check all Kustomizations
flux get kustomizations

# Verify tenant namespace exists
kubectl get ns team-a

# Check the podinfo deployment landed in team-a
kubectl get pods -n team-a

# Verify the service account
kubectl get sa -n team-a
```

Now test the RBAC boundary — the tenant SA cannot touch other namespaces:

```bash
# This should fail — team-a SA has no access to default namespace
kubectl auth can-i create deployments \
  --as=system:serviceaccount:team-a:team-a \
  -n default

# This should succeed — team-a SA is admin in its own namespace
kubectl auth can-i create deployments \
  --as=system:serviceaccount:team-a:team-a \
  -n team-a
```

## Step 6: See the D2 Pattern in Action

```bash
# Platform view — see all Kustomizations and their scopes
flux get kustomizations

# You should see:
# flux-system    → manages Flux itself (cluster-admin)
# infra          → manages monitoring stack (cluster-admin)
# tenants        → manages namespaces and RBAC (cluster-admin)
# team-a-apps    → manages team-a's apps (team-a SA, namespace-scoped)
```

This is exactly how D2 works at scale:
- The **platform team** controls `infra` and `tenants` (cluster-admin)
- Each **dev team** gets their own Kustomization running as their own SA
- Flux enforces the boundary — dev teams *cannot* escalate privileges

::remark-box
**Key Learning:** Platform team controls infra (cluster-admin). App teams control apps
(namespace-scoped). Flux enforces the boundary via RBAC impersonation.
This is the D2 fleet/infra/apps pattern in a single cluster.
::

## Checkpoint

If you fell behind:
```bash
kubectl apply -f checkpoints/lab4-complete.yaml
```
