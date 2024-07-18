SUCCESS

# STAGE
argocd app create hello-world-k-stage \
--repo https://github.com/mmwillingham/sampleapps.git \
--path gitops_apps/hello-world-k-env/overlays/stage \
--dest-server https://kubernetes.default.svc \
--sync-policy automated \
--self-heal \
--dest-namespace hello-world-k-stage

argocd app delete hello-world-k-stage -y
curl https://hello-world-hello-world-k-stage.apps.bosez-20240521.5nay.p1.openshiftapps.com/

# PROD
argocd app create hello-world-k-prod \
--repo https://github.com/mmwillingham/sampleapps.git \
--path gitops_apps/hello-world-k-env/overlays/prod \
--dest-server https://kubernetes.default.svc \
--sync-policy automated \
--self-heal \
--dest-namespace hello-world-k-prod

https://hello-world-hello-world-k-prod.apps.bosez-20240521.5nay.p1.openshiftapps.com/

argocd app delete hello-world-k-prod -y
