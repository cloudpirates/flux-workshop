---
kind: unit
title: "Lab 6: AI-Assisted GitOps with the Flux MCP Server"
name: lab6-ai-mcp-server
---

# Lab 6: AI-Assisted GitOps with the Flux MCP Server

> **Duration:** 10 minutes
> **Goal:** Connect an AI assistant to your cluster via the Flux Operator MCP Server and use natural language to inspect, troubleshoot, and operate your GitOps pipeline.
>
> **Catch-up:** If you're starting here, run `kubectl apply -f checkpoints/lab5-complete.yaml` to get the state from Labs 1-5.

## Background

As GitOps pipelines grow in complexity, the cognitive load of troubleshooting increases.
The **Flux MCP Server** (part of the [Flux Operator](https://github.com/controlplaneio-fluxcd/flux-operator) project)
implements the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) to bridge AI assistants
directly to your Kubernetes clusters.

What does this unlock?

- **End-to-end pipeline debugging** — trace from HelmReleases to pod logs via conversation
- **Root cause analysis** — "Why did the frontend deployment fail?" gets a real answer
- **Cross-cluster comparison** — "Compare podinfo between staging and production"
- **Visual dependency graphs** — "Draw a Mermaid diagram of Kustomization dependencies"
- **GitOps operations** — "Resume all suspended resources and verify status"
- **Up-to-date guidance** — MCP server searches the latest Flux docs, not stale training data

## Step 1: Install the Flux Operator and MCP Server

First, install the Flux Operator (which replaces or extends the standard Flux controllers):

```bash
# Install the Flux Operator via Helm
helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --namespace flux-system
```

Then install the MCP server binary:

```bash
# The MCP server is a standalone Go binary
# In the playground, it's pre-installed at /usr/local/bin/flux-operator-mcp
flux-operator-mcp --version
```

## Step 2: Configure MCP for Your AI Assistant

The MCP server uses stdio transport — your AI tool spawns it as a subprocess.
Here's the configuration for Claude, Cursor, Windsurf, or GitHub Copilot:

```json
{
  "mcpServers": {
    "flux-operator-mcp": {
      "command": "flux-operator-mcp",
      "args": ["serve"],
      "env": {
        "KUBECONFIG": "/root/.kube/config"
      }
    }
  }
}
```

For **read-only mode** (safe for production clusters):

```json
{
  "mcpServers": {
    "flux-operator-mcp": {
      "command": "flux-operator-mcp",
      "args": ["serve", "--read-only"],
      "env": {
        "KUBECONFIG": "/root/.kube/config"
      }
    }
  }
}
```

> **Security note:** The MCP server operates with your existing kubeconfig permissions.
> Use service account impersonation for least-privilege access. Sensitive data in
> Kubernetes Secrets is automatically masked.

## Step 3: Hands-on — Talk to Your Cluster

Since we're in a playground without a full AI IDE, we'll use the MCP server's CLI mode
to demonstrate what the tools do under the hood.

### Health Check

```bash
# List all MCP tools available
flux-operator-mcp tools list

# Get cluster health (what the AI calls behind the scenes)
flux-operator-mcp tools call flux_health
```

### Pipeline Visualization

```bash
# Get the dependency tree the AI would use to draw a Mermaid diagram
flux-operator-mcp tools call flux_tree --namespace flux-system
```

### Troubleshooting

```bash
# Simulate a broken deployment — scale podinfo to 0 replicas
kubectl scale deployment podinfo -n apps --replicas=0

# Ask the MCP server for root cause analysis
flux-operator-mcp tools call flux_debug \
  --kind HelmRelease \
  --name podinfo \
  --namespace apps

# Flux will detect the drift and correct it (from Lab 5)
# Watch the reconciliation
flux get helmreleases -n apps --watch
```

### Operations via MCP

```bash
# Suspend all resources (what "suspend everything" would trigger)
flux-operator-mcp tools call flux_suspend --all --namespace apps

# Resume them (what "resume all suspended resources" would trigger)
flux-operator-mcp tools call flux_resume --all --namespace apps
```

## Step 4: Demo — The Conversational GitOps Experience

Here's what this looks like in practice with a real AI assistant:

**You:** "Analyze the Flux installation in my cluster and report the status of all components."

**AI (using MCP tools):**
1. Calls `flux_health` → gets controller status
2. Calls `flux_list` → enumerates all Flux resources
3. Calls `flux_tree` → maps dependencies
4. Synthesizes a human-readable report with recommendations

**You:** "The podinfo app in the apps namespace seems slow. Investigate."

**AI (using MCP tools):**
1. Calls `flux_debug --kind HelmRelease --name podinfo --namespace apps`
2. Calls `kubectl_logs` for podinfo pods
3. Calls `flux_diff` to compare desired vs actual state
4. Reports: "The HelmRelease is healthy but I notice the replica count was manually changed. Flux will reconcile this in the next interval. The pods show increased latency in health checks — consider increasing resource limits."

## Why This Matters

The MCP Server turns Flux from a "deploy and hope" tool into a **conversational platform**:

| Traditional GitOps | AI-Assisted GitOps |
|---|---|
| `kubectl get hr -A`, scan output | "Show me failed releases" |
| Read YAML, trace dependencies manually | "Why did the frontend fail?" |
| Switch contexts, diff configs | "Compare staging vs production" |
| Write YAML, commit, push, wait | "Deploy podinfo v6.7 to staging" |

This is the future of platform engineering — GitOps pipelines that you can **talk to**.

## Key Takeaways

- The Flux MCP Server is an official ControlPlane project, not a toy
- It works with Claude, Cursor, Windsurf, GitHub Copilot, and any MCP-compatible client
- Read-only mode makes it safe for production observation
- It searches the latest Flux docs for accurate guidance (not hallucinated)
- Combined with the D2 architecture from Labs 1-5, you get enterprise GitOps + AI operations

> **Next:** Advanced Flux features — notifications, image automation, and scaling patterns.
