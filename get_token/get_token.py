import os
import json
import datetime
import warnings
import requests
from requests.auth import HTTPBasicAuth
from urllib.parse import urlparse, parse_qs

warnings.filterwarnings('ignore')

def print_json(j):
    print (json.dumps(j,indent=4,sort_keys=True))

# +----------------------------------------+
# | Set OCP credentials or source from ENV |
# +----------------------------------------+
#oc login -u bolauder -p Bolauder-password-123 https://api.bosez123.qzzw.p1.openshiftapps.com:6443
host = "oauth-openshift.apps.bosez123.qzzw.p1.openshiftapps.com"
user = "bolauder"
passwd = "Bolauder-password-123"
# user = os.environ["OCP_USER"]
# passwd = os.environ["OCP_PWD"]
# host = os.environ["OCP_OAUTH_HOST"]

port = 443
urlport = str(port)
ConnectTimeout = 5.0
headers = {'Content-Type': 'application/json','Accept':'application/json'}
ep = "/oauth/authorize"
client_id = "openshift-challenging-client"
response_type = "token"
url = ("https://" + host + ":" + urlport + ep + "?" + "client_id=" + client_id + "&" + "response_type=" + response_type)
print(url)

response = requests.get(url, verify=False, auth=(user, passwd), timeout=ConnectTimeout, allow_redirects=False)
now_date = datetime.datetime.now()

response.raise_for_status()

if response.status_code == 302:
    url_parts = urlparse(response.headers['Location'])
    fragment_parts = parse_qs(url_parts.fragment)    
    access_token = fragment_parts['access_token'][0]
    expires_in = fragment_parts['expires_in'][0]    
    expiry_date = now_date + datetime.timedelta(seconds=86400)
    
else:
    raise RuntimeError("Didn't get the expected 302 redirect")

print(access_token)
#print(expiry_date)
