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
JIRA_PLUGIN_MIRRORING_UPSTREAM="https://bity.gordi.ir"
JIRA_SSL_CERTIFICATE_PASS="myrandomSSLpass"

# JDK 8 tar.gz Archive
JAVA_REPOSITORY="https://ftp.weheartwebsites.de/linux/java/jdk/"
JAVA_FILENAME="jdk-8u192-linux-x64.tar.gz"



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
