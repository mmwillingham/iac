# STAGE
argocd app create hello-world-k-stage \
--repo https://github.com/mmwillingham/sampleapps.git \
--path gitops_apps/hello-world-k-env/overlays/stage \
--dest-server https://kubernetes.default.svc \
--sync-policy automated \
--self-heal \
--sync-option ServerSideApply=true \
--sync-option Validate=false \
--sync-option CreateNamespace=true \
--dest-namespace hello-world-k-stage

curl https://hello-world-hello-world-k-stage.apps.bosez-20240521.5nay.p1.openshiftapps.com/

# Delete
argocd app delete hello-world-k-stage -y

# PROD
argocd app create hello-world-k-prod \
--repo https://github.com/mmwillingham/sampleapps.git \
--path gitops_apps/hello-world-k-env/overlays/prod \
--dest-server https://kubernetes.default.svc \
--sync-policy automated \
--self-heal \
--sync-option ServerSideApply=true \
--sync-option Validate=false \
--sync-option CreateNamespace=true \
--dest-namespace hello-world-k-prod

curl https://hello-world-hello-world-k-prod.apps.bosez-20240521.5nay.p1.openshiftapps.com/

# Delete
argocd app delete hello-world-k-prod -y
