---
kind: unit
title: "Lab 5: OCI Artifacts and Drift Detection"
name: lab5-oci-drift
---

> **Fresh playground?** If you're starting this lab on a new playground, run:
> ```bash
> curl -sf https://raw.githubusercontent.com/cloudpirates/flux-workshop/main/scripts/catch-up.sh | bash
> ```
> This sets up Gitea, Flux, and the workshop repo automatically (~4 min).

# Lab 5: OCI Artifacts and Drift Detection

> **Duration:** 10 minutes
> **Goal:** Replace Git with an OCI registry as your source of truth, then watch Flux correct
> manual drift in real time.
>
> **Catch-up:** If you're starting here, run `kubectl apply -f checkpoints/lab4-complete.yaml` to get the state from Labs 1-4.

## Why OCI?

Git is great for authoring, but for *distribution* OCI artifacts win:

- **Signed and versioned** — cosign, SBOM, immutable tags
- **Pull-through caches** — distribution at scale without git-clone bottlenecks
- **Air-gapped friendly** — one artifact to mirror, not N git repos
- **No tokens to scope** — pull creds, not write creds, live on the cluster

In production D2 deployments, `d2-apps` is typically *published* as OCI artifacts by CI,
and the cluster watches the OCI registry — not the Git repo directly.

## Step 1: Switch to an OCIRepository

We'll replace the `flux-system` GitRepository with a public OCI artifact that ships
the podinfo manifests. `stefanprodan/manifests/podinfo` is a public `oci://` source
maintained by the Flux team for exactly this demo.

```bash
cd ~/workshop/flux-workshop

cat > clusters/staging/podinfo-oci.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: podinfo-oci
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: podinfo
  namespace: podinfo-oci
spec:
  interval: 1m
  url: oci://ghcr.io/stefanprodan/manifests/podinfo
  ref:
    semver: "6.x"
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo
  namespace: podinfo-oci
spec:
  interval: 2m
  targetNamespace: podinfo-oci
  prune: true
  sourceRef:
    kind: OCIRepository
    name: podinfo
  path: "./"
EOF

git add clusters/staging/podinfo-oci.yaml
git commit -m "Add podinfo via OCIRepository"
git push
```

## Step 2: Watch Flux Reconcile the OCI Source

```bash
flux reconcile source git flux-system -n flux-system
flux get sources oci -A
```

You should see:

```
NAMESPACE       NAME     REVISION                    SUSPENDED   READY   MESSAGE
podinfo-oci     podinfo  6.7.1@sha256:abc123...     False       True    stored artifact...
```

Notice the revision is an **OCI digest**, not a Git SHA. That's a cryptographic guarantee
that the artifact pulled matches the one signed by CI.

Verify podinfo is running:

```bash
kubectl get pods,svc -n podinfo-oci
```

## Step 3: Introduce Drift

Let's pretend a tired on-call engineer scales down the deployment at 3am:

```bash
kubectl scale deployment/podinfo -n podinfo-oci --replicas=0
kubectl get pods -n podinfo-oci
```

All pods gone. Now wait up to 2 minutes (our Kustomization interval) and check again:

```bash
watch -n 2 'kubectl get deploy,pods -n podinfo-oci'
```

Flux will notice the drift and restore the desired replica count. You'll see the
Deployment scale back up, pods recreate, Service stays intact.

To force it immediately:

```bash
flux reconcile kustomization podinfo -n podinfo-oci --with-source
```

## Step 4: Try a Sneakier Drift

Spec changes are reverted the same way:

```bash
kubectl patch deployment podinfo -n podinfo-oci \
  --type='strategic' \
  -p='{"spec":{"template":{"spec":{"containers":[{"name":"podinfo","image":"nginx:alpine"}]}}}}'

kubectl get deploy podinfo -n podinfo-oci -o jsonpath='{.spec.template.spec.containers[0].image}'
```

Wait one reconciliation cycle, then check again:

```bash
flux reconcile kustomization podinfo -n podinfo-oci
kubectl get deploy podinfo -n podinfo-oci -o jsonpath='{.spec.template.spec.containers[0].image}'
```

Back to `ghcr.io/stefanprodan/podinfo:...`. Flux does not negotiate with drift.

## Step 5: The Production Pattern

In the real D2 architecture, the sequence is:

1. Dev pushes to `d2-apps` Git repo
2. CI runs `flux push artifact oci://registry/repo:v1.2.3 --path ./apps`
3. CI signs it with `cosign sign`
4. OCIRepository in the cluster watches `semver: "1.x"`
5. Flux verifies the signature before applying (via `verify.provider: cosign`)

To explore signature verification (outside this lab's time budget), see:
<https://fluxcd.io/flux/components/source/ocirepositories/#verification>

## What You Just Proved

- OCI artifacts can fully replace Git as a source for Flux
- Drift is corrected automatically, whether it's replicas, images, or arbitrary spec fields
- The cluster only needs pull credentials — no write access to Git, no long-lived tokens

## Wrap-up Checklist

Before the workshop ends, take one minute to check:

```bash
flux get all -A
```

You should see sources and reconcilers for every lab still green. That's your whole
GitOps pipeline, top to bottom, in 90 minutes.

## Where to Go Next

- **Image automation** — `flux get images all -A` automatically updates Git when new
  images appear in a registry
- **Notification controller** — fire Slack/Teams/webhook alerts on reconciliation events
- **Flux Operator** — lifecycle-manage Flux itself (the ControlPlane-maintained CRD)
- **D2 Reference** — clone the three repos and explore the real thing:
  - <https://github.com/controlplaneio-fluxcd/d2-fleet>
  - <https://github.com/controlplaneio-fluxcd/d2-infra>
  - <https://github.com/controlplaneio-fluxcd/d2-apps>

Thanks for coming — find me on any socials as **@ams0** with questions.
