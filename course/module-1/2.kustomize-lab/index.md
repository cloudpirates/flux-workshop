---
kind: lesson
title: "Lab 0: Hands-on Kustomize"
description: |
  Learn Kustomize — the tool Flux uses under the hood — by building overlays
  for different environments without touching the original YAML.
name: kustomize-lab
slug: kustomize-hands-on
createdAt: 2026-04-24
updatedAt: 2026-04-24
cover: __static__/flux-cover.png

playground:
  name: k3s

tasks:
  kustomize_base:
    machine: dev-machine
    run: |
      kubectl get deployment podinfo -n default 2>/dev/null | grep -q podinfo
  kustomize_overlay:
    machine: dev-machine
    needs:
      - kustomize_base
    run: |
      kubectl get deployment podinfo -n staging 2>/dev/null | grep -q podinfo
---
