
argocd app create hello-world-bg \
--repo https://github.com/mmwillingham/sampleapps.git \
--path gitops_apps/hello-world-bg/base \
--dest-server https://kubernetes.default.svc \
--sync-policy automated \
--self-heal \
--sync-option Prune=true \
--sync-option CreateNamespace=true \
--dest-namespace hello-world-bg

# Delete
argocd app delete hello-world-bg -y

# Show layout and files
# Repo: https://github.com/mmwillingham/sampleapps/tree/main/gitops_apps/hello-world-blue-green
    Deployment - Blue
        1 replica
        Image tag: 1.0
    Deployment - Green
        2 replicas
        Image tag: latest

    Route - weight to each service

# Weighted 100% to blue
curl https://hello-world-hello-world-bg.apps.bosez-20240521.5nay.p1.openshiftapps.com/
Image version : v1.0

# Keep it running
while true; do curl https://hello-world-hello-world-bg.apps.bosez-20240521.5nay.p1.openshiftapps.com/; sleep 1; done

# Change route to 100% green
# Then click refresh in argoCD console

# Check curl
Image version : latest
