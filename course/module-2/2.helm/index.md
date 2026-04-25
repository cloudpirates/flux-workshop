---
kind: lesson
title: "Lab 3: Helm Releases with HelmRelease"
description: |
  Manage Helm charts declaratively using HelmRepository and HelmRelease CRDs.
name: helm
slug: helm-releases
createdAt: 2026-04-23
updatedAt: 2026-04-23
cover: __static__/flux-cover.png

playground:
  name: flux-workshop-ready-dbd9ad17

tasks:
  helmrelease_ready:
    machine: dev-machine
    run: |
      flux get helmreleases -A 2>&1 | grep -q "True"
---
