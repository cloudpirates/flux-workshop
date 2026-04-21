---
kind: unit
title: "Lab 7: Advanced Topics & Production Patterns"
name: lab7-advanced-topics
---

# Lab 7: Advanced Topics & Production Patterns

> **Duration:** 10 minutes
> **Goal:** Survey advanced Flux features you'll need in production — notifications, image automation, Flux Operator ResourceSets, and scaling patterns.

This is a fast-paced tour. Each topic includes working YAML you can apply in the playground
and take home for your own clusters.

---

## 1. Notifications — Flux Talks Back

The **notification-controller** handles both inbound events (GitHub webhooks triggering reconciliation)
and outbound alerts (Slack/Discord/Teams messages when things break).

### Set Up a Discord/Slack Alert

```yaml
# manifests/infra/notifications/provider.yaml
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Provider
metadata:
  name: slack-alerts
  namespace: flux-system
spec:
  type: slack
  channel: flux-alerts
  secretRef:
    name: slack-webhook-url
---
# manifests/infra/notifications/alert.yaml
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Alert
metadata:
  name: deployment-alerts
  namespace: flux-system
spec:
  providerRef:
    name: slack-alerts
  eventSeverity: error
  eventSources:
    - kind: HelmRelease
      name: '*'
    - kind: Kustomization
      name: '*'
```

### Set Up a GitHub Webhook Receiver

```yaml
# manifests/infra/notifications/receiver.yaml
apiVersion: notification.toolkit.fluxcd.io/v1
kind: Receiver
metadata:
  name: github-receiver
  namespace: flux-system
spec:
  type: github
  events:
    - "ping"
    - "push"
  secretRef:
    name: receiver-token
  resources:
    - kind: GitRepository
      name: flux-system
```

When GitHub sends a push webhook, Flux immediately reconciles instead of waiting for the poll interval.
This gives you **near-instant deployments** after `git push`.

```bash
# Apply and check the receiver URL
kubectl apply -f manifests/infra/notifications/
kubectl get receivers -n flux-system
# The receiver generates a webhook URL you register in GitHub
```

---

## 2. Image Automation — Auto-Update on New Container Images

The **image-reflector-controller** scans container registries, and the **image-automation-controller**
commits updated image tags back to Git. This is "closed-loop GitOps" — push a new image, Flux
updates the repo and deploys it.

### Scan a Registry

```yaml
# manifests/infra/image-automation/image-repository.yaml
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: podinfo
  namespace: flux-system
spec:
  image: ghcr.io/stefanprodan/podinfo
  interval: 5m
---
# manifests/infra/image-automation/image-policy.yaml
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImagePolicy
metadata:
  name: podinfo
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: podinfo
  policy:
    semver:
      range: ">=6.0.0"
```

### Auto-Commit Updated Tags

```yaml
# manifests/infra/image-automation/image-update.yaml
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageUpdateAutomation
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 30m
  sourceRef:
    kind: GitRepository
    name: flux-system
  git:
    checkout:
      ref:
        branch: main
    commit:
      author:
        email: fluxbot@users.noreply.github.com
        name: fluxbot
      messageTemplate: |
        Automated image update
        
        {{range .Changed.Changes}}
        - {{.OldValue}} -> {{.NewValue}}
        {{end}}
    push:
      branch: main
  update:
    path: ./manifests/apps
    strategy: Setters
```

In your deployment YAML, mark which images to auto-update:

```yaml
# In manifests/apps/podinfo/deployment.yaml
spec:
  containers:
    - name: podinfo
      image: ghcr.io/stefanprodan/podinfo:6.5.0 # {"$imagepolicy": "flux-system:podinfo"}
```

```bash
# Apply and watch the image reflector find new tags
kubectl apply -f manifests/infra/image-automation/
flux get image repository podinfo
flux get image policy podinfo
```

---

## 3. Flux Operator & ResourceSets — Fleet Management at Scale

The **Flux Operator** (by ControlPlane) extends Flux with higher-level abstractions:

### FluxInstance — Declarative Flux Lifecycle

