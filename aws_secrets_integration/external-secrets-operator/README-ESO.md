
# Integrate AWS Secrets Manager secrets into OpenShift - using External Secrets Operator
Process assumes AWS STS
```
# To verify STS
oc get authentication.config.openshift.io cluster -o json | jq .spec.serviceAccountIssuer
# example response: "https://rh-oidc.s3.us-east-1.amazonaws.com/2b1a6mhmakfmljn26lek7n063ofjb3hi"

# Create environment variables
export REGION=$(oc get infrastructure cluster -o=jsonpath="{.status.platformStatus.aws.region}")
export OIDC_ENDPOINT=$(oc get authentication.config.openshift.io cluster -o jsonpath='{.spec.serviceAccountIssuer}' | sed  's|^https://||')
export AWS_ACCOUNT_ID=`aws sts get-caller-identity --query Account --output text`
export AWS_PAGER=""
export NAMESPACE="external-secrets"
export USER_NAMESPACE="abc-user-namespace"
export SA_NAME="external-secrets-operator-sa"
export ESO_SECRET_BUCKET=eso-bucket5
export KEY1="username"
export VALUE1="bolauder"
export KEY2="password"
export VALUE2="HelloWorld"
export KEY3="cred-string"
export VALUE3="{"username":"BoLauder", "password":"HelloWorld123"}"
export AWS_SECRETS_POLICY_NAME="ocp-access-to-aws-secrets"

echo $REGION
echo $OIDC_ENDPOINT
echo $AWS_ACCOUNT_ID
echo $NAMESPACE
echo $USER_NAMESPACE
echo $SA_NAME
echo $ESO_SECRET_BUCKET
echo $KEY1
echo $VALUE1
echo $KEY2
echo $VALUE2
echo $KEY3
echo $VALUE3
echo $AWS_SECRETS_POLICY_NAME
echo $AWS_PAGER # Will be blank


# Parameterize the secret creation using KEY/VALUE variables. Here and when creating ExternalSecret below
# Create secret bucket
ESO_SECRET_ARN=$(aws --region "$REGION" secretsmanager create-secret --name ${ESO_SECRET_BUCKET} --secret-string '{"'"$KEY1"'":"'"$VALUE1"'", "'"$KEY2"'":"'"$VALUE2"'"}' --query ARN --output text)

# ESO_SECRET_ARN_TEST=$(aws --region "$REGION" secretsmanager create-secret --name eso-bucket7 --secret-string '{"'"$KEY1"'":"'"$VALUE1"'", "'"$KEY2"'":"'"$VALUE2"'", "{"username":"BoLauder", "password":"HelloWorld123"}"}' --query ARN --output text)
# The result in AWS is: {"username":"bolauder", "password":"HelloWorld", "{"username":"BoLauder", "password":"HelloWorld123"}"}


echo $ESO_SECRET_ARN

# View the bucket to make sure it's correct
aws secretsmanager get-secret-value --secret-id $ESO_SECRET_ARN


# Create IAM policy
cat << EOF > eso-actions-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": "$ESO_SECRET_ARN",
            "Effect": "Allow"
        }
    ]
}
EOF

# Note, in the above policy, I replaced:
# This: "Resource": "arn:aws:secretsmanager:$REGION:$AWS_ACCOUNT_ID:$ESO_SECRET_BUCKET:*",
# With: "Resource": "$ESO_SECRET_ARN",
# To allow access to all secrets: 
            "Resource": "*",


# Verify variables
cat eso-actions-policy.json

# Create policy ARN
ESO_ACTIONS_POLICY_ARN=$(aws --region "$REGION" --query Policy.Arn --output text iam create-policy --policy-name "$AWS_SECRETS_POLICY_NAME"  --policy-document file://eso-actions-policy.json)
echo $ESO_ACTIONS_POLICY_ARN

# Create IAM Role trust policy
# NOTE: For testing, to allow all service accounts from all namespaces, you can change to
#     "StringLike" : {"${OIDC_ENDPOINT}:sub": ["system:serviceaccount:*:*"]}
# WARNING!! Don't copy the above line after creating the file or the variable OIDC_ENDPOINT isn't replaced

cat << EOF > eso-trust-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::$AWS_ACCOUNT_ID:oidc-provider/${OIDC_ENDPOINT}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {"${OIDC_ENDPOINT}:sub": ["system:serviceaccount:${USER_NAMESPACE}:${SA_NAME}"]}
            }
        }
    ]
}
EOF

# Verify variables
cat eso-trust-policy.json

# Create IAM role
ESO_ROLE_ARN=$(aws iam create-role --role-name "$AWS_SECRETS_POLICY_NAME" --assume-role-policy-document file://eso-trust-policy.json --query Role.Arn --output text)
echo $ESO_ROLE_ARN

# Attach the role to the policy
aws iam attach-role-policy --role-name "$AWS_SECRETS_POLICY_NAME" --policy-arn $ESO_ACTIONS_POLICY_ARN

# Verify attachment
aws iam list-attached-role-policies --role-name "$AWS_SECRETS_POLICY_NAME" --output text
```

## Deploy Operator and Instance
```
oc apply -k aws_secrets_integration/external-secrets-operator/operator/overlays/stable
oc apply -k aws_secrets_integration/external-secrets-operator/instance/overlays/default
```

## Create OpenShift resources
```
# Update values in aws_secrets_integration/external-secrets-operator/store/overlays/dev/kustomization.yaml
  # Especially
  # - ServiceAccount /metadata/annotations/eks.amazonaws.com~1role-arn
  # - ExternalSecret /spec/data/0/remoteRef/key
  # - ExternalSecret /spec/data/0/remoteRef/property
  # - ExternalSecret /spec/data/0/secretKey

oc apply -k aws_secrets_integration/external-secrets-operator/store/overlays/dev

# Verify all
oc project abc-user-namespace
oc describe sa external-secrets-operator-sa | egrep "^Annotations"
oc get secretstore
oc get externalsecret
oc get secrets my-kubernetes-secret -o json | jq -r .data.$KEY1 | base64 -d; echo
oc get secrets my-kubernetes-secret -o json | jq -r .data.$KEY2 | base64 -d; echo
oc get secrets my-kubernetes-secret -o json | jq -r .data.$KEY3 | base64 -d; echo

# Verify Service Account
oc describe sa external-secrets-operator-sa -n external-secrets | egrep "^Annotations"
# Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::942823120101:role/ocp-access-to-aws-secrets


# Verify Secret Store
oc get secretstore -n external-secrets
# NAME                  AGE   STATUS   CAPABILITIES   READY
# mystore   21s   Valid    ReadWrite      True

# Verify secret
oc get externalsecret -n external-secrets # Probably need to create this in a user namespace
# NAME       STORE     FRESH INTERVAL     STATUS         READY
# mysecret   mystore   1m                 SecretSynced   True


# Check local secret
oc get secrets my-kubernetes-secret -n external-secrets -o json | jq -r .data.password | base64 -d; echo
# {"username":"bolauder", "password":"HelloWorld"}

oc get secrets my-kubernetes-secret -n external-secrets -o json | jq -r .data.$KEY1 | base64 -d; echo
oc get secrets my-kubernetes-secret -n external-secrets -o json | jq -r .data.username| base64 -d; echo
bolauder

oc get secrets my-kubernetes-secret -n external-secrets -o json | jq -r .data.$KEY2 | base64 -d; echo
oc get secrets my-kubernetes-secret -n external-secrets -o json | jq -r .data.password | base64 -d; echo
HelloWorld

# Use the secret in a deployment
# NOTE: This example needs to be modified to fit the above.
apiVersion: apps/v1
kind: Deployment
(...)
      containers:
        - name: example-app-prod
          image: [yourimage]
          env:
            # Inject variables from a Kuberetes secret
            - name: secret-variables
              valueFrom:
                secretKeyRef:
                  name: my-kubernetes-secret
                  key: password


For every 1hr it refreshes and updates the secrets from the SecretStore.
It fetches the specified secret from SecretStore and stores it in the target secret.
```

# Cleanup
```
oc delete -k aws_secrets_integration/external-secrets-operator/store/overlays/dev
oc delete -k aws_secrets_integration/external-secrets-operator/instance/overlays/default
oc delete -k aws_secrets_integration/external-secrets-operator/operator/overlays/stable
oc delete csv $(oc get csv -n openshift-operators -o name | grep external-secrets)
oc delete project external-secrets
```

