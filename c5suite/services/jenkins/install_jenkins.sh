#!/bin/bash
# Jenkins Installation Script
# Install first openJDK, then setup Jenkins repository
# and finally install latest jenkins version

exec > >(tee -a /var/tmp/install_jenkins-_$$.log) 2>&1
#set -e

. /usr/local/osmosix/etc/userenv
. /usr/local/osmosix/service/utils/agent_util.sh#
#if[ -e /etc/yum.repos.d/cliqr.repo ] then
  sudo sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/cliqr.repo
#fi

wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

agentSendLogMessage "Installing java."
yum install java -y
agentSendLogMessage "Installing Jenkins."
yum install jenkins -y
agentSendLogMessage "Jenkins installed"
JPWD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
agentSendLogMessage "Initial Jenkins Password: $JPWD"
