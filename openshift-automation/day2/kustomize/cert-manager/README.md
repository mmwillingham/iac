# Cert Manager on ROSA
https://docs.openshift.com/rosa/cloud_experts_tutorials/cloud-experts-dynamic-certificate-custom-domain.html#cloud-experts-dynamic-certificate-custom-domain-create-cd-ingress-con

# Setup AWS
```
# Set variables
export DOMAIN=*.extapps.bosez-20240710.o5fq.p1.openshiftapps.com
NOTE: May need to change this to: DOMAIN=extapps.bosez-20240710.o5fq.p1.openshiftapps.com
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
# IMPORTANT NOTE: This command looks for a public hosted zone that 
matches the custom domain you specified earlier as the DOMAIN environment variable.
# You can manually specify the Amazon Route 53 public hosted zone by running export ZONE_ID=<zone_ID>, replacing <zone_ID> with your specific 
# Amazon Route 53 public hosted zone ID.

export ZONE_ID=$(aws route53 list-hosted-zones-by-name --output json --dns-name "${DOMAIN}." --query 'HostedZones[0]'.Id --out text | sed 's/\/hostedzone\///')

# In my case, it picked up the wrong one. Run this to get a list of the zones and pick the public zone ("PrivateZone": false) that isn't sandbox
aws route53 list-hosted-zones-by-name --output json
export ZONE_ID=<correct zone>

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
## Install Operator and Instances

### Install Operator
```
NOTE: It's now possible to provide ROLE_ARN during operator installation.

oc apply -k cert-manager/operator/overlays/dev
```
### Install ClusterIssuers and custom domain Ingress Controller
```
oc apply -k cert-manager/instance/overlays/dev

# NOTE: It takes a few minutes for this certificate to be issued by Let’s Encrypt. If it takes longer than 5 minutes, to see any issues reported by cert-manager:

# Verify
oc get clusterissuer.cert-manager.io/letsencrypt-dev
oc -n openshift-ingress get certificate.cert-manager.io/custom-domain-ingress-cert
oc -n openshift-ingress describe certificate.cert-manager.io/custom-domain-ingress-cert
oc logs -n cert-manager $(oc get pods -n cert-manager | grep -v cain | grep -v web | grep -v NAME | awk '{print $1}')

# NOTE: This IngressController example will create an internet accessible Network Load Balancer (NLB) in your AWS account.
# To provision an internal NLB instead, set the .spec.endpointPublishingStrategy.loadBalancer.scope parameter to Internal 
# before creating the IngressController resource.

# Verify
oc -n openshift-ingress get service/router-custom-domain-ingress

# Check if it's Ready (it takes some time in provisioning)
export ELB_DNS=$(oc -n openshift-ingress get service/router-custom-domain-ingress -o=custom-columns=EXTIP:status.loadBalancer.ingress[0].hostname | grep -v EXTIP)
echo $ELB_DNS
a29e9114a7e1f460fa752d2c4eabc07e-f43d8c858dfb40cd.elb.us-east-2.amazonaws.com

# Never got this variable working: aws elbv2 describe-load-balancers | jq '.LoadBalancers[] | select(.DNSName == \"${ELB_DNS}\")' | jq .State

aws elbv2 describe-load-balancers | jq '.LoadBalancers[] | select(.DNSName == "a29e9114a7e1f460fa752d2c4eabc07e-f43d8c858dfb40cd.elb.us-east-2.amazonaws.com")' | jq .State

# Wait until it moves from provisioning to active

```

# Manual AWS step. How to automate???
```
# Prepare a document with the necessary DNS changes to enable DNS resolution for your custom domain Ingress Controller

INGRESS=$(oc -n openshift-ingress get service/router-custom-domain-ingress -ojsonpath="{.status.loadBalancer.ingress[0].hostname}")

# NOTE: Be careful with "*.${DOMAIN}" If you are using wildcard, you could end with "*.*.extapps.bosez-20240710.o5fq.p1.openshiftapps.com"

# For wildcards, the result should be: *.extapps.bosez-20240710.o5fq.p1.openshiftapps.com
# NOTE: This creates a CNAME. The default *.apps is an A alias.

cat << EOF > "${SCRATCH}/create-cname.json"
{
  "Comment":"Add CNAME to custom domain endpoint",
  "Changes":[{
      "Action":"CREATE",
      "ResourceRecordSet":{
        "Name": "${DOMAIN}",
      "Type":"CNAME",
      "TTL":30,
      "ResourceRecords":[{
        "Value": "${INGRESS}"
      }]
    }
  }]
}
EOF

cat ${SCRATCH}/create-cname.json

# Submit your changes to Amazon Route 53 for propagation
aws route53 change-resource-record-sets --hosted-zone-id ${ZONE_ID} --change-batch file://${SCRATCH}/create-cname.json

# Wait until it moves from pending to INSYNC (Check console. Couldn't find a CLI option for this.)

```

# Configuring dynamic certificates for custom domain routes
### IMPORTANT. The previous AWS step should be completed before proceeding.
### Image is here: ghcr.io/cert-manager/cert-manager-openshift-routes:0.5.0
### May need to open firewall to ghcr.io/cert-manager
```
oc apply -k cert-manager/app-prep/overlays/dev
oc -n cert-manager get pods | grep route
```

# Test with a sample app
```
oc new-project hello-world-cert
oc -n hello-world-cert new-app --image=docker.io/openshift/hello-openshift
echo $DOMAIN
# If it does not include *
oc -n hello-world-cert create route edge --service=hello-openshift hello-openshift-tls --hostname hello.${DOMAIN}

# If includes *:
export NEW_DOMAIN=$(echo ${DOMAIN} | sed s/\*.//)
echo $NEW_DOMAIN
oc -n hello-world-cert create route edge --service=hello-openshift hello-openshift-tls --hostname hello.${NEW_DOMAIN}



oc -n hello-world-cert create route edge --service=hello-openshift hello-openshift-tls --hostname hello.${DOMAIN}
oc -n hello-world-cert create route edge --service=hello-openshift hello-openshift-tls --hostname hello.extapps.bosez-20240710.o5fq.p1.openshiftapps.com
curl -I https://hello.extapps.bosez-20240710.o5fq.p1.openshiftapps.com
curl: (6) Could not resolve host: hello.extapps.bosez-20240710.o5fq.p1.openshiftapps.com
```

# Cleanup
# All in one - or see below for details
```
# Install here for convenience
oc apply -k cert-manager/operator/overlays/dev
oc apply -k cert-manager/instance/overlays/dev

oc delete -k cert-manager/instance/overlays/dev
oc delete -k cert-manager/operator/overlays/dev
oc delete project cert-manager
oc delete project cert-manager-operator
```