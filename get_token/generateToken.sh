generateToken() {
  tmpfile="$(tempfile)"
  curl -s \
    -D "$tmpfile" \
    --insecure \
#    -u "$OC_USER:$OC_PASSWORD" \
    -u "bolauder:Bolauder-password-123" \
#    "${OC_BASEURL}oauth/authorize?response_type=token&client_id=openshift-browser-client" || return $?
    "bosez123.qzzw.p1.openshiftapps.com/oauth/authorize?response_type=token&client_id=openshift-browser-client" || return $?

  token="$(grep '^location' "$tmpfile")"
  rm -f "$tmpfile"
  token="${token#*access_token=}"
  token="${token%%&*}"
  echo "$token"
}

token=$(generateToken)
oc login --token=$token