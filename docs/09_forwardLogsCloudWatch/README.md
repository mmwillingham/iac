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

## Export Environment Variables
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

## Prepare AWS (roles and policies)
```
# Create an Identity Access Management (IAM) policy for logging

POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='RosaCloudWatch'].{ARN:Arn}" --output text)
if [[ -z "${POLICY_ARN}" ]]; then
cat << EOF > ${SCRATCH}/policy.json
{
  "Version": "2012-10-17",
  "Statement": [
     {
           "Effect": "Allow",
           "Action": [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:DescribeLogGroups",
              "logs:DescribeLogStreams",
              "logs:PutLogEvents",
              "logs:PutRetentionPolicy"
           ],
           "Resource": "arn:aws:logs:*:*:*"
     }
]
}
EOF

POLICY_ARN=$(aws iam create-policy --policy-name "RosaCloudWatch" \
--policy-document file:///${SCRATCH}/policy.json --query Policy.Arn --output text)
fi
echo ${POLICY_ARN}

# Create an IAM role trust policy for the cluster - and a role

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
         "${OIDC_ENDPOINT}:sub": "system:serviceaccount:openshift-logging:logcollector"
       }
     }
   }]
}
EOF

ROLE_ARN=$(aws iam create-role --role-name "${ROSA_CLUSTER_NAME}-RosaCloudWatch" \
      --assume-role-policy-document file://${SCRATCH}/trust-policy.json \
      --query Role.Arn --output text)
echo ${ROLE_ARN}

# Attach the policy to the role
aws iam attach-role-policy --role-name "${ROSA_CLUSTER_NAME}-RosaCloudWatch" --policy-arn ${POLICY_ARN}
```

## Configure OpenShift
### Install Cluster Logging operator
```
# Create/Apply namespace, operator group, and subscription

cat << EOF > ${SCRATCH}/cluster-logging.yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-logging
  annotations:
    openshift.io/node-selector: ""
  labels:
    openshift.io/cluster-monitoring: "true"
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: cluster-logging
  namespace: openshift-logging
spec:
  targetNamespaces:
  - openshift-logging
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/cluster-logging.openshift-logging: ""
  name: cluster-logging
  namespace: openshift-logging
spec:
  channel: stable
  name: cluster-logging
  installPlanApproval: Automatic
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

oc apply -f ${SCRATCH}/cluster-logging.yaml

# Verify operator is running
oc get csv -n openshift-logging | grep cluster-logging

# Create a secret

cat << EOF > ${SCRATCH}/cluster-logging-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudwatch-credentials
  namespace: openshift-logging
stringData:
  role_arn: $ROLE_ARN
EOF

oc apply -f ${SCRATCH}/cluster-logging-secret.yaml
```

### Configure cluster logging
```
# Create ClusterLogForwarder

cat << EOF > ${SCRATCH}/cluster-logging-forwarder.yaml
apiVersion: "logging.openshift.io/v1"
kind: ClusterLogForwarder
metadata:
  name: instance
  namespace: openshift-logging
spec:
  outputs:
    - name: cw
      type: cloudwatch
      cloudwatch:
        groupBy: namespaceName
        groupPrefix: rosa-${ROSA_CLUSTER_NAME}
        region: ${REGION}
      secret:
        name: cloudwatch-credentials
  pipelines:
    - name: to-cloudwatch
      inputRefs:
        - infrastructure
        - audit
        - application
      outputRefs:
        - cw
EOF

oc apply -f ${SCRATCH}/cluster-logging-forwarder.yaml

# Create ClusterLogging instance
# Note. The documentation has, but it is deprecated. I fixed in the yaml.
#  spec:
#    collection:
#      logs:
#         type: vector

cat << EOF > ${SCRATCH}/cluster-logging-instance.yaml
apiVersion: logging.openshift.io/v1
kind: ClusterLogging
metadata:
  name: instance
  namespace: openshift-logging
spec:
  collection:
    type: vector
  managementState: Managed
EOF

oc apply -f ${SCRATCH}/cluster-logging-instance.yaml
```

### Validation for logging
#### Create sample application
```
oc new-project sample-app
oc new-app --template=openshift/nginx-example
oc get pods
```
#### Locate logs in AWS using CLI (with example log names)
```
# List log groups
aws logs describe-log-groups --log-group-name-prefix rosa-${ROSA_CLUSTER_NAME} | awk '{print $2}'

# Details of log groups
aws logs describe-log-groups --log-group-name-prefix rosa-${ROSA_CLUSTER_NAME}

# Get log streams for the sample-app log group
aws logs describe-log-streams --log-group-name rosa-bosez-gdabs.sample-app

# Get events for a log stream
aws logs get-log-events --log-group-name rosa-bosez-gdabs.sample-app --log-stream-name kubernetes.var.log.pods.sample-app_nginx-example-1-deploy_2bdeb45a-e25b-4433-a60a-61dd18d97a66.deployment.0.log
```

#### Delete the sample application
```
oc delete project sample-app
```

