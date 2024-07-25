# Web Terminal

Install Web Terminal.

Do not use the `base` directory directly, as you will need to patch the `channel` based on the version of OpenShift you are using, or the version of the operator you want to use.

The current *overlays* available are for the following channels:

* [fast](operator/overlays/fast)

## Usage

If you have cloned the repository, you can install Web Terminal based on the overlay of your choice by running from the root directory.

```
oc apply -k web-terminal/operator/overlays/<channel>
```

Or, without cloning:

```
oc apply -k https://github.com/mmwillingham/iac/app/gitops/web-terminal/overlays

```

As part of a different overlay in your own GitOps repo:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/redhat-cop/gitops-catalog/web-terminal/operator/overlays/<channel>?ref=main
```