# Unable to run from GitHub Actions because OpenShift API is private.
# Workaround. After cluster is created, install GitOps and Master App:

```
oc login ...
git clone https://github.com/mmwillingham/iac
cd open
oc apply -k day_1/gitops-operator/overlays/latest
oc apply -k day_1/master-apps
```

# More details below
# Install GitOps
```
# CREATE
           
git clone https://github.com/mmwillingham/iac
cd iac

# Specific version
oc apply -k day_1/gitops-operator/overlays/gitops-1.12

# Latest version
oc apply -k day_1/gitops-operator/overlays/latest

# DELETE
# oc delete -k day_1/gitops-operator/overlays/latest

# May need to add encryption
oc -n openshift-gitops patch argocd/openshift-gitops --type=merge -p='{"spec":{"server":{"route":{"enabled":true,"tls":{"insecureEdgeTerminationPolicy":"Redirect","termination":"reencrypt"}}}}}'
```

# Create GitOps repository connections
```
export REPO_NAME="iac"
export TYPE=git
export PROJECT="gitops-repos"
export URL="https://github.com/mmwillingham/iac"
export USERNAME=<github username>
export PAT='<redacted>'

export REPO_NAME_BASE64=$(echo $REPO_NAME | base64)
export TYPE_BASE64=$(echo $TYPE | base64)
export PROJECT_BASE64=$(echo $PROJECT  | base64)
export URL_BASE64=$(echo $URL  | base64)
export USERNAME_BASE64=$(echo $USERNAME  | base64)
export PAT_BASE64=$(echo $PAT | base64)

echo $REPO_NAME
echo $TYPE
echo $PROJECT
echo $URL
echo $USERNAME
echo $PAT

echo $REPO_NAME_BASE64
echo $TYPE_BASE64
echo $PROJECT_BASE64
echo $URL_BASE64
echo $USERNAME_BASE64
echo $PAT_BASE64

oc -n openshift-gitops create secret generic $REPO_NAME \
--from-literal=name=$REPO_NAME \
--from-literal=type=$TYPE \
--from-literal=project=$PROJECT \
--from-literal=url=$URL \
--from-literal=username=$USERNAME \
--from-literal=password=$PAT
oc -n openshift-gitops label secret $REPO_NAME argocd.argoproj.io/secret-type=repository

```

# Install Master App
```
# CREATE
           
git clone https://github.com/mmwillingham/iac
cd iac
git checkout feature-cwis-887-instructions
oc apply -k day_1/master-apps

# DELETE
# oc delete -k day_1/master-apps
```

