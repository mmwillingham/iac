# Run from Master App or
```
argocd app create ecm-uat \
--repo https://github.com/NCDHHS-Enterprise/cwis-infra.git \
--revision feature-cwis-887-instructions \
--path app/openshift-automation/day2/ecm/overlays/uat \
--dest-server https://kubernetes.default.svc \
--sync-policy automated \
--self-heal \
--sync-option Prune=true \
--sync-option CreateNamespace=true \
--dest-namespace ecm-uat

# Delete
argocd app delete ecm-uat -y; oc delete project ecm-uat; oc patch Application ecm-uat -n openshift-gitops -p '{"metadata":{"finalizers":null}}' --type=merge
```