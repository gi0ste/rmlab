#!/bin/bash -xe
exec > >(tee -a ./appd_agent_java_$$.log) 2>&1
set -e

. /usr/local/osmosix/etc/userenv
. /usr/local/osmosix/service/utils/agent_util.sh

# AppDynamics variables
AGENT_LOCATION="http://www.stefanogioia.com/appdynamics" #Where to donwload the agent
AGENT_VERSION="appdynamics-php-agent-4.5.0.0-1.x86_64.rpm"
APPD_CONF_NODE="$HOSTNAME"

agentSendLogMessage "Installing Eper-release..."
sudo rpm -Uvh https://mirror.webtatic.com/yum/el7/epel-release.rpm
sudo rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

agentSendLogMessage "Installing php 5.6..."
sudo yum remove php-common -y

yum install -y php56w php56w-opcache php56w-xml php56w-mcrypt php56w-gd php56w-devel php56w-mysql php56w-intl php56w-mbstring


#Downloading the AppD Agent
agentSendLogMessage "Downloading the AppDynamics PHP Agent..."
wget --proxy=off ${AGENT_LOCATION}/${AGENT_VERSION}

# Install the AppD Agent
agentSendLogMessage "Installing the AppDynamics Machine Agent..."
sudo -E rpm -ivh ${AGENT_VERSION}

# Restart apache httpd
echo "Restarting HTTP Service..."
sleep 10
sudo service httpd restart

agentSendLogMessage "AppD: PHP Agent Installation done!"
