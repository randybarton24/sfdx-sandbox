echo "Authenticating..."
mkdir keys
echo $SFDC_SERVER_KEY | base64 -d > keys/server.key
export JWT_KEY_FILE=keys/server.key
sfdx force:auth:jwt:grant --clientid $master_KEY --jwtkeyfile ${JWT_KEY_FILE} --username $master_USER -a prod -r https://login.salesforce.com
echo "Converting source..."
sfdx force:source:convert -r force-app -d testDeploy
echo "Deploying..."
sfdx force:mdapi:deploy -d testDeploy/ -u prod -l RunLocalTests -w -1