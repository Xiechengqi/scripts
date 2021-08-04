#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/03
# install mysql 8.0 5.7
#

trap "_clean" EXIT

_clean() {
cd /tmp && rm -f mysql.tar.* $$*
}

source /etc/profile

OS() {
osType=$1
osVersion=$2
curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/tool/os.sh | bash -s ${osType} ${osVersion} || exit 1
}

INFO() {
printf -- "\033[44;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "%s" "$1"
printf "\n"
}

YELLOW() {
printf -- "\033[44;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "\033[33m%s\033[0m" "$1"
printf "\n"
}

ERROR() {
printf -- "\033[41;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "%s" "$1"
printf "\n"
exit 1
}

EXEC() {
local cmd="$1"
INFO "${cmd}"
eval ${cmd} 1> /dev/null
if [ $? -ne 0 ]; then
ERROR "Execution command (${cmd}) failed, please check it and try again."
fi
}

function main() {
# check os
OS "ubuntu"

# envrionments
serviceName="mysqld"
version=${1-"5.7"}
[ "$version" != "8.0" ] && [ "$version" != "5.7" ] && ERROR "You can only choose mysql version: 5.7 or 8.0"
installPath="/data/${serviceName}-${version}"
[ "$version" = "5.7" ] && downloadUrl="https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.34-linux-glibc2.12-x86_64.tar.gz" || downloadUrl="https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.26-linux-glibc2.12-x86_64.tar.xz"
port="3306"
password="P@ssword"

# check servcie
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath/{conf,data,logs}"

# download tarball
if [ "$version" = "8.0" ]
then
EXEC "curl -sSL $downloadUrl > /tmp/mysql.tar.xz"
EXEC "tar xvJf /tmp/mysql.tar.xz --strip-components 1 -C $installPath"
else
EXEC "curl -sSL $downloadUrl > /tmp/mysql.tar.gz"
EXEC "tar zxvf /tmp/mysql.tar.gz --strip-components 1 -C $installPath"
fi
EXEC "rm -f /tmp/mysql.tar.*"

# install libaio
EXEC "apt update && apt install -y libaio1"

# register bin
EXEC "ln -fs $installPath/bin/* /usr/local/bin"

# config
cat > $installPath/conf/my.cnf << EOF
[mysqld]
port=$port
basedir=$installPath
datadir=$installPath/data
log_error=$installPath/logs/mysqld.log
EOF

# check start service user
! cat /etc/passwd | grep mysql && EXEC "useradd -s /sbin/nologin mysql"

# chown
EXEC "chown -R mysql.mysql $installPath"

# init
EXEC "mysqld --defaults-file=$installPath/conf/my.cnf --initialize --user=mysql"

# chown
# EXEC "chown -R mysql.mysql $installPath"

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

mysqld --defaults-file=$installPath/conf/my.cnf --user=mysql
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=MySQL ${version}
Documentation=https://dev.mysql.com/

[Service]
User=root
Group=root
ExecStart=/bin/bash $installPath/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# sleep
sleep 5

# change root password
defaultPassword=`grep 'temporary password' $installPath/logs/mysqld.log | tail -1 | awk '{print $NF}'`
INFO "default password: $defaultPassword"
EXEC "mysqladmin -uroot -p'${defaultPassword}' password '${password}'"

# open remote connect
echo -e "CREATE USER 'root'@'%' IDENTIFIED BY '${password}';\nGRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;\nFLUSH PRIVILEGES;" > /tmp/$$_init.sql
EXEC "cat /tmp/$$_init.sql" && cat /tmp/$$_init.sql
EXEC "mysql -uroot -p${password} < /tmp/$$_init.sql"

# info
YELLOW "$serviceName $version"
YELLOW "connection cmd: mysql -uroot -P${port} -p${password}"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
