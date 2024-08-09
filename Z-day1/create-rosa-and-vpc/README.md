## Deploy a ROSA Cluster Via VCS Driven Workflow
In this deployment model, the Terraform configuration for deploying ROSA clusters are stored in a private GitHub repository.

### Configure the ROSA OpenShift Version
Update the `prod.auto.tfvars` file with the desired OpenShift version. Available versions can be found using the following:
```
rosa login
rosa list versions | head
```
After updating the file, push the changes to GitHub. This will trigger a new run in Terraform Cloud.

### Terraform Run Monitoring
After approving the run, you can monitor the installation log in the TF Cloud UI and using the following:
```
rosa list clusters
rosa logs install -c <cluster_name> --watch
```

### Cluster Admin Login
Obtain the OpenShift API endpoint.
```
rosa describe cluster -c <cluster_name>
rosa describe cluster -c <cluster_name> -o json | jq -r .api.url
```
Login to the cluster using the URL obtained above. 
```
URL=`rosa describe cluster -c <cluster_name> -o json | jq -r .api.url`
oc login $URL --username <admin_username> --password <admin_password> --insecure-skip-tls-verify=true
```
Use the following to obtain the console URL.
```
rosa describe cluster -c <cluster_name> -o json | jq -r .console.url
```

### Upgrading a ROSA Cluster
Update the `prod.auto.tfvars` file with the desired OpenShift version and push the changes to GitHub. This will trigger a new run in Terraform Cloud. After approving the run, the scheduled upgrade can be monitored using the following:
```
rosa list upgrades -c <cluster_name>
rosa describe cluster -c <cluster_name> -o json | jq .scheduledUpgrade
rosa describe cluster -c <cluster_name> -o json | jq .version
rosa describe cluster -c <cluster_name> -o json | jq .state
```

### Uninstall the ROSA Cluster Via VCS Driven Workflow
Comment out resources in `main.tf` and push the changes to GitHub. This will trigger a new run in Terraform Cloud. After approving the run, you can monitor the uninstall in the TF Cloud UI and using the following:
```
rosa describe cluster -c <cluster_name> -o json | jq .state
rosa logs uninstall -c <cluster_name> --watch
```