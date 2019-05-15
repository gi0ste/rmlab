#!/bin/bash -x
#exec > >(tee -a ./appd_agent_java_$$.log) 2>&1
#set -e
. /usr/local/osmosix/etc/.osmosix.sh
. /usr/local/osmosix/etc/userenv
. /usr/local/osmosix/service/utils/cfgutil.sh
. /usr/local/osmosix/service/utils/agent_util.sh


# AppDynamics variables
AGENT_LOCATION="http://www.stefanogioia.com/appdynamics" #Where to donwload the agent
AGENT_VERSION="appdynamics-machine-agent-4.5.10.2131.x86_64.rpm"

#List here all the prerequisits
prereqs="java wget"
agentSendLogMessage  "AppD: Installing OS Prereqs ${prereqs}"
sudo yum install -y ${prereqs}


#Downloading the AppD Agent
agentSendLogMessage "Downloading the AppDynamics Machine Agent..."
wget --proxy=off ${AGENT_LOCATION}/${AGENT_VERSION}

# Install the AppD Agent
agentSendLogMessage "Installing the AppDynamics Machine Agent..."
sudo rpm -ivh ${AGENT_VERSION}


agentSendLogMessage "Configuring the AppDynamics Machine Agent..."
sudo sed -i -e "s%<controller-host>%<controller-host>${APPD_CONF_CONTROLLER_HOST}%g" \
-e "s%<controller-port>%<controller-port>${APPD_CONF_CONTROLLER_PORT}%g" \
-e "s%<account-access-key>%<account-access-key>${APPD_CONF_ACCESS_KEY}%g" \
-e "s%<account-name>%<account-name>${APPD_CONF_ACCOUNT}%g" \
/opt/appdynamics/machine-agent/conf/controller-info.xml

# Starting Machine Agent
agentSendLogMessage "Starting the AppDynamics Machine Agent..."
sleep 10
sudo service appdynamics-machine-agent start

# Clean up the temporary file and the agent package file
agentSendLogMessage "Cleaning files... AppDynamics Machine Agent..."
rm -rf $AGENT_VERSION

agentSendLogMessage "AppD: Machine Agent Installation done!"
