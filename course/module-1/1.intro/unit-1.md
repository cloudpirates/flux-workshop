---
kind: unit
title: "Introduction: GitOps and Flux"
name: intro-gitops-flux
---

# Introduction: GitOps and Flux

## What is GitOps?

GitOps is an operational model where:

- **Git is the single source of truth** for your infrastructure and application configuration
- **Automated agents** continuously reconcile the actual system state with the desired state in Git
- **All changes go through Git** — pull requests, code review, audit trail for free
- **The system is self-healing** — manual drift is automatically corrected

The key shift: instead of CI/CD pipelines *pushing* changes to your cluster, a controller *pulls*
desired state and converges.

## Why Flux?

[Flux](https://fluxcd.io) is a CNCF Graduated project purpose-built for GitOps on Kubernetes.

**What makes it different:**

- **Kubernetes-native** — everything is a Custom Resource (GitRepository, Kustomization, HelmRelease)
- **Composable controllers** — source, kustomize, helm, notification, image-automation work independently
- **Multi-tenancy** — native RBAC integration via ServiceAccount impersonation
- **OCI-native** — first-class support for OCI artifacts as configuration sources
- **No UI server** — no attack surface, no state to manage, just CRDs and controllers

## The 5 Controllers

```
                    ┌─────────────┐
                    │   Source     │  Fetches from Git, Helm repos, OCI, S3
                    │  Controller │
                    └──────┬──────┘
                           │ artifacts
              ┌────────────┼────────────┐
              ▼            ▼            ▼
     ┌────────────┐ ┌────────────┐ ┌────────────┐
     │ Kustomize  │ │   Helm     │ │   Image    │
     │ Controller │ │ Controller │ │ Automation │
     └─────┬──────┘ └─────┬──────┘ └─────┬──────┘
           │              │              │
           └──────────┬───┘              │ patches Git
                      ▼                  ▼
              ┌──────────────┐   ┌──────────────┐
              │  Kubernetes  │   │  Git Repo    │
              │   Cluster    │   │  (images)    │
              └──────┬───────┘   └──────────────┘
                     │
                     ▼
            ┌──────────────┐
            │ Notification │  Alerts → Slack, Teams, webhooks
            │  Controller  │  Receivers ← Git webhooks
            └──────────────┘
```

## The D2 Reference Architecture

Today's workshop is inspired by ControlPlane's **D2 Reference Architecture** — a production-grade
pattern for multi-cluster, multi-tenant GitOps.

The key insight: **separate concerns into three repositories:**

| Repository | Owned by | Scope | Privilege |
|-----------|----------|-------|-----------|
| **d2-fleet** | Platform team | Cluster bootstrap, tenant onboarding | cluster-admin |
| **d2-infra** | Platform team | Add-ons (monitoring, ingress, cert-manager) | cluster-admin |
| **d2-apps** | Dev teams | Application deployments | namespace-scoped |

We'll build a simplified version of this pattern across the next 5 labs.

> **Next:** Get hands-on with Kustomize — the tool Flux uses under the hood.
