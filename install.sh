#!/bin/bash
# Author: Daniel Gordi (danitfk)
# Date: 17/Nov/2018

# JIRA Installation variables (must change by user)
JIRA_USER="JIRA"
JIRA_INSTALL_DIR="/opt/jira"
JIRA_HOME="/var/jira/"
JIRA_DISPLAY_NAME="Your JIRA"
JIRA_BASE_URL="jira.gordi.ir"
JIRA_LICENSE=""
JIRA_SYSADMIN_USER="superuser"
JIRA_SYSADMIN_PASSWORD="logmein2018@@"
JIRA_SYSADMIN_DISPLAY_NAME="JIRA Superuser"
JIRA_SYSADMIN_EMAIL_ADDRESS="superuser@mydomain.tld"
JIRA_DATABASE_NAME="JIRA"
JIRA_DATABASE_USERNAME="JIRAusernameDB2018"
JIRA_DATABASE_PASSWORD="JIRApasswordDB2018"
JIRA_PLUGIN_MIRRORING_UPSTREAM="https://jira.gordi.ir"
JIRA_SSL_CERTIFICATE_PASS="myrandomSSLpass"

# Jira installation URL
JIRA_CORE_URL="https://product-downloads.atlassian.com/software/jira/downloads/atlassian-jira-core-7.12.3-x64.bin"
JIRA_SERVICEDESK_URL="https://product-downloads.atlassian.com/software/jira/downloads/atlassian-servicedesk-3.15.3-x64.bin"
JIRA_SOFTWARE_URL="https://product-downloads.atlassian.com/software/jira/downloads/atlassian-jira-software-7.12.3-x64.bin"
# JDK 8 tar.gz Archive
JAVA_REPOSITORY="https://ftp.weheartwebsites.de/linux/java/jdk/"
JAVA_FILENAME="jdk-8u192-linux-x64.tar.gz"

# Run system health check
function system_health_check {
# Check sudo access or root user
if [ "$(whoami)" != "root" ]; then
        echo "ERROR! "
	echo "You have to run this script by root user or sudo command"
        exit 1
fi
# Check network connectivity
if ping -q -c 1 -W 1 google.com >/dev/null; then
  echo "The Internet connectivity and system DNS is OK."
else
  echo "ERROR!! -> There is some problem in Internet connectivity or system DNS."
  exit 1
fi
SYSTEM_IP=`ip route get 8.8.8.8 | sed -n 's|^.*src \(.*\)$|\1|gp' | awk {'print $1'} | head -n 1`
printf "Your Public IP address is $SYSTEM_IP? (y/n) "
read answer
if [[ "$answer" == "y" ]]
then
	DOMAIN_IP=`dig $JIRA_BASE_URL +short @8.8.8.8`
	if [[ "$DOMAIN_IP" == "$SYSTEM_IP" ]]
	then
		echo "System IP and Domain got matched."
	else
		echo "System IP and Domain not matched."
		exit 1
	fi

else
	printf "Please Enter your correct Public IP of Server. (Must match with domain)"
	read answer
	DOMAIN_IP=`dig $JIRA_BASE_URL +short @8.8.8.8`
	if [[ "$DOMAIN_IP" == "$answer" ]]
	then
		echo "System IP and Domain got matched."
	else
		echo "System IP and Domain not matched."
		exit 1
	fi

fi

if [[ -d "$JIRA_HOME" || -d "$JIRA_INSTALL_DIR" ]]
then

	echo "This system contains JIRA in one of these directories"
	echo " - $JIRA_HOME"
	echo " - $JIRA_INSTALL_DIR"
	echo "Cannot Install system, Please clean the system"
	exit 1

fi
}
### Install system Requirements
function requirements_install {
apt-get update
apt-get install -qy wget
wget -q http://ftp.au.debian.org/debian/pool/main/n/netselect/netselect_0.3.ds1-26_amd64.deb
dpkg -i netselect_0.3.ds1-26_amd64.deb
rm -f netselect_0.3.ds1-26_amd64.deb
FAST_APT=`netselect -s 20 -t 40 $(wget -qO - mirrors.ubuntu.com/mirrors.txt) | tail -n1 | grep -o http.*`
if [[ $FAST_APT == "" ]];
then
	echo "Cannot find fastest mirror of apt."
	echo "Continue with default mirror"
else
	ORIG_APT=`cat /etc/apt/sources.list | grep deb | awk {'print $2'} | uniq | head -n1`
	sed -i "s|$ORIG_APT|$FAST_APT|g" /etc/apt/sources.list
	apt-get update
fi
apt-get install -qy postfix  postgresql postgresql-contrib nano curl software-properties-common locales
cd /usr/local/src
wget -qO "JIRA.tar.gz" "$JIRA_URL"
tar -xf JIRA.tar.gz
JIRA_DIR_NAME=`ls -f1 | grep atlassian-JIRA`
cp -r $JIRA_DIR_NAME $JIRA_INSTALL_DIR
rm -rf $JIRA_DIR_NAME
locale-gen "en_US.UTF-8"
update-locale LC_ALL="en_US.UTF-8"
export LC_ALL=en_US.UTF-8
export JIRA_HOME="$JIRA_HOME"
echo 'JIRA_HOME="$JIRA_HOME"' >> /etc/environment
echo 'JIRA_HOME="$JIRA_HOME"'  >> ~/.bashrc
apt-add-repository ppa:git-core/ppa -y > /dev/null 2>&1
apt-get update
apt-get install -qy git
}
### Install Oracle Java 8
function java_install {
cd /opt/
rm -rf $JAVA_FILENAME java `ls -lf1 | grep jdk`
wget -q `echo "$JAVA_REPOSITORY""$JAVA_FILENAME"`
tar -xf $JAVA_FILENAME && rm -f $JAVA_FILENAME
ln -s `ls -lf1 | grep jdk` java
update-alternatives --install /usr/bin/java java /opt/java/bin/java 1
update-alternatives --install /usr/bin/javac javac /opt/java/bin/javac 1
update-alternatives --install /usr/bin/javadoc javadoc /opt/java/bin/javadoc 1
update-alternatives --install /usr/bin/jarsigner jarsigner /opt/java/bin/jarsigner 1
update-alternatives --install /usr/bin/keytool keytool /opt/java/bin/keytool 1
export JAVA_HOME="/opt/java/"
echo 'JAVA_HOME="/opt/java/"' >> /etc/environment
echo 'JAVA_HOME="/opt/java/"' >> ~/.bashrc
}
### Create JIRA user and home directory
function user_permissions {
useradd $JIRA_USER
usermod -s /bin/nologin $JIRA_USER
usermod -d $JIRA_INSTALL_DIR $JIRA_USER
chown -R $JIRA_USER:$JIRA_USER $JIRA_INSTALL_DIR
usermod -a -G sudo $JIRA_USER
mkdir -p $JIRA_HOME
chown -R $JIRA_USER:$JIRA_USER $JIRA_HOME
}
### Configure PostgreSQL database and create user/password
function postgres_configure {
sudo -u postgres createuser $JIRA_DATABASE_USERNAME
cat > /tmp/create_user.psql << EOL
CREATE ROLE $JIRA_DATABASE_USERNAME WITH LOGIN PASSWORD '$JIRA_DATABASE_PASSWORD' VALID UNTIL 'infinity';
CREATE DATABASE $JIRA_DATABASE_NAME WITH OWNER=$JIRA_DATABASE_USERNAME CONNECTION LIMIT=-1;
EOL
chmod 777 /tmp/create_user.psql
cat > /etc/postgresql/*/main/pg_hba.conf << EOL
local   all             postgres                                trust
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 md5
EOL
su postgres -c "psql < /tmp/create_user.psql"
systemctl restart postgresql > /dev/null 2>&1
systemctl enable postgresql > /dev/null 2>&1
}
### Install Let's encrypt through official repository
function install_letsencrypt {
add-apt-repository ppa:certbot/certbot -y > /dev/null 2>&1
apt-get update
apt-get install -qy certbot
certbot certonly --standalone --preferred-challenges http --agree-tos --email $JIRA_SYSADMIN_EMAIL_ADDRESS -d $JIRA_BASE_URL --non-interactive
SSL_DIRECTORY=`echo "/etc/letsencrypt/live/$JIRA_BASE_URL/"`
SSL_CERT_FILE=`echo "$SSL_DIRECTORY""cert.pem"`
SSL_KEY_FILE=`echo "$SSL_DIRECTORY""privkey.pem"`
SSL_CHAIN_FILE=`echo "$SSL_DIRECTORY""chain.pem"`
SSL_FULLCHAIN_FILE=`echo "$SSL_DIRECTORY""fullchain.pem"`
# Create Java keystore from Let's encrypt
cd $SSL_DIRECTORY
rm -f pkcs.p12 $JIRA_BASE_URL.jks
openssl pkcs12 -export -in fullchain.pem -inkey privkey.pem -out pkcs.p12 -name $JIRA_BASE_URL -passin pass:$JIRA_SSL_CERTIFICATE_PASS -passout pass:$JIRA_SSL_CERTIFICATE_PASS > /dev/null 2>&1
keytool -importkeystore -deststorepass $JIRA_SSL_CERTIFICATE_PASS -destkeypass  $JIRA_SSL_CERTIFICATE_PASS  -destkeystore $JIRA_BASE_URL.jks -srckeystore pkcs.p12 -srcstoretype PKCS12 -srcstorepass $JIRA_SSL_CERTIFICATE_PASS -alias $JIRA_BASE_URL > /dev/null 2>&1
SSL_JKS_FILE=`echo "$SSL_DIRECTORY""$JIRA_BASE_URL"".jks"`
}

# Flow:
# 0 System health check
# 1 Install Oracle JAVA JDK 8
# 2 Install System Requirements
# 2 Configure home directory and permissions
# 3 Configure PostgreSQL

export DEBIAN_FRONTEND=noninteractive
# Run system health check
#echo "0) Run System health check" && system_health_check && echo "$(tput setaf 2)0) Everything should be fine $(tput sgr 0)"
#echo "0) Install System Requirements" && requirements_install && echo "$(tput setaf 2)0) System requirements installed successfully $(tput sgr 0)"
echo "0) Install Oracle Java JDK 8" && java_install && echo "$(tput setaf 2)0) Oracle Java JDK 8 Installed successfully.. $(tput sgr 0)"
echo "0) Create JIRA directory and set permissions" && user_permissions && echo "$(tput setaf 2)0) JIRA Directory created and permission granted successfully.. $(tput sgr 0)"

#echo "0) Install Let'sEncrypt and Issue SSL Certificate" && install_letsencrypt && echo "$(tput setaf 2)0) Let'sEncrypt Installed and SSL Certificate Issued successfully $(tput sgr 0)"
#echo "0) Task..." && system_health_check && echo "$(tput setaf 2)0) Task successfully.. $(tput sgr 0)"
