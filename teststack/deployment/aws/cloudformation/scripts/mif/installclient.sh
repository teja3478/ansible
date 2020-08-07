#!/bin/bash

# script logging
exec > /tmp/oracle_client_installation.log 2>&1
set -x

# importing DB host name
source /etc/manh/aws_environment.sh
echo $DATABASE_ORACLE_HOST
echo $DATABASE_ORACLE_PORT

#setting  up ORACLE HOME and LD_LIBRARY_PATH

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
select * from all_users order by created;

exit;

EOF
echo "[$(date)] createschema.sh complete" >> /tmp/oracle_client_installation.log


