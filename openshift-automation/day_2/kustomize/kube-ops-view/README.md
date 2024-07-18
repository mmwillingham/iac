# kube-ops-view
oc adm policy add-scc-to-user privileged system:serviceaccount:ops-view:kube-ops-view
oc adm policy add-scc-to-user privileged system:serviceaccount:ops-view:default

argocd app create kube-ops-view \
--repo https://github.com/mmwillingham/sampleapps.git \
--path gitops_apps/kube-ops-view \
--dest-server https://kubernetes.default.svc \
--directory-recurse \
--sync-policy automated \
--self-heal \
--sync-option Prune=true \
--sync-option CreateNamespace=true \
--dest-namespace ocp-ops-view

# Open route to view

# DELETE 
argocd app delete kube-ops-view -y
