# Secrets Store CSI Driver



# Old Docs
Repo
```
https://github.com/kubernetes-sigs/secrets-store-csi-driver/tree/main/deploy
```
Instructions
```
https://secrets-store-csi-driver.sigs.k8s.io/getting-started/installation.html#alternatively-deployment-using-yamls
```
Manual Steps
```
# NOTE: If customer wants to use CSI driver, these steps need to be adjusted to use GitOps approach. But External Secrets Operator is preferred, and already configured in repo.

# Integrate AWS Secrets Manager secrets into OpenShift
Process assumes AWS STS
```
# To verify STS
oc get authentication.config.openshift.io cluster -o json | jq .spec.serviceAccountIssuer
# example response: "https://rh-oidc.s3.us-east-1.amazonaws.com/2b1a6mhmakfmljn26lek7n063ofjb3hi"

## Create environment variables
export REGION=$(oc get infrastructure cluster -o=jsonpath="{.status.platformStatus.aws.region}")
export OIDC_ENDPOINT=$(oc get authentication.config.openshift.io cluster -o jsonpath='{.spec.serviceAccountIssuer}' | sed  's|^https://||')
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_PAGER=""
export MY_APP="bo-secret-app"
export MY_SECRET=db_password # make this lowercase
# Verify OIDC provider exists in AWS with the same OIDC_ENDPOINT as above
aws iam list-open-id-connect-providers | grep ${OIDC_ENDPOINT}

echo $REGION
echo $OIDC_ENDPOINT
echo $AWS_ACCOUNT_ID
echo $MY_APP
echo $MY_SECRET
```

## Deploy AWS Secrets and Configuration Provider
### Also possible to do it without helm. See my repo from https://github.com/mmwillingham/iac/app/openshift-automation/day2/kustomize/csi-driver

```
# Add helm repo
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts

# Update helm
helm repo update

# Install secrets store CSI driver
helm upgrade --install -n csi-secrets-store csi-secrets-store-driver secrets-store-csi-driver/secrets-store-csi-driver --set syncSecret.enabled=true

# Verify
oc -n csi-secrets-store get pods -l "app=secrets-store-csi-driver"

# Deploy AWS provider
wget https://raw.githubusercontent.com/rh-mobb/documentation/main/content/misc/secrets-store-csi/aws-provider-installer.yaml

sed 's/1.0.r2-6-gee95299-2022.04.14.21.07/1.0.r2-68-gab548b3-2024.03.20.21.58/' aws-provider-installer.yaml > aws-provider-installer-updated.yaml

oc apply -f aws-provider-installer-updated.yaml

# Check that both Daemonsets are running
oc -n csi-secrets-store get ds csi-secrets-store-provider-aws csi-secrets-store-driver-secrets-store-csi-driver

# Label the Secrets Store CSI Driver to allow use with the restricted pod security profile
oc label csidriver.storage.k8s.io/secrets-store.csi.k8s.io security.openshift.io/csi-ephemeral-volume-profile=restricted

Verify the label
oc get csidriver.storage.k8s.io/secrets-store.csi.k8s.io --show-labels | grep "security.openshift.io/csi-ephemeral-volume-profile=restricted"
```

## Create an AWS secret and IAM access policies
```
# Create a secret (bucket) in Secrets Manager
# NOTE: This will create a single secret (bucket) in AWS containing one or more key/value pairs

SECRET_ARN=$(aws --region "$REGION" secretsmanager create-secret --name ${MY_SECRET} --secret-string '{"username":"shadowman", "password":"hunter2"}' --query ARN --output text)
echo $SECRET_ARN

# Create an IAM Access Policy document 
# NOTE: for the previous secret, this document specifies what actions are allowed
# NOTE: For testing, to allow access to all secrets, you can change Resource value to: "Resource": "*"

cat << EOF > policy.json
{
   "Version": "2012-10-17",
   "Statement": [{
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": ["$SECRET_ARN"]
      }]
}
EOF

# Verify the variables were correctly populated
cat policy.json

# Create an IAM Access Policy

