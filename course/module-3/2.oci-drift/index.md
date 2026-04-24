---
kind: lesson
title: "Lab 5: OCI Artifacts and Drift Detection"
description: |
  Use OCI container registries as configuration sources and observe
  Flux automatically correcting manual drift.
name: oci-drift
slug: oci-artifacts-drift
createdAt: 2026-04-23
updatedAt: 2026-04-23
cover: __static__/flux-cover.png

playground:
  name: flux-workshop-ed43474f

tasks:
  oci_source:
    machine: dev-machine
    run: |
      flux get sources oci -A 2>&1 | grep -q "True"
  oci_pods:
    machine: dev-machine
    needs:
      - oci_source
    run: |
      kubectl get pods -n oci-apps 2>/dev/null | grep -q Running
---
