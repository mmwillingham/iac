# Configure OpenShift to forward cluster logging to AWS CloudWatch

## References
https://docs.openshift.com/rosa/cloud_experts_tutorials/cloud-experts-rosa-cloudwatch-sts.html
https://docs.openshift.com/rosa/observability/logging/cluster-logging.html
https://docs.openshift.com/rosa/observability/logging/log_collection_forwarding/cluster-logging-eventrouter.html
https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Working-with-log-groups-and-streams.html

NOTE: By default, log data is stored in CloudWatch Logs indefinitely. However, you can configure how long to store log data in a log group. Any data older than the current retention setting is deleted. You can change the log retention for each log group at any time.

## Prerequisites
- ROSA cluster
- Cluster-admin access
- CLI: jq, aws, oc, rosa, jq (optional)
- AWS access to create roles and policies

## Prepare Environment
 NOTE: Adjust steps as needed for DHHS specifics

```
oc login -u <username> -p <password> <API URL>
export ROSA_CLUSTER_NAME=$(oc get infrastructure cluster -o=jsonpath="{.status.infrastructureName}"  | sed 's/-[a-z0-9]\{5\}$//')
export REGION=$(rosa describe cluster -c ${ROSA_CLUSTER_NAME} --output json | jq -r .region.id)
export OIDC_ENDPOINT=$(oc get authentication.config.openshift.io cluster -o json | jq -r .spec.serviceAccountIssuer | sed  's|^https://||')
export AWS_ACCOUNT_ID=`aws sts get-caller-identity --query Account --output text`
export AWS_PAGER=""
export SCRATCH="/tmp/${ROSA_CLUSTER_NAME}/clf-cloudwatch-sts"
mkdir -p ${SCRATCH}

echo "Cluster: ${ROSA_CLUSTER_NAME}, Region: ${REGION}, AWS Account ID: ${AWS_ACCOUNT_ID}", OIDC Endpoint: ${OIDC_ENDPOINT}
```


