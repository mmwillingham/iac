# Run from Master App or
```
argocd app create ecm-dev \
--repo https://github.com/NCDHHS-Enterprise/cwis-infra.git \
--revision feature-cwis-887-instructions \
--path app/openshift-automation/day2/ecm/overlays/dev \
--dest-server https://kubernetes.default.svc \
--sync-policy automated \
--self-heal \
--sync-option Prune=true \
--sync-option CreateNamespace=true \
--dest-namespace ecm-dev

# Delete
argocd app delete ecm-dev -y
```