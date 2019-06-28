#!/bin/bash -x

# RUN EVERYTHING AS ROOT
if [ "$(id -u)" != "0" ]; then
    exec sudo "$0" "$@"
fi

. /usr/local/osmosix/etc/.osmosix.sh
. /usr/local/osmosix/etc/userenv
. /usr/local/osmosix/service/utils/cfgutil.sh
. /usr/local/osmosix/service/utils/agent_util.sh

agentSendLogMessage "Installing httpd ..."
# Remove Apache welcome page and prevent displaying files
sudo yum install httpd -y

sudo sed -i 's/^/#&/g' /etc/httpd/conf.d/welcome.conf
sudo sed -i "s/Options Indexes FollowSymLinks/Options FollowSymLinks/" /etc/httpd/conf/httpd.conf

agentagentSendLogMessage "Installing subversion ..."
sudo yum install subversion mod_dav_svn -y


sudo /bin/cat <<EOM >> /etc/httpd/conf.modules.d/10-subversion.conf 

<Location /svn>
DAV svn
SVNParentPath /svn
AuthName "SVN Repos"
AuthType Basic
AuthUserFile /etc/svn/svn-auth
AuthzSVNAccessFile /svn/authz
Require valid-user
</Location>
EOM

#Create SVN Repo
agentSendLogMessage "Creating $repoName SVN repo..."
sudo mkdir /svn
cd /svn
sudo svnadmin create $repoName
sudo chown -R apache:apache $repoName
# sudo svnadmin create repo1 
# sudo chown -R apache:apache repo1 

#Setup SVN Account
sudo mkdir /etc/svn
agentSendLogMessage "Creating $repoName SVN users..."

sudo htpasswd -cm -b /etc/svn/svn-auth $repoAdmin $repoPwd
sudo chown root:apache /etc/svn/svn-auth
sudo chmod 640 /etc/svn/svn-auth
sudo htpasswd -m -b /etc/svn/svn-auth user002 C1sco123
sudo htpasswd -m -b /etc/svn/svn-auth user003 C1sco123
#Setup Permission for users
sudo cp /svn/repo1/conf/authz /svn/authz
sudo cp /svn/$repoName/conf/authz /svn/authz

FILE="/svn/authz"
sudo /bin/cat <<EOM >$FILE
[groups]
admin=$repoAdmin
repo1_user=user002
repo1_trainee=user003

[/]
@admin=rw

[$repoName:/]
@repo1_user=rw
@repo1_trainee=r
EOM

sudo systemctl start httpd.service
sudo systemctl enable httpd.service

# Chec k is the variable exist
if [ ! -z "$jenkinsIP" ] 
then 
agentSendLogMessage "Creating post-commit hooks ..."

SVNHOOK="/svn/$repoName/hooks/post-commit"
sudo /bin/cat <<EOM >$SVNHOOK

REPOS="$1"
REV="$2"
UUID=`svnlook uuid $REPOS`
/usr/bin/wget \
  --header "Content-Type:text/plain;charset=UTF-8" \
  --post-data "`svnlook changed --revision $REV $REPOS`" \
  --output-document "-" \
  --timeout=2 \
  http://$jenkinsIP:$jenkinsPort/subversion/${UUID}/notifyCommit?rev=$REV
EOM


else 

agentSendLogMessage "Skipping post-commit hooks ..."
agentSendLogMessage "SVN installed."

# sudo firewall-cmd --zone=public --permanent --add-service=http
# sudo firewall-cmd --reload
