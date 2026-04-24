---
kind: lesson
title: "Lab 0b: Hands-on Helm"
description: |
  Learn Helm — the package manager Flux can manage declaratively — by installing,
  customizing, and upgrading charts the traditional way.
name: helm-lab
slug: helm-hands-on
createdAt: 2026-04-24
updatedAt: 2026-04-24
cover: __static__/flux-cover.png

playground:
  name: k3s

tasks:
  helm_install:
    machine: dev-machine
    run: |
      helm list -A 2>/dev/null | grep -q podinfo
  helm_upgrade:
    machine: dev-machine
    needs:
      - helm_install
    run: |
      kubectl get deployment podinfo -n helm-demo -o jsonpath='{.spec.replicas}' 2>/dev/null | grep -q 3
---
