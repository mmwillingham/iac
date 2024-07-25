# Create External Ingress
```
export SECOND_IC=extapps-ingress
export CUSTOM_DOMAIN=extapps.bosez-20240710.o5fq.p1.openshiftapps.com
echo $SECOND_IC, $CUSTOM_DOMAIN

# Watch status until it is Available and Admitted
oc describe -n openshift-ingress-operator ingresscontroller/$SECOND_IC
oc logs -n openshift-ingress-operator deployments/ingress-operator -f | grep $SECOND_IC

# Verify the new load balancer used for the new ingress controller 
oc get svc -n openshift-ingress | egrep "router-default|router-$SECOND_IC|NAME"

# Store the new LB into a variable
# Will use for cert later
NEW_LB=$(oc get svc -n openshift-ingress "router-$SECOND_IC" -ojson | jq .status.loadBalancer.ingress[].hostname)
echo $NEW_LB

$ oc get svc -n openshift-ingress
NAME                                    TYPE           CLUSTER-IP       EXTERNAL-IP                                                                     PORT(S)                      AGE
router-custom-domain-ingress            LoadBalancer   172.30.81.166    a29e9114a7e1f460fa752d2c4eabc07e-f43d8c858dfb40cd.elb.us-east-2.amazonaws.com   80:32013/TCP,443:32329/TCP   7d3h
router-default                          LoadBalancer   172.30.83.164    ad39ad99db871433db728efb7f31fa46-2bcbd57932ea953b.elb.us-east-2.amazonaws.com   80:31819/TCP,443:32727/TCP   15d
router-extapps-ingress                  LoadBalancer   172.30.206.162   a817326d51ba04816b17e68fb7d86151-15e344966f2f8cc5.elb.us-east-2.amazonaws.com   80:30999/TCP,443:32029/TCP   73s
router-internal-custom-domain-ingress   ClusterIP      172.30.246.18    <none>                                                                          80/TCP,443/TCP,1936/TCP      7d3h
router-internal-default                 ClusterIP      172.30.143.62    <none>                                                                          80/TCP,443/TCP,1936/TCP      15d
router-internal-extapps-ingress         ClusterIP      172.30.218.100   <none>                                                                          80/TCP,443/TCP,1936/TCP      73s
mwilling@mwilling-thinkpadp1gen4i:/tmp$ 

```