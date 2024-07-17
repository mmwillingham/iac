# Cert Manager on ROSA
# Setup AWS
```
# Set variables
export DOMAIN=apps.bosez-20240710.o5fq.p1.openshiftapps.com
export EMAIL=bolauder88@gmail.com
export AWS_PAGER=""
export CLUSTER=$(oc get infrastructure cluster -o=jsonpath="{.status.infrastructureName}"  | sed 's/-[a-z0-9]\{5\}$//')
export OIDC_ENDPOINT=$(oc get authentication.config.openshift.io cluster -o json | jq -r .spec.serviceAccountIssuer | sed  's|^https://||')
export REGION=$(oc get infrastructure cluster -o=jsonpath="{.status.platformStatus.aws.region}")
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export SCRATCH="/tmp/${CLUSTER}/dynamic-certs"
mkdir -p ${SCRATCH}

echo "Cluster: ${CLUSTER}"
echo "Region: ${REGION}"
echo "OIDC Endpoint: ${OIDC_ENDPOINT}"
echo "AWS Account ID: ${AWS_ACCOUNT_ID}"

# Retrieve the Amazon Route 53 public hosted zone ID:
# NOTE: This command looks for a public hosted zone that matches the custom domain you specified earlier as the DOMAIN environment variable.
# You can manually specify the Amazon Route 53 public hosted zone by running export ZONE_ID=<zone_ID>, replacing <zone_ID> with your specific 
# Amazon Route 53 public hosted zone ID.

export ZONE_ID=$(aws route53 list-hosted-zones-by-name --output json --dns-name "${DOMAIN}." --query 'HostedZones[0]'.Id --out text | sed 's/\/hostedzone\///')

# Create an AWS IAM policy document for the cert-manager Operator that provides the ability to update only the specified public hosted zone
cat <<EOF > "${SCRATCH}/cert-manager-policy.json"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:GetChange",
      "Resource": "arn:aws:route53:::change/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/${ZONE_ID}"
    },
    {
      "Effect": "Allow",
      "Action": "route53:ListHostedZonesByName",
      "Resource": "*"
    }
  ]
}
EOF

# Create the IAM policy using the file you created in the previous step
POLICY_ARN=$(aws iam create-policy --policy-name "${CLUSTER}-cert-manager-policy" --policy-document file://${SCRATCH}/cert-manager-policy.json --query 'Policy.Arn' --output text)

echo $POLICY_ARN

# Create an AWS IAM trust policy for the cert-manager Operator
cat <<EOF > "${SCRATCH}/trust-policy.json"
{
 "Version": "2012-10-17",
 "Statement": [
 {
 "Effect": "Allow",
 "Condition": {
   "StringEquals" : {
     "${OIDC_ENDPOINT}:sub": "system:serviceaccount:cert-manager:cert-manager"
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

cat ${SCRATCH}/trust-policy.json

# Create an IAM role for the cert-manager Operator using the trust policy
ROLE_ARN=$(aws iam create-role --role-name "${CLUSTER}-cert-manager-operator" --assume-role-policy-document "file://${SCRATCH}/trust-policy.json" --query Role.Arn --output text)

echo $ROLE_ARN

# Attach the permissions policy to the role
aws iam attach-role-policy --role-name "${CLUSTER}-cert-manager-operator" --policy-arn ${POLICY_ARN}

# Verify attachment
aws iam list-attached-role-policies --role-name "${CLUSTER}-cert-manager-operator" --output text
```

# Setup OpenShift
## Install OADP Operator and Instances
### Install Operator
```
NOTE: It's now possible to provide ROLE_ARN during operator installation.

oc apply -k cert-manager/operator/overlays/dev
```
### Install XXX
```
oc apply -k cert-manager/instance/overlays/dev
```