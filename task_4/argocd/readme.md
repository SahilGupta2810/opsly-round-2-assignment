# Argo CD
Helm charts: https://argoproj.github.io/argo-helm

## Install (Helm)
```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd -f values.yaml -n argocd-system --create-namespace
```

## Install (manifests)
If you want Argo CD to deploy workloads into the same cluster (`kubernetes.default.svc`), you must
also apply the cluster RBAC.

```bash
kubectl apply -k argocd/manifests/cluster-install -n argocd-system
```

## Namespace access (example: `dev`)
If you cannot (or do not want to) grant Argo CD cluster-wide permissions, bind the controller
ServiceAccount to the target namespace.

```bash
kubectl apply -f argocd/manifests/addons/argocd-application-controller-dev-rbac.yaml
```
