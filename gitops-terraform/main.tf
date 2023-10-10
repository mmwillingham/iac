data "kubernetes_resource" "gitops" {
  api_version = "v1"
  kind        = "Subscription"

  metadata {
    name      = "openshift-gitops-operator"
    namespace = "openshift-gitops-operator"
  }
  spec {
    channel = "latest"
    installPlanApproval = "Automatic"
    name = "openshift-gitops-operator"
    source = "redhat-operators"
    sourceNamespace = "openshift-marketplace"
  }
}

