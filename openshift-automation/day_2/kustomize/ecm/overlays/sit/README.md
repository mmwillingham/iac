# Run from Master App or
```
argocd app create ecm-sit \
--repo https://github.com/mmwillingham/iac.git \
--revision feature-cwis-887-instructions \
--path app/openshift-automation/day2/ecm/overlays/sit \
--dest-server https://kubernetes.default.svc \
--sync-policy automated \
--self-heal \
--sync-option Prune=true \
--sync-option CreateNamespace=true \
--dest-namespace ecm-sit

# Delete
argocd app delete ecm-sit -y
```