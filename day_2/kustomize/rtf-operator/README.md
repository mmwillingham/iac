# For the secret

# Need to identify best way of providing secret data. Manual method is:

# oc create secret docker-registry rtf-pull-secret \
# --namespace rtf \
# --docker-server=<docker_registry_url> \
# --docker-username=<docker_registry_username> \
# --docker-password=<docker_ registry_password>

```
RTF_IMAGE_REGISTRY_ENDPOINT="rtf-runtime-registry.kprod.msap.io",
RTF_IMAGE_REGISTRY_USER="<redacted>",
RTF_IMAGE_REGISTRY_PASSWORD="<redacted>"
# Generate the auth
echo -n "$RTF_IMAGE_REGISTRY_USER:$RTF_IMAGE_REGISTRY_PASSWORD" | base64 -w0

# for example
echo -n "r7nHc112345/us-east-1/e89f17511ed54615bthisisasample:299536b2C3cf46CA9thisisasample" | base64 -w0
cjduSGMxZmUyYS91cy1lYXN0LTEvZTg01234567890WQ1NDYxNWI2MDk0ODIxMTQ1OGYxZmM6Mjk5NTM2YjJDM2NmNDZDQTlithisisasample=

# Build dockerconfig.json
cat <<EOF > dockerconfig.json
"rtf-runtime-registry.kprod.msap.io": {
      "username": "r7nHc112345/us-east-1/e89f17511ed54615bthisisasample",
      "password": "299536b2C3cf46CA9thisisasample",
      "auth": "cjduSGMxZmUyYS91cy1lYXN0LTEvZTg01234567890WQ1NDYxNWI2MDk0ODIxMTQ1OGYxZmM6Mjk5NTM2YjJDM2NmNDZDQTlithisisasample==",
      "email": "none"
    }
EOF

IMAGE_PULL_SECRET=$(cat dockerconfig.json | base64 -w0);

Create the secret:
cat <<EOF > rtf-pull-secret.yaml
apiVersion: v1
type: kubernetes.io/dockerconfigjson
kind: Secret
metadata:
  name: rtf-pull-secret
data:
  .dockerconfigjson: "$IMAGE_PULL_SECRET"
EOF

{"auths":{"rtf-runtime-registry.kprod.msap.io":{"username":"r7nHclfe2a/us-east-1/aa2f30932cc04d198d48727a69aaab22","password":"0244172925Bb461698F5147DcC7F40bB","auth":"cjduSGNsZmUyYS91cy1lYXN0LTEvYWEyZjMwOTMyY2MwNGQxOThkNDg3MjdhNjlhYWFiMjI6MDI0NDE3MjkyNUJiNDYxNjk4RjUxNDdEY0M3RjQwYkI="}}}