---
kind: course

title: "From Git to Production: Hands-on GitOps with Flux"
description: |
  A hands-on course that takes you from a bare Kubernetes cluster to a
  production-grade GitOps pipeline using Flux. Based on ControlPlane's D2
  Reference Architecture, covering bootstrap, Kustomization, Helm, multi-tenancy,
  OCI artifacts, the Flux MCP Server for AI-assisted GitOps, and production patterns.

categories:
  - kubernetes
  - ci-cd

tagz:
  - flux
  - gitops
  - mcp
  - multi-tenancy
  - ai

createdAt: 2026-04-23
updatedAt: 2026-04-23

cover: __static__/flux-cover.png
---

## Course Overview

**Duration:** ~90 minutes
**Level:** Intermediate (comfortable with kubectl, YAML, and basic Helm)
**Event:** Devoxx Greece 2026

### What You'll Build

Starting from a bare Kubernetes cluster, you'll progressively build a GitOps pipeline that mirrors
the [D2 Reference Architecture](https://fluxcd.control-plane.io/guides/d2-architecture-reference/)
used by ControlPlane for enterprise Flux deployments.

### Modules

| Module | Duration | Topics |
|--------|----------|--------|
| 1. Foundations | 32 min | GitOps concepts, hands-on Kustomize, hands-on Helm, Flux bootstrap |
| 2. Core GitOps Patterns | 24 min | Kustomization, Helm releases |
| 3. Enterprise Patterns | 22 min | Multi-tenancy, OCI artifacts, drift detection |
| 4. AI & Production | 20 min | Flux MCP Server, notifications, image automation, scaling |

### Prerequisites

- Basic Kubernetes knowledge (Pods, Deployments, Services, kubectl)
- Familiarity with YAML and Helm concepts
- No GitHub account required — a local Gitea server is pre-provisioned

---

## About the Author

**Alessandro Vozza** — Cloud Native architect, Golden Kubestronaut, Microsoft CSA,
KubeCon speaker, and founder of [Kubespaces.io](https://kubespaces.io).

- GitHub: [@ams0](https://github.com/ams0)
- Email: alessandro.vozza@linux.com

Source repo: [github.com/cloudpirates/flux-workshop](https://github.com/cloudpirates/flux-workshop)
