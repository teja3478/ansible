#!/bin/sh

# script logging

exec > /tmp/mif_installation.log 2>&1
set -x

file="/data/mifinstall/webmethods/IntegrationServer/instances/default/bin/server.sh"

if [ -f "$file" ]
then
      echo "MIF installation already exist !! Starting MIF application."

       /data/mifinstall/webmethods/IntegrationServer/instances/default/bin/server.sh
fi
        echo "$file mif installation not found!! Starting MIF installation."
 #updating DB Hostname

source /etc/manh/aws_environment.sh

echo $DATABASE_ORACLE_HOST
echo $DATABASE_ORACLE_PORT

s="jdbc.url="
d="jdbc.url=jdbc:oracle:thin:@$DATABASE_ORACLE_HOST:$DATABASE_ORACLE_PORT:ORCL"
R="jdbc:wm:oracle://$DATABASE_ORACLE_HOST:$DATABASE_ORACLE_PORT;serviceName=ORCL"

# JAVA-1.8.0  install
 yum install java-1.8.0 -y

#Removing older java version
  yum remove java-1.7.0 -y


# creating folder for installation files and  DCC, Webmethods and copying required installation files#

mkdir -p /data/mifinstallfiles /data/mifinstall/dcc /data/mifinstall/webmethods /data/mifinstallfiles/mif/mifdump

cd /data/mifinstallfiles
unzip /home/ec2-user/MIFinstaller_2017/MIF.zip

# Installing DCC by calling dependent DCC readscript#

java -jar /data/mifinstallfiles/MIF/webMethods9.12/SoftwareAGInstaller20161018.jar -readScript /data/mifinstallfiles/MIF/mifscript/dccinstall.sh

# DCC DB scripts running #

cd /data/mifinstall/dcc/common/db/bin

./dbConfigurator.sh -a create -d oracle -c ISCoreAudit -v latest -l  "$R" -u OMNIWEB -p OMNIWEB -tsdata WEBMDATA  -tsindex WEBMINDX
./dbConfigurator.sh -a create -d oracle -c ISInternal -v latest -l "$R" -u OMNIWEB -p OMNIWEB -tsdata WEBMDATA  -tsindex WEBMINDX
./dbConfigurator.sh -a create -d oracle -c CrossReference -v latest -l "$R" -u OMNIWEB -p OMNIWEB -tsdata WEBMDATA  -tsindex WEBMINDX
./dbConfigurator.sh -a create -d oracle -c DocumentHistory -v latest -l "$R" -u OMNIWEB -p OMNIWEB -tsdata WEBMDATA  -tsindex WEBMINDX

## installing webMethods by calling dependent webmethods readscript #

java -jar /data/mifinstallfiles/MIF/webMethods9.12/SoftwareAGInstaller20161018.jar -readScript /data/mifinstallfiles/MIF/mifscript/webmethodsinstall.sh

## installing MIF ##

cd /data/mifinstall/webmethods/IntegrationServer/instances/default/bin

./shutdown.sh

cp -pr /data/mifinstallfiles/MIF/mif-2017.zip /data/mifinstallfiles/mif/mifdump

cd /data/mifinstallfiles/mif/mifdump

unzip /data/mifinstallfiles/mif/mifdump/mif-2017.zip

cd /data/mifinstall/webmethods/IntegrationServer/instances/default

unzip -xo /data/mifinstallfiles/mif/mifdump/ILSWebMethods-2017.0.0.1085.zip


##Update ils.properties file under IntegrationServer/instances/default/packages/ILS/resources Makesure ConfigureJDBCAdapter=true, license path and db details updated in ils properties file

sed -i 's/ConfigureJDBCAdapter=false/ConfigureJDBCAdapter=true/g' /data/mifinstall/webmethods/IntegrationServer/instances/default/packages/ILS/resources/ils.properties

sed -i 's/db.username=/db.username=OMNIMIF/g' /data/mifinstall/webmethods/IntegrationServer/instances/default/packages/ILS/resources/ils.properties

sed -i 's/db.password=/db.password=OMNIMIF/g' /data/mifinstall/webmethods/IntegrationServer/instances/default/packages/ILS/resources/ils.properties

sed -i 's,data1/sftware/downloads/keys/mif_manh.lic,data/mifinstallfiles/MIF/webMethods9.12/2018_scpp_all_manh_scpp.lic,g' /data/mifinstall/webmethods/IntegrationServer/instances/default/packages/ILS/resources/ils.properties

sed -i "s|$s|$d|g"  /data/mifinstall/webmethods/IntegrationServer/instances/default/packages/ILS/resources/ils.properties

# removing the jboss-logging.jar file from /IntegrationServer/instances/default/lib/jars path#

rm -rf /data/mifinstall/webmethods/IntegrationServer/lib/jars/jboss-logging.jar


#applying Fix patchscd /data/mifinstall/webmethods/UpdateManager/bin

cd /data/mifinstall/webmethods/UpdateManager/bin

./UpdateManagerCMD.sh -readScript /etc/manh/scripts/mif/CloudStreams.txt
./UpdateManagerCMD.sh -readScript /etc/manh/scripts/mif/IS.txt
./UpdateManagerCMD.sh -readScript /etc/manh/scripts/mif/JDBC.txt
./UpdateManagerCMD.sh -readScript /etc/manh/scripts/mif/MQ_Adapter37.txt
./UpdateManagerCMD.sh -readScript /etc/manh/scripts/mif/Platform_Manager.txt
./UpdateManagerCMD.sh -readScript /etc/manh/scripts/mif/Shared_Libraries.txt

# Starting the MIF server #

cd /data/mifinstall/webmethods/IntegrationServer/instances/default/bin


./server.sh

echo "[$(date)] installmif.sh complete" >> /tmp/mif_installation.log


