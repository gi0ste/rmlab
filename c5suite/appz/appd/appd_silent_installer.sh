#!/bin/bash
exec > >(tee -a /var/tmp/install-appd-platform_$$.log) 2>&1
# RUN EVERYTHING AS ROOT
if [ "$(id -u)" != "0" ]; then
    exec sudo "$0" "$@"
fi

# Source the Cloudcenter user env file to onboard C3 specifc vars
source /usr/local/cliqr/etc/userenv

#Declaring variable used in the script
LOCAL_REPOSITORY=http://192.168.130.206
APPD_PLATFORM_NAME=platform-setup-x64-linux-4.5.0.12579.sh
APPD_RESPONSE_FILE=appd.response.file

. /usr/local/osmosix/etc/.osmosix.sh
. /usr/local/osmosix/etc/userenv
. /usr/local/osmosix/service/utils/cfgutil.sh
. /usr/local/osmosix/service/utils/agent_util.sh

firewall-cmd --zone=public --add-port=8090/tcp --permanent
firewall-cmd --zone=public --add-port=9191/tcp --permanent

agentSendLogMessage "Downloading AppDynamic 4.5..."
wget $LOCAL_REPOSITORY/appz/appdynamics/$APPD_PLATFORM_NAME
wget $LOCAL_REPOSITORY/appz/appdynamics/$APPD_RESPONSE_FILE

sed -i "s/theAdminPort/$adminPort/" $APPD_RESPONSE_FILE
sed -i "s/theDatabasePort/$databasePort/" $APPD_RESPONSE_FILE
#sudo sed -i "s/theDataDir/$dataDir/" $APPD_RESPONSE_FILE
sed -i "s/theDatabasePassword/$databasePassword/" $APPD_RESPONSE_FILE
sed -i "s/theDatabaseRootPassword/$databaseRootPassword/" $APPD_RESPONSE_FILE
sed -i "s/theAdminPassword/$AdminPassword/" $APPD_RESPONSE_FILE
#sudo sed -i "s/useHttps/$useHttps/" $APPD_RESPONSE_FILE
#sudo sed -i "s/theIinstallationDir/$installationDir/" $APPD_RESPONSE_FILE
sed -i "s/HOSTPLACEHOLDER/$HOSTNAME/" $APPD_RESPONSE_FILE


# We need to add the hostname to /etc/hosts
echo "127.0.0.1 "$HOSTNAME >> /etc/hosts


agentSendLogMessage "Installing AppDynamic 4.5..."
chmod +x ./$APPD_PLATFORM_NAME
./$APPD_PLATFORM_NAME -q -varfile $APPD_RESPONSE_FILE
rm $APPD_PLATFORM_NAME

agentSendLogMessage "AppDynamics installed"
agentSendLogMessage "Configuring AppDynamics"

mkdir /opt/appdynamics/platform/products
cd /opt/appdynamics/platform/platform-admin/bin

./platform-admin.sh create-platform --name AppD --installation-dir /opt/appdynamics/platform/products
./platform-admin.sh add-hosts --hosts localhost
./platform-admin.sh submit-job --service controller --job install --args controllerPrimaryHost=localhost controllerAdminUsername=$controllerAdminUsername controllerAdminPassword=$controllerAdminPassword controllerRootUserPassword=$AdminPassword mysqlRootPassword=$databaseRootPassword
