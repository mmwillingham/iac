# Integrate AWS Secrets Manager secrets into OpenShift
Process assumes AWS STS
```
# To verify STS
oc get authentication.config.openshift.io cluster -o json | jq .spec.serviceAccountIssuer
# example response: "https://rh-oidc.s3.us-east-1.amazonaws.com/2b1a6mhmakfmljn26lek7n063ofjb3hi"

# Set SCCs to allow CSI driver
oc new-project csi-secrets-store
oc adm policy add-scc-to-user privileged system:serviceaccount:csi-secrets-store:secrets-store-csi-driver
oc adm policy add-scc-to-user privileged system:serviceaccount:csi-secrets-store:csi-secrets-store-provider-aws

## Create environment variables
export REGION=$(oc get infrastructure cluster -o=jsonpath="{.status.platformStatus.aws.region}")
export OIDC_ENDPOINT=$(oc get authentication.config.openshift.io cluster -o jsonpath='{.spec.serviceAccountIssuer}' | sed  's|^https://||')
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_PAGER=""
export MY_APP="my-secret-app"
export MY_SA=$MY_APP-sa
export MY_SECRET=ocp-secrets # make this lowercase
# Verify OIDC provider exists in AWS with the same OIDC_ENDPOINT as above
aws iam list-open-id-connect-providers | grep ${OIDC_ENDPOINT}

echo $REGION
echo $OIDC_ENDPOINT
echo $AWS_ACCOUNT_ID
echo $AWS_PAGER
echo $MY_APP
echo $MY_SECRET
echo $MY_SA
```

## Deploy AWS Secrets and Configuration Provider
```
# Add helm repo
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts

# Update helm
helm repo update

# Install secrets store CSI driver
helm upgrade --install -n csi-secrets-store csi-secrets-store-driver secrets-store-csi-driver/secrets-store-csi-driver --set syncSecret.enabled=true

# Verify
oc --ce=csi-secrets-store get pods -l "app=secrets-store-csi-driver"

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
#     "StringLike" : {
#       "${OIDC_ENDPOINT}:sub": ["system:serviceaccount:*:*"]

cat <<EOF > trust-policy.json
{
   "Version": "2012-10-17",
   "Statement": [
   {
   "Effect": "Allow",
   "Condition": {
     "StringEquals" : {
       "${OIDC_ENDPOINT}:sub": ["system:serviceaccount:${MY_APP}:${MY_SA}"]
      }
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

## Create an Application POD to expose the secret in a filepath
```
# Create an OpenShift project
# rename if necessary: export MY_APP=myapp2
oc new-project $MY_APP

# Create service account
oc create sa $MY_SA
# Annotate the service account to use the STS Role
oc annotate -n $MY_APP serviceaccount $MY_SA eks.amazonaws.com/role-arn=$ROLE_ARN

# Verify annotation
oc describe sa $MY_SA | grep eks.amazonaws.com/role-arn

# Create a secret provider class to access our secret
# This needs to be in the application namespace
cat << EOF > $MY_SA-secretproviderclass.yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: $MY_APP-aws-secrets
  namespace: $MY_APP
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "$MY_SECRET"  # AWS secret name
        objectType: "secretsmanager"
EOF
cat $MY_SA-secretproviderclass.yaml
oc apply -f $MY_SA-secretproviderclass.yaml

# Verify it exists and contents are as expected
oc get secretproviderclass $MY_APP-aws-secrets -oyaml

# Create a pod using our secret
cat << EOF > $MY_APP-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: $MY_APP
  labels:
    app: $MY_APP
spec:
  serviceAccountName: $MY_SA
  volumes:
  - name: secrets-store-inline
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: "${MY_APP}-aws-secrets"
  containers:
  - name: $MY_APP
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
oc exec -it $MY_APP -- cat /mnt/secrets-store/$MY_SECRET; echo
expected response: # {"username":"shadowman", "password":"hunter2"}

```

## Create an application DEPLOYMENT to expose the secret in an environment variable
```
# Set new variables but use same AWS resources (secret, policy, role)
export MY_APP="my-secret-app-2"
export MY_SA=$MY_APP-sa
echo $MY_APP, $MY_SA

# Create project
oc new-project $MY_APP

# Create service account
oc create sa $MY_SA

# Annotate the service account to use the STS Role
oc annotate -n $MY_APP serviceaccount $MY_SA eks.amazonaws.com/role-arn=$ROLE_ARN

# Verify annotation
oc describe sa $MY_SA | grep eks.amazonaws.com/role-arn

# Create a secret provider class to access our secret
# This needs to be in the application namespace

cat << EOF > $MY_APP-secretproviderclass.yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: $MY_APP-aws-secrets
  namespace: $MY_APP
spec:
  provider: aws
  secretObjects:
    - data:
        - key: db_string # whatever you want the env variable to be called
          objectName: $MY_SECRET   # AWS secret name
      secretName: $MY_APP # kubernetes secret name I think
      type: Opaque
  parameters:
    objects: |
      - objectName: "$MY_SECRET"  # AWS secret name
        objectType: "secretsmanager"
EOF
cat $MY_APP-secretproviderclass.yaml
oc apply -f $MY_APP-secretproviderclass.yaml

# Verify it exists and contents are as expected
oc get secretproviderclass $MY_APP-aws-secrets -oyaml

cat << EOF > $MY_APP-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $MY_APP
  namespace: $MY_APP
  labels:
    app: $MY_APP
spec:
  selector:
    matchLabels:
      app: $MY_APP
  template:
    metadata:
      labels:
        app: $MY_APP
    spec:
      serviceAccountName: $MY_SA
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
                key: $MY_APP # k8s secret specified in secretproviderclass
                name: db_string # env variable specified in secretproviderclass
EOF
cat $MY_APP-deployment.yaml
oc apply -f $MY_APP-deployment.yaml

oc exec $MY_APP -- printenv | grep db_string
# expected result: db_string={"username":"shadowman", "password":"hunter2"}
# You can extract just the password value with this:
# Add steps here

```
