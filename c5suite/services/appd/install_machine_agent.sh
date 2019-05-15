#!/bin/bash -x
exec > >(tee -a /var/tmp/appd_agent_java_$$.log) 2>&1
set -e
. /usr/local/osmosix/etc/.osmosix.sh
. /usr/local/osmosix/etc/userenv
. /usr/local/osmosix/service/utils/cfgutil.sh
. /usr/local/osmosix/service/utils/agent_util.sh


# AppDynamics variables
AGENT_LOCATION="http://www.stefanogioia.com/appdynamics" #Where to donwload the agent
AGENT_VERSION="appdynamics-machine-agent-4.5.10.2131.x86_64.rpm"

#List here akll the prerequisits
prereqs="java"
agentSendLogMessage  "AppD: Installing OS Prereqs ${prereqs}"
sudo yum install -y ${prereqs}


#Downloading the AppD Agent
echo "Downloading the AppDynamics Machine Agent..."
cd /tmp/
mkdir appd-agent -p
cd /tmp/appd-agent
wget --proxy=off ${AGENT_LOCATION}/${AGENT_VERSION}; touch /tmp/appd-agent/downloadagent.done &

# Install the AppD Agent
echo "Installing the AppDynamics Machine Agent..."
rpm -ivh ${AGENT_VERSION}
#rpm -ivh appdynamics-machine-agent-4.3.7.3-1.x86_64.rpm

echo "Configuring the AppDynamics Machine Agent..."
sed -i.bkp -e "s%<controller-host>%<controller-host>${APPD_CONF_CONTROLLER_HOST}%g" \
-e "s%<controller-port>%<controller-port>${APPD_CONF_CONTROLLER_PORT}%g" \
-e "s%<account-access-key>%<account-access-key>${APPD_CONF_ACCESS_KEY}%g" \
-e "s%<controller-ssl-enabled>%<controller-ssl-enabled>false%g" \
-e "s%<account-name>%<account-name>${APPD_CONF_ACCOUNT}%g" \
-e "s%<sim-enabled>false%<sim-enabled>false%g" \
/opt/appdynamics/machine-agent/conf/controller-info.xml


# Restart Machine Agent
echo "Starting the AppDynamics Machine Agent..."
