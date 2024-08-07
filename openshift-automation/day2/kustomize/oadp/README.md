# OADP on ROSA
https://docs.openshift.com/rosa/rosa_backing_up_and_restoring_applications/backing-up-applications.html

# Prepare AWS credentials
```
oc login...
export CLUSTER_NAME=bosez-20240710
export ROSA_CLUSTER_ID=$(rosa describe cluster -c ${CLUSTER_NAME} --output json | jq -r .id)
export REGION=$(rosa describe cluster -c ${CLUSTER_NAME} --output json | jq -r .region.id)
export OIDC_ENDPOINT=$(oc get authentication.config.openshift.io cluster -o jsonpath='{.spec.serviceAccountIssuer}' | sed 's|^https://||')
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export CLUSTER_VERSION=$(rosa describe cluster -c ${CLUSTER_NAME} -o json | jq -r .version.raw_id | cut -f -2 -d '.')
export ROLE_NAME="${CLUSTER_NAME}-openshift-oadp-aws-cloud-credentials"
export SCRATCH="/tmp/${CLUSTER_NAME}/oadp"
mkdir -p ${SCRATCH}
echo "Cluster ID: ${ROSA_CLUSTER_ID}, Region: ${REGION}, OIDC Endpoint: ${OIDC_ENDPOINT}, AWS Account ID: ${AWS_ACCOUNT_ID}"
```
## Create an IAM policy to allow access to S3
```
if [[ -z "${POLICY_ARN}" ]]; then
cat << EOF > ${SCRATCH}/policy.json 
{
"Version": "2012-10-17",
"Statement": [
  {
    "Effect": "Allow",
    "Action": [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:PutBucketTagging",
      "s3:GetBucketTagging",
      "s3:PutEncryptionConfiguration",
      "s3:GetEncryptionConfiguration",
      "s3:PutLifecycleConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "ec2:DescribeSnapshots",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumeAttribute",
      "ec2:DescribeVolumesModifications",
      "ec2:DescribeVolumeStatus",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot"
    ],
    "Resource": "*"
  }
 ]}
EOF

POLICY_ARN=$(aws iam create-policy --policy-name "RosaOadpVer1" \
--policy-document file:///${SCRATCH}/policy.json --query Policy.Arn \
--tags Key=rosa_openshift_version,Value=${CLUSTER_VERSION} Key=rosa_role_prefix,Value=ManagedOpenShift Key=operator_namespace,Value=openshift-oadp Key=operator_name,Value=openshift-oadp \
--output text)
fi
echo ${POLICY_ARN}
```
## Create an IAM role trust policy for the cluster, a role, and attach.
```
# Policy
cat <<EOF > ${SCRATCH}/trust-policy.json
{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_ENDPOINT}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_ENDPOINT}:sub": [
            "system:serviceaccount:openshift-adp:openshift-adp-controller-manager",
            "system:serviceaccount:openshift-adp:velero"]
        }
      }
    }]
}
EOF

cat ${SCRATCH}/trust-policy.json

# Role
ROLE_ARN=$(aws iam create-role --role-name "${ROLE_NAME}" --assume-role-policy-document file://${SCRATCH}/trust-policy.json --tags Key=rosa_cluster_id,Value=${ROSA_CLUSTER_ID} Key=rosa_openshift_version,Value=${CLUSTER_VERSION} Key=rosa_role_prefix,Value=ManagedOpenShift Key=operator_namespace,Value=openshift-adp Key=operator_name,Value=openshift-oadp --query Role.Arn --output text)

echo ${ROLE_ARN}

# Attach
aws iam attach-role-policy --role-name "${ROLE_NAME}" --policy-arn ${POLICY_ARN}

# # Verify attachment
aws iam list-attached-role-policies --role-name "${ROLE_NAME}" --output text
```
# Install OADP Operator and Instances
## Install Operator
NOTE: Prior to OCP 4.15, you had to create a secret before installing the operator. This is not required with 4.15+, but you must provide the ROLE_ARN during operator installation. We will use the 4.15+ process. For OCP 4.14-, see the docs.
```
oc apply -k oadp/operator/overlays/dev
```
## Install OADP Cloud Storage, Data Protection Application, and Backup
```
oc apply -k oadp/instance/overlays/dev
```
## Create Backup
```
oc apply -k oadp/backup/overlays/dev
```
## Verify backup and list objects
```
# OpenShift
oc get backup -n openshift-adp
# assume backup name is backup-manual-user-namespaces
oc describe backup backup-manual-user-namespaces -n openshift-adp

# AWS
aws s3api list-objects --bucket bosez-20240710-oadp --output table

# Velero (Details of the specific kubernetes resources backed up)
alias velero='oc -n openshift-adp exec deployment/velero -c velero -it -- ./velero'
velero backup describe backup-manual-user-namespaces --details
```

# Restore

# Troubleshooting
```
oc get backup -n openshift-adp
# assume backup name is backup-user-namespaces
oc describe backup backup-user-namespaces -n openshift-adp
oc logs -f deploy/velero -n openshift-adp
alias velero='oc -n openshift-adp exec deployment/velero -c velero -it -- ./velero'
velero backup describe backup-user-namespaces --details
velero backup logs backup-user-namespaces
# If everything works on active cluster, and passive says the cloudstorage and dpa are available, but it doesn't list the backups, check the velero pod logs. May say something like this
# time="2023-09-25T18:34:56Z" level=error msg="Error getting backup metadata from backup store" backup=acm-resources-generic-schedule-20230925173327 backupLocation=dl-rosa10-2s-dpa-1 controller=backup-sync error="rpc error: code = Unknown desc = error getting object backups/acm-resources-generic-schedule-20230925173327/velero-backup.json: AccessDenied: User: arn:aws:sts::693101272312:assumed-role/delegate-admin-rhacm-bkp-restore-us-west-2/1695666895356145449 is not authorized to perform: kms:Decrypt on resource: arn:aws:kms:us-east-1:693101272312:key/dfa432ed-0f3a-45a0-b545-617cadb64911 because no identity-based policy allows the kms:Decrypt action\n\tstatus code: 403, request id: 4MAQKWC0BMJXSCJ8, host id: kdjIg/Iiz/8kGodFriPLyu837ouYE/Mewwynv0pfrw+KVtMB4g+PPoTREnEPlG5eWVKTtNs5rag=" error.file="/remote-source/velero/app/pkg/persistence/object_store.go:294" error.function="github.com/vmware-tanzu/velero/pkg/persistence.(*objectBackupStore).GetBackupMetadata" logSource="/remote-source/velero/app/pkg/controlle...
# Customer switched and used same KMS Key ID as was used in primary AWS region. Then it worked.
```