---
kind: training

title: "From Git to Production: Hands-on GitOps with Flux"

description: |
  A 90-minute hands-on workshop that takes you from a bare Kubernetes cluster to a
  production-grade GitOps pipeline using Flux. Based on ControlPlane's D2 Reference
  Architecture, you'll bootstrap Flux, deploy apps with GitRepository and Kustomization,
  manage Helm releases declaratively, implement multi-tenancy with RBAC isolation,
  use OCI artifacts with drift detection, connect AI assistants to your cluster via
  the Flux MCP Server, and explore production patterns like notifications, image
  automation, and fleet management. Each lab builds on the previous one.

categories:
  - kubernetes
  - ci-cd

tagz:
  - flux
  - gitops
  - mcp
  - multi-tenancy
  - ai

createdAt: 2026-04-21
updatedAt: 2026-04-21

cover: __static__/flux-cover.png
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
6. **AI-Assisted GitOps** — connect the Flux MCP Server to talk to your cluster
7. **Production patterns** — notifications, image automation, fleet management at scale

### Prerequisites

- Basic Kubernetes knowledge (Pods, Deployments, Services, kubectl)
- Familiarity with YAML and Helm concepts
- No GitHub account required — a local Gitea server is pre-provisioned in the playground

### Agenda

| Unit | Duration | Topic |
|------|----------|-------|
| unit-1 | 5 min | Introduction: GitOps and Flux |
| unit-2 | 12 min | Lab 1: Bootstrap Flux |
| unit-3 | 12 min | Lab 2: Deploy with GitRepository + Kustomization |
| unit-4 | 12 min | Lab 3: Helm Releases with HelmRelease |
| unit-5 | 12 min | Lab 4: Multi-Tenancy — The D2 Pattern |
| unit-6 | 10 min | Lab 5: OCI Artifacts and Drift Detection |
| unit-7 | 10 min | Lab 6: AI-Assisted GitOps with Flux MCP Server |
| unit-8 | 10 min | Lab 7: Advanced Topics & Production Patterns |
| wrap-up | 7 min | Q&A (baked into unit-8) |

---

## About the Author

**Alessandro Vozza** — Cloud Native architect, Golden Kubestronaut, Microsoft CSA,
KubeCon speaker, and founder of [Kubespaces.io](https://kubespaces.io).

- GitHub: [@ams0](https://github.com/ams0)
- Email: alessandro.vozza@linux.com

Source repo: [github.com/cloudpirates/flux-workshop](https://github.com/cloudpirates/flux-workshop)
