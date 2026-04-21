---
kind: training

title: "From Git to Production: Hands-on GitOps with Flux"

description: |
  A 90-minute hands-on workshop that takes you from a bare Kubernetes cluster to a
  production-grade GitOps pipeline using Flux. Based on ControlPlane's D2 Reference
  Architecture, you'll bootstrap Flux, deploy apps with GitRepository and Kustomization,
  manage Helm releases declaratively, implement multi-tenancy with RBAC isolation, and
  use OCI artifacts with drift detection. Each lab builds on the previous one.

categories:
  - kubernetes
  - gitops

tags:
  - flux
  - gitops
  - helm
  - multi-tenancy
  - oci
  - d2-architecture

createdAt: 2026-04-21
updatedAt: 2026-04-21
---

## Workshop Overview

**Duration:** 90 minutes
**Level:** Intermediate (you should be comfortable with kubectl, YAML, and basic Helm)
**Event:** Devoxx Greece 2026

### What You'll Build

Starting from a bare Kubernetes cluster, you'll progressively build a GitOps pipeline that mirrors
the [D2 Reference Architecture](https://fluxcd.control-plane.io/guides/d2-architecture-reference/)
used by ControlPlane for enterprise Flux deployments:

1. **Bootstrap Flux** — install Flux and understand the self-managing GitOps loop
2. **Deploy an app** — use GitRepository + Kustomization to deploy from Git
3. **Manage Helm charts** — declare HelmReleases instead of running `helm install`
4. **Multi-tenancy** — separate platform and app team concerns with RBAC
5. **OCI artifacts** — the "gitless GitOps" production pattern with drift correction

### Prerequisites

- Basic Kubernetes knowledge (Pods, Deployments, Services, kubectl)
- Familiarity with YAML and Helm concepts
- No GitHub account required — a local Gitea server is pre-provisioned in the playground

### Agenda

| Unit | Duration | Topic |
|------|----------|-------|
| unit-1 | 10 min | Introduction: GitOps and Flux |
| unit-2 | 15 min | Lab 1: Bootstrap Flux |
| unit-3 | 15 min | Lab 2: Deploy with GitRepository + Kustomization |
| unit-4 | 15 min | Lab 3: Helm Releases with HelmRelease |
| unit-5 | 15 min | Lab 4: Multi-Tenancy — The D2 Pattern |
| unit-6 | 10 min | Lab 5: OCI Artifacts and Drift Detection |
| wrap-up | 10 min | Q&A + where to go next (baked into unit-6) |