```yaml
apiVersion: fluxcd.controlplane.io/v1
kind: FluxInstance
metadata:
  name: flux
  namespace: flux-system
spec:
  distribution:
    version: "2.x"
    registry: ghcr.io/fluxcd
  components:
    - source-controller
    - kustomize-controller
    - helm-controller
    - notification-controller
  cluster:
    type: kubernetes
    multitenant: true
```

### ResourceSet — Templatized Multi-Tenancy

Instead of copy-pasting tenant configs (Lab 4), ResourceSets template them:

```yaml
apiVersion: fluxcd.controlplane.io/v1
kind: ResourceSet
metadata:
  name: tenants
  namespace: flux-system
spec:
  resources:
    - apiVersion: v1
      kind: Namespace
      metadata:
        name: "{{ .name }}"
    - apiVersion: kustomize.toolkit.fluxcd.io/v1
      kind: Kustomization
      metadata:
        name: "{{ .name }}"
        namespace: flux-system
      spec:
        interval: 10m
        sourceRef:
          kind: GitRepository
          name: flux-system
        path: "./manifests/tenants/{{ .name }}"
        prune: true
        serviceAccountName: "{{ .name }}-reconciler"
  inputs:
    - name: frontend
    - name: backend
    - name: data-team
```

One ResourceSet, N tenants. Add a team by adding one line to `inputs`.

---

## 4. Scaling Patterns — What Changes at 50+ Clusters

Quick reference for production scaling:

| Pattern | When | How |
|---|---|---|
| **Sharding** | >500 resources per cluster | `--watch-label-selector` on controllers |
| **Vertical scaling** | Memory pressure on source-controller | Increase memory limits, tune `--concurrent` |
| **Multi-cluster** | Central fleet management | Flux Operator + ResourceSets per cluster |
| **Rate limiting** | GitHub API rate limits | Use OCI sources (Lab 5), reduce poll intervals |
| **Monitoring** | Always | Prometheus metrics at `:8080/metrics`, Grafana dashboards in `fluxcd/flux2-monitoring-example` |

### Prometheus Metrics Quick Setup

```bash
# Flux exposes metrics on all controllers
kubectl port-forward -n flux-system svc/source-controller 8080:8080 &
curl -s http://localhost:8080/metrics | grep gotk_reconcile
```

Key metrics:
- `gotk_reconcile_duration_seconds` — how long reconciliations take
- `gotk_reconcile_condition` — current status of all Flux resources
- `gotk_suspend_status` — which resources are suspended

---

## 5. Where to Go Next

| Resource | Link |
|---|---|
| D2 Reference Architecture | <https://fluxcd.control-plane.io/guides/d2-architecture-reference/> |
| Flux Operator & MCP Server | <https://github.com/controlplaneio-fluxcd/flux-operator> |
| Flux Monitoring Example | <https://github.com/fluxcd/flux2-monitoring-example> |
| Image Automation Guide | <https://fluxcd.io/flux/guides/image-update/> |
| Flux Security Best Practices | <https://fluxcd.io/flux/security/> |
| Linux Foundation GitOps Course (LFS269) | <https://training.linuxfoundation.org/training/gitops-continuous-delivery-on-kubernetes-with-flux-lfs269/> |

---

## Workshop Complete! 🎉

You've gone from zero to a production-grade GitOps pipeline in 90 minutes:

1. ✅ **Bootstrapped Flux** — the self-managing GitOps loop
2. ✅ **Deployed from Git** — GitRepository + Kustomization
3. ✅ **Managed Helm declaratively** — HelmRelease
4. ✅ **Implemented multi-tenancy** — RBAC-isolated team namespaces
5. ✅ **Used OCI artifacts** — container registry as source of truth
6. ✅ **Connected AI to your cluster** — Flux MCP Server for conversational GitOps
7. ✅ **Explored production patterns** — notifications, image automation, fleet management

The D2 Reference Architecture and the Flux Operator are actively maintained by ControlPlane.
Everything you built today maps directly to production deployments.

**Questions?** Find Alessandro at [@ams0](https://github.com/ams0) or the Flux community on [CNCF Slack](https://slack.cncf.io/) in `#flux`.
