# For testing only. This should be run from master-apps
```
argocd app create spe \
--repo https://github.com/mmwillingham/iac.git \
--revision feature-cwis-887-instructions \
--path app/openshift-automation/day2/spe/overlays/dev \
--dest-server https://kubernetes.default.svc \
--sync-policy automated \
--self-heal \
--sync-option Prune=true \
--sync-option CreateNamespace=true \
--dest-namespace spe

# Delete
argocd app delete spe -y; oc delete project spe; oc patch Application spe -n openshift-gitops -p '{"metadata":{"finalizers":null}}' --type=merge
```
