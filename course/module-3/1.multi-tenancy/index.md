---
kind: lesson
title: "Lab 4: Multi-Tenancy — The D2 Pattern"
description: |
  Separate platform and application team concerns with ServiceAccount
  impersonation and namespace-scoped RBAC.
name: multi-tenancy
slug: multi-tenancy-d2
createdAt: 2026-04-23
updatedAt: 2026-04-23
cover: __static__/flux-cover.png

playground:
  name: flux-workshop-ed43474f

tasks:
  tenant_namespace:
    machine: dev-machine
    run: |
      kubectl get namespace team-a 2>/dev/null | grep -q Active
  tenant_pods:
    machine: dev-machine
    needs:
      - tenant_namespace
    run: |
      kubectl get pods -n team-a 2>/dev/null | grep -q Running
---
