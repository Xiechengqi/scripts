#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/03
# install postgresql
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

function main() {
# check os
OS "ubuntu"

# environments
serviceName="postgres"
version=${1-"10.5"}
installPath="/data/${serviceName}-${version}"
downloadUrl="https://get.enterprisedb.com/postgresql/postgresql-${version}-1-linux-x64-binaries.tar.gz"
user="postgres"
port="5432"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# check user
! cat /etc/passwd | grep $user &> /dev/null && EXEC "useradd -m $user"

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{data,logs} && cd $installPath"

# download tarball
EXEC "curl -SsL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# register path
EXEC "sed -i '/postgres.*\/bin/d' /etc/profile"
EXEC "sed -i '/postgres.*\/lib/d' /etc/profile"
EXEC "echo 'export PATH=\$PATH:$installPath/bin' >> /etc/profile"
EXEC "ln -fs $installPath/bin/* /usr/bin/"
EXEC "source /etc/profile"
EXEC "psql --version" && psql --version

# chown
EXEC "chown -R $user.$user $installPath" 

# init db
EXEC "su $user -c '$installPath/bin/initdb -E UTF8 --locale=en_US.utf8 -D $installPath/data'"

# register service
cat > $installPath/${serviceName}.service << EOF
[Unit]
Description=PostgreSQL database server
After=network.target

[Service]
Type=forking
User=$user
Group=$user
Environment=PGPORT=$port
Environment=PGDATA=$installPath/data/
Environment=PGLOG=$installPath/logs/${serviceName}.log
OOMScoreAdjust=-1000
ExecStart=$installPath/bin/pg_ctl start -l \${PGLOG} -D \${PGDATA} -s -o "-p \${PGPORT}" -w -t 300
ExecStop=$installPath/bin/pg_ctl stop -D \${PGDATA} -s -m fast
ExecReload=$installPath/bin/pg_ctl reload -D \${PGDATA} -s
TimeoutSec=300

[Install]
WantedBy=multi-user.target
EOF
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
EXEC "ln -fs $installPath/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "${serviceName} version: $version"
YELLOW "install path: $installPath"
YELLOW "data path: $installPath/data"
YELLOW "log path: $installPath/logs"
YELLOW "conncetion cmd: su $user && psql -p $port"
YELLOW "managemanet cmd: systemctl [status|stop|start|restart|reload] $serviceName"
}

main $@
