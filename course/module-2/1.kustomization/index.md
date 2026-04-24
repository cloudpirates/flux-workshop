---
kind: lesson
title: "Lab 2: Deploy with GitRepository + Kustomization"
description: |
  Create a Kustomization that syncs application manifests from Git to your cluster.
name: kustomization
slug: gitrepo-kustomization
createdAt: 2026-04-23
updatedAt: 2026-04-23
cover: __static__/flux-cover.png

playground:
  name: flux-workshop-ed43474f

tasks:
  podinfo_running:
    machine: dev-machine
    run: |
      kubectl get deployment podinfo -n apps -o jsonpath='{.status.readyReplicas}' 2>/dev/null | grep -qE '^[1-9]'
---
