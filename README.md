# From Git to Production: Hands-on GitOps with Flux

A 90-minute hands-on workshop for [Devoxx Greece 2026](https://devoxx.gr/).

## What You'll Learn

- Bootstrap Flux on a Kubernetes cluster
- Deploy apps with GitRepository + Kustomization
- Manage Helm releases declaratively with HelmRelease
- Implement multi-tenancy using the D2 fleet/infra/apps pattern
- Use OCI artifacts and observe drift detection in action

## Prerequisites

- Basic Kubernetes knowledge (kubectl, Pods, Deployments, Services)
- Familiarity with YAML and basic Helm concepts
- A GitHub account (for Flux bootstrap)

## Based On

This workshop is inspired by ControlPlane's [D2 Reference Architecture](https://fluxcd.control-plane.io/guides/d2-architecture-reference/) — a production-grade pattern for multi-cluster, multi-tenant GitOps with Flux.

## Workshop Structure

| Time  | Duration | Section | Type |
|-------|----------|---------|------|
| 0:00  | 10 min   | Intro: GitOps principles, Flux overview | Talk |
| 0:10  | 15 min   | Lab 1: Bootstrap Flux | Hands-on |
| 0:25  | 15 min   | Lab 2: Deploy with GitRepository + Kustomization | Hands-on |
| 0:40  | 5 min    | Break / catch-up | -- |
| 0:45  | 15 min   | Lab 3: Helm releases with HelmRelease | Hands-on |
| 1:00  | 15 min   | Lab 4: Multi-tenancy (D2 pattern) | Hands-on |
| 1:15  | 10 min   | Lab 5: OCI artifacts & drift detection | Hands-on |
| 1:25  | 5 min    | Wrap-up & Q&A | Talk |

## Repository Layout

```
manifests/          # Kubernetes manifests used across labs
  apps/             # Sample application (podinfo)
  infra/            # Infrastructure add-ons (monitoring)
  tenants/          # Multi-tenancy RBAC and namespaces
checkpoints/        # Catch-up manifests for each lab
scripts/            # Setup and helper scripts
training/           # iximiuz Labs training content
playground.yaml     # iximiuz Labs playground definition
```

## Running the Labs

Labs run on [iximiuz Labs](https://labs.iximiuz.com/) with pre-configured Kubernetes clusters.
Each lab builds on the previous one — state accumulates across labs.

If you fall behind, apply the checkpoint for the previous lab:

```bash
kubectl apply -f checkpoints/labN-complete.yaml
```

## References

- [Flux Documentation](https://fluxcd.io/flux/)
- [D2 Reference Architecture](https://fluxcd.control-plane.io/guides/d2-architecture-reference/)
- [d2-fleet](https://github.com/controlplaneio-fluxcd/d2-fleet)
- [d2-infra](https://github.com/controlplaneio-fluxcd/d2-infra)
- [d2-apps](https://github.com/controlplaneio-fluxcd/d2-apps)
- [Flux Operator](https://github.com/controlplaneio-fluxcd/flux-operator)

## Author

[Alessandro Vozza](https://github.com/ams0) — Golden Kubestronaut, CNCF Ambassador
