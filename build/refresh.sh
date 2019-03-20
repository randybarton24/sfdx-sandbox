echo "Getting login token..."
curlRequest1=$(curl --form client_id=$CONSUMER_KEY \
     --form client_secret=$CONSUMER_SECRET \
     --form grant_type=password \
     --form username=$USERNAME\
     --form password=$PASSWORD \
      https://login.salesforce.com/services/oauth2/token)

authToken=$(jq -r '.access_token' <<<"$curlRequest1")
instanceURL=$(jq -r '.instance_url' <<<"$curlRequest1")

echo "authToken: $authToken"
echo "instanceURL: $instanceURL"

arraySandboxes=('dev1' 'dev2' 'dev3')
echo "Query sandbox ids..."
curlRequest2=$(curl -H "Authorization: Bearer ${authToken}"  \
      "${instanceURL}/services/data/v42.0/tooling/query?q=SELECT+id,sourceid,sandboxname+from+sandboxinfo+where+sandboxname+in%20('dev1'%2C'dev2'%2C'dev3')")

echo "Query active work requests..."
curlRequest3=$(curl -H "Authorization: Bearer ${authToken}" \
      -H "Content-Type: application/json"  \
      "${instanceURL}/services/data/v43.0/query?q=SELECT+Id%2CName%2Cagf__Scheduled_Build_Name__c+FROM+agf__ADM_Work__c+WHERE+agf__Scheduled_Build_Name__c+%21%3D+null+AND+%28NOT+agf__Status__c+LIKE+%27Closed%25%27%29")


arraySandboxesInUse=$(jq -r '.records[] | .agf__Scheduled_Build_Name__c' <<<"$curlRequest3")
echo "Sandboxes In Use: ${arraySandboxesInUse}"
sandboxString=" ${arraySandboxes[*]} "

for item in ${arraySandboxesInUse[@]}; do
  sandboxString=${sandboxString/ ${item} / }
done
arraySandboxes=( $sandboxString )
echo "Sandboxes To Be Refreshed: ${arraySandboxes[*]}"

for sbox in ${arraySandboxes[@]}; do
  echo "Refreshing ${sbox}"
  sboxId=$(jq -r --arg vname "${sbox}" '.records[] | select(.SandboxName==$vname) | .Id' <<<"$curlRequest2")
  echo "Sandbox ID: $sboxId"

  curlRequest4=$(curl -H "Authorization: Bearer ${authToken}" \
      -H "Content-Type: application/json"  \
      -d '{"LicenseType": "DEVELOPER","AutoActivate": true,"ApexClassId": "01p31000006BQ5M"}' \
      --request "PATCH" "${instanceURL}/services/data/v42.0/tooling/sobjects/SandboxInfo/${sboxId}")
  echo "$curlRequest4" | jq .
done