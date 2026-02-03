# Task 4 — GitOps with Argo CD

This folder contains configuration and manifests for **Part 4: GitOps with Argo CD**.

## Completion status

| Requirement | Status | Notes |
| --- | --- | --- |
| Task 4.1 — Argo CD installation | Partial | Helm values and upstream manifests are present, plus RBAC config for Argo CD users. HA/Ingress/TLS/SSO/notifications are not fully configured yet. |
| Task 4.2 — Application definitions | Partial | Includes a single dev `Application`. Missing App-of-Apps pattern + staging/prod apps + env-specific sync policies. |
| Task 4.3 — CI pipeline | Not done | No GitHub Actions/GitLab CI pipeline exists in this repo yet. |

## Artifacts

- `argocd/values.yaml` — Helm values (baseline; adjust for your cluster, ingress, SSO, etc.).
- `argocd/manifests/` — upstream Argo CD install manifests (including HA variants and cluster RBAC overlays).
- `argocd/rbac/rbac.yaml` — Argo CD UI/API RBAC (ConfigMap `argocd-rbac-cm`).
- `argocd/app-defination/apps/ai-chatbot-dev.yaml` — example dev application.

## Notes

- Installation steps are documented in `argocd/readme.md`.
- If you see sync failures due to missing Kubernetes permissions, either:
  - apply cluster RBAC (`argocd/manifests/cluster-rbac`), or
  - bind the controller to the target namespace (example: `argocd/manifests/addons/argocd-application-controller-dev-rbac.yaml`).
- `ai-chatbot-dev.yaml` must point to a real chart path in the referenced repo; update `spec.source.path` to match your GitOps repo layout.
