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
- CLI:
  jq
  aws
  oc
  rosa
- AWS access to create roles and policies

