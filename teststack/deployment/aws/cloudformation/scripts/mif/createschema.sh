#!/bin/bash

# script logging
exec > /tmp/oracle_client_installation.log 2>&1
set -x

# importing DB host name
source /etc/manh/aws_environment.sh
echo $DATABASE_ORACLE_HOST
echo $DATABASE_ORACLE_PORT

# setting  up ORACLE HOME and LD_LIBRARY_PATH

cd /home/ec2-user

echo 'ORACLE_HOME=/usr/lib/oracle/12.2/client64' >>/home/ec2-user/.bash_profile
echo 'PATH=$ORACLE_HOME/bin:$PATH' >>/home/ec2-user/.bash_profile
echo 'LD_LIBRARY_PATH=$ORACLE_HOME/lib' >>/home/ec2-user/.bash_profile
echo 'export ORACLE_HOME' >>/home/ec2-user/.bash_profile
echo 'export LD_LIBRARY_PATH' >>/home/ec2-user/.bash_profile

. ./.bash_profile

mkdir -p /usr/lib/oracle/12.2/client64/network/admin
touch /usr/lib/oracle/12.2/client64/network/admin/tnsnames.ora
cat <<EOF >/usr/lib/oracle/12.2/client64/network/admin/tnsnames.ora
MIFDB=
  (DESCRIPTION=
    (ADDRESS=
      (PROTOCOL=TCP)
      (HOST=$DATABASE_ORACLE_HOST)
      (PORT=$DATABASE_ORACLE_PORT)
    )
    (CONNECT_DATA=
      (SERVER=dedicated)
      (SERVICE_NAME=ORCL)
    )
  )

EOF

#Connecting to SQLPLUS client <sqlplus "$DB_uSERNAME/$DB_PASSWORD@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$)(PORT=1521))(CONNECT_DATA=(SID=YOURSID)))">

cd /usr/lib/oracle/12.2/client64/bin

sqlplus  "$1/$2@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$DATABASE_ORACLE_HOST)(PORT=$DATABASE_ORACLE_PORT))(CONNECT_DATA=(SID=ORCL)))"  << EOF

whenever sqlerror exit sql.sqlcode;
set echo off
set heading off


CREATE TABLESPACE IFW_DT_TBS DATAFILE SIZE 100M AUTOEXTEND ON;
CREATE TABLESPACE IFW_IDX_TBS DATAFILE SIZE 100M AUTOEXTEND ON;


CREATE USER OMNIMIF IDENTIFIED BY OMNIMIF default tablespace IFW_DT_TBS;

GRANT CONNECT, UNLIMITED TABLESPACE ,RESOURCE, CREATE VIEW, CREATE TYPE, CREATE PROCEDURE, CREATE TRIGGER, CREATE TABLE, CREATE SEQUENCE,
CREATE SYNONYM,  CREATE ANY CONTEXT, CREATE DATABASE LINK, CREATE MATERIALIZED VIEW TO OMNIMIF;

grant connect,resource to OMNIMIF;

ALTER USER OMNIMIF QUOTA UNLIMITED ON IFW_DT_TBS;
ALTER USER OMNIMIF QUOTA UNLIMITED ON IFW_IDX_TBS;


CREATE TABLESPACE WEBMBLOB DATAFILE SIZE 100M AUTOEXTEND ON;
CREATE TABLESPACE WEBMINDX DATAFILE SIZE 100M AUTOEXTEND ON;
CREATE TABLESPACE WEBMDATA DATAFILE SIZE 100M AUTOEXTEND ON;


CREATE USER OMNIWEB IDENTIFIED BY OMNIWEB;

GRANT CONNECT, UNLIMITED TABLESPACE ,RESOURCE, CREATE VIEW, CREATE TYPE, CREATE PROCEDURE, CREATE TRIGGER, CREATE TABLE, CREATE SEQUENCE,
CREATE SYNONYM,  CREATE ANY CONTEXT, CREATE DATABASE LINK, CREATE MATERIALIZED VIEW TO OMNIWEB;

grant connect,resource to OMNIMIF;

ALTER USER OMNIWEB QUOTA UNLIMITED ON IFW_DT_TBS;
ALTER USER OMNIWEB QUOTA UNLIMITED ON IFW_IDX_TBS;
ALTER USER OMNIWEB QUOTA UNLIMITED ON WEBMBLOB;
ALTER USER OMNIWEB QUOTA UNLIMITED ON WEBMINDX;
ALTER USER OMNIWEB QUOTA UNLIMITED ON WEBMDATA;

exit;

EOF

sleep 60

#deploying the MIF tables with seeds

cd /home/ec2-user/MIFinstaller_2017
unzip dbbuild.zip
cd /home/ec2-user/MIFinstaller_2017/dbbuild
unzip manhmifdbdeploy.zip

chmod -R 755 Oracle

cd Oracle

echo -e "1 \n 1 \n MIFDB \n OMNIMIF \n OMNIMIF \n"  | sh MIFDeploy.sh


echo "[$(date)] createschema.sh complete" >> /tmp/oracle_client_installation.log