POLICY_ARN=$(aws --region "$REGION" --query Policy.Arn --output text iam create-policy --policy-name ocp-access-to-${MY_SECRET}-policy --policy-document file://policy.json)
echo $POLICY_ARN

# Create an IAM Role trust policy document
# NOTE: The trust policy is locked down to the default service account of a namespace you create later in this process.
# NOTE: For testing, to allow all service accounts from all namespaces, you can change to
#     "StringLike" : {"${OIDC_ENDPOINT}:sub": ["system:serviceaccount:*:*"]}

cat <<EOF > trust-policy.json
{
   "Version": "2012-10-17",
   "Statement": [
   {
   "Effect": "Allow",
   "Condition": {
     "StringEquals" : {"${OIDC_ENDPOINT}:sub": ["system:serviceaccount:${MY_APP}:${MY_APP}-sa"]}
    },
    "Principal": {
       "Federated": "arn:aws:iam::$AWS_ACCOUNT_ID:oidc-provider/${OIDC_ENDPOINT}"
    },
    "Action": "sts:AssumeRoleWithWebIdentity"
    }
    ]
}
EOF

# Verify variables were correctly populated
cat trust-policy.json

# Create IAM role
ROLE_ARN=$(aws iam create-role --role-name ocp-access-to-${MY_SECRET} --assume-role-policy-document file://trust-policy.json --query Role.Arn --output text)
echo $ROLE_ARN

# Attach the role to the policy
aws iam attach-role-policy --role-name ocp-access-to-${MY_SECRET} --policy-arn $POLICY_ARN

# Verify attachment
aws iam list-attached-role-policies --role-name ocp-access-to-${MY_SECRET} --output text
```

## Create a secret provider class for the secret
```
# Create an OpenShift project
# rename if necessary: export MY_APP=myapp2
oc new-project $MY_APP

# Create service account
oc create sa $MY_APP-sa

# Annotate the service account to use the STS Role
oc annotate -n $MY_APP serviceaccount $MY_APP-sa eks.amazonaws.com/role-arn=$ROLE_ARN

# Verify annotation
oc describe sa $MY_APP-sa | grep eks.amazonaws.com/role-arn

# Create a secret provider class to access our secret
This needs to be in the application namespace.

cat << EOF > $MY_APP-secretproviderclass.yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: $MY_APP-aws-secrets
  namespace: $MY_APP
spec:
  provider: aws
#################################################################
# SecretObjects is required for generating a kubernetes secret.
# Optional if you only want to mount the secret to a volume path
  secretObjects:
    - data:
        - key: db_string           # data field to populate
          objectName: $MY_SECRET   # AWS secret name
      secretName: $MY_APP-k8s      # kubernetes secret name
      type: Opaque
#################################################################
  parameters:
    objects: |
      - objectName: "$MY_SECRET"  # AWS secret name
        objectType: "secretsmanager"
EOF
cat $MY_APP-secretproviderclass.yaml
oc apply -f $MY_APP-secretproviderclass.yaml

# Verify it exists and contents are as expected
oc get secretproviderclass $MY_APP-aws-secrets -oyaml
```

## Create an Application POD to expose the secret in a filepath
```
# Create a pod using our secret
cat << EOF > $MY_APP-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: $MY_APP-pod
  labels:
    app: $MY_APP-pod
spec:
  serviceAccountName: $MY_APP-sa
  volumes:
  - name: secrets-store-inline
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: "${MY_APP}-aws-secrets"
  containers:
  - name: $MY_APP-pod
    image: k8s.gcr.io/e2e-test-images/busybox:1.29
    command:
      - "/bin/sleep"
      - "10000"
    volumeMounts:
    - name: secrets-store-inline
      mountPath: "/mnt/secrets-store"
      readOnly: true
EOF
cat $MY_APP-pod.yaml

oc apply -f $MY_APP-pod.yaml

oc get pods

# Verify the Pod has the secret mounted
oc exec -it $MY_APP-pod -- cat /mnt/secrets-store/$MY_SECRET; echo
expected response: # {"username":"shadowman", "password":"hunter2"}

```

## Create an application DEPLOYMENT to expose the secret in an environment variable
```
cat << EOF > $MY_APP-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $MY_APP
  namespace: $MY_APP
  labels:
    app: $MY_APP
    component: api
spec:
  selector:
    matchLabels:
      app: $MY_APP
      component: api
  template:
    metadata:
      labels:
        app: $MY_APP
        component: api
    spec:
      serviceAccountName: $MY_APP-sa
      containers:
      - name: $MY_APP
        image: k8s.gcr.io/e2e-test-images/busybox:1.29
        command:
          - "/bin/sleep"
          - "10000"
        env:
          - name: db_string
            valueFrom:
              secretKeyRef:
                #name: $MY_APP-aws-secrets # secret provider class
                name: $MY_APP-k8s # kubernetes secret
                key: db_string # env variable specified in secretproviderclass
EOF
cat $MY_APP-deployment.yaml
oc apply -f $MY_APP-deployment.yaml

oc exec $(oc get pods -l app=$MY_APP -oname) -- env | grep db_string
# expected result: db_string={"username":"shadowman", "password":"hunter2"}
# You can extract just the password value with this:
## Maybe for enviroment variables, it's impossible to get partial, so if you want just password, create a secret called db_password with value of the password as its contents
NOTE: when I did this, I don't see the variable when I "oc exec", "oc rsh", or "oc debug" but I do when I select pods "Terminal" in the console.
```

## Troubleshooting
# Check csi-secrets-store provider logs
oc logs -n csi-secrets-store $(oc get pods -n csi-secrets-store -oname | grep provider | tail -1)
oc logs -n csi-secrets-store $(oc get pods -n csi-secrets-store -oname | grep provider | head -1)

# Check service account annotation
oc describe sa $MY_APP-sa | grep eks.amazonaws.com/role-arn
```