### Configure event logging
```
# Create a template for the Event Router
cat << EOF > eventrouter.yaml
apiVersion: template.openshift.io/v1
kind: Template
metadata:
  name: eventrouter-template
  annotations:
    description: "A pod forwarding kubernetes events to OpenShift Logging stack."
    tags: "events,EFK,logging,cluster-logging"
objects:
  - kind: ServiceAccount
    apiVersion: v1
    metadata:
      name: eventrouter
      namespace: ${NAMESPACE}
  - kind: ClusterRole 
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: event-reader
    rules:
    - apiGroups: [""]
      resources: ["events"]
      verbs: ["get", "watch", "list"]
  - kind: ClusterRoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: event-reader-binding
    subjects:
    - kind: ServiceAccount
      name: eventrouter
      namespace: ${NAMESPACE}
    roleRef:
      kind: ClusterRole
      name: event-reader
  - kind: ConfigMap
    apiVersion: v1
    metadata:
      name: eventrouter
      namespace: ${NAMESPACE}
    data:
      config.json: |-
        {
          "sink": "stdout"
        }
  - kind: Deployment
    apiVersion: apps/v1
    metadata:
      name: eventrouter
      namespace: ${NAMESPACE}
      labels:
        component: "eventrouter"
        logging-infra: "eventrouter"
        provider: "openshift"
    spec:
      selector:
        matchLabels:
          component: "eventrouter"
          logging-infra: "eventrouter"
          provider: "openshift"
      replicas: 1
      template:
        metadata:
          labels:
            component: "eventrouter"
            logging-infra: "eventrouter"
            provider: "openshift"
          name: eventrouter
        spec:
          serviceAccount: eventrouter
          containers:
            - name: kube-eventrouter
              image: ${IMAGE}
              imagePullPolicy: IfNotPresent
              resources:
                requests:
                  cpu: ${CPU}
                  memory: ${MEMORY}
              volumeMounts:
              - name: config-volume
                mountPath: /etc/eventrouter
              securityContext:
                allowPrivilegeEscalation: false
                capabilities:
                  drop: ["ALL"]
          securityContext:
            runAsNonRoot: true
            seccompProfile:
              type: RuntimeDefault
          volumes:
          - name: config-volume
            configMap:
              name: eventrouter
parameters:
  - name: IMAGE
    displayName: Image
    value: "registry.redhat.io/openshift-logging/eventrouter-rhel9:v0.4"
  - name: CPU
    displayName: CPU
    value: "100m"
  - name: MEMORY
    displayName: Memory
    value: "128Mi"
  - name: NAMESPACE
    displayName: Namespace
    value: "openshift-logging"
EOF

# Make sure these variables are not replaced in the file (they should remain as variables, not with values. The variables will be replaces with the parameters at the bottom of the file in the next command.
# ${NAMESPACE}, ${IMAGE}, ${CPU}, ${MEMORY}

# Process the file:
oc process -f eventrouter.yaml | oc apply -n openshift-logging -f -

# Verify it is running:
oc get pod -l component=eventrouter
```

### Validation steps for event logs
#### Check OpenShift for recent events
`oc get events -A --sort-by='.lastTimestamp'`

#### Check OpenShift logs from new Event Router pod
`oc -n openshift-logging logs $(oc get pods --selector  component=eventrouter -o name -n openshift-logging)`

#### List AWS log groups (if you have yq cli, otherwise use other tools)
`aws logs describe-log-groups --no-cli-pager --output yaml | yq .logGroups[].logGroupName`

#### Set variable of infrastructure log group
`INFRASTRUCTURELG=$(aws logs describe-log-groups --output text --query "logGroups[?logGroupName.contains(@, 'infrastructure')].logGroupName")`

`echo ${INFRASTRUCTURELG}`

#### Show events in AWS CloudWatch (events are in the infrastructure log group)
`aws logs describe-log-streams --log-group-name ${INFRASTRUCTURELG}`

#### Set variable for eventrouter logstream
`EVENTROUTERLS=$(aws logs describe-log-streams --log-group-name ${INFRASTRUCTURELG} --output text --query "logStreams[?logStreamName.contains(@, 'eventrouter')].logStreamName")`

`echo ${EVENTROUTERLS}`

#### Get log events for eventrouter logstream
`aws logs get-log-events --log-group-name ${INFRASTRUCTURELG} --log-stream-name ${EVENTROUTERLS} --output json`

#### Same as above with start and end times
```
aws logs get-log-events \
--log-group-name ${INFRASTRUCTURELG} \
--log-stream-name ${EVENTROUTERLS} \
--start-time `date -d 2015-11-10T14:50:00Z +%s`000 \
--end-time `date -d 2025-11-10T14:50:00Z +%s`000 \
--output json
```

#### Same as above with start and end times and filter for "extract"
#### NOTE: This command can search multple logs
```
aws logs filter-log-events \
--log-group-name ${INFRASTRUCTURELG} \
--log-stream-names ${EVENTROUTERLS} \
--start-time `date -d 2015-11-10T14:50:00Z +%s`000 \
--end-time `date -d 2025-11-10T14:50:00Z +%s`000 \
--filter-pattern extract \
--output json
```
