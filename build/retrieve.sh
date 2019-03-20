echo "Authenticating..."
mkdir keys
echo $SFDC_SERVER_KEY | base64 -d > keys/server.key
CURRENTDATE=`date +"%Y-%m-%d-%H"`
export JWT_KEY_FILE=keys/server.key
sfdx force:auth:jwt:grant --clientid $CONSUMER_KEY --jwtkeyfile ${JWT_KEY_FILE} --username $USERNAME --setdefaultdevhubusername -a prod -r https://login.salesforce.com
sfdx force --help
echo "Setting up Git..."
mkdir -p /home/circleci/tempdir
cd /home/circleci/tempdir
git init
git config --global user.email "randy@solutionreach.com"
git config --global user.name "Randy Barton"
git clone git@github.com:sr-system-ops/sr-sf.git
cd /home/circleci/tempdir/sr-sf
git checkout -b ${CURRENTDATE}
echo "Retrieving Source..."
sfdx force:source:retrieve -u prod -x xml/package.xml
echo "Committing and pushing changes..."
git status
git add -A
git commit -m ${CURRENTDATE}
git push -u origin HEAD