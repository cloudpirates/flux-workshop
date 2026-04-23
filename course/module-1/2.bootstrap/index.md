---
kind: lesson
title: "Lab 1: Bootstrap Flux"
description: |
  Install Flux controllers, connect to Gitea, and verify the self-managing GitOps loop.
name: bootstrap
slug: bootstrap-flux
createdAt: 2026-04-23
updatedAt: 2026-04-23
cover: __static__/flux-cover.png

playground:
  name: flux-workshop-ed43474f

tasks:
  flux_installed:
    run: |
      flux check 2>&1 | grep -q "all checks passed"
  gitrepo_ready:
    needs:
      - flux_installed
    run: |
      flux get sources git flux-system -n flux-system 2>&1 | grep -q "True"
---
