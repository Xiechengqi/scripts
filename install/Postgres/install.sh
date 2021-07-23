#!/usr/bin/env bash

#
# xiechengqi
# 2021/07/23
# binary install postgresql
#

source /etc/profile

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
# environments
serviceName="postgres"
version="10.5"
installPath="/data/${serviceName}-${version}"
downloadUrl="https://get.enterprisedb.com/postgresql/postgresql-${version}-1-linux-x64-binaries.tar.gz"
user="postgres"
port="5432"

# check service
systemctl is-active $serviceName &> /dev/null && INFO "$serviceName is running ..." && return 0

# check user
! cat /etc/passwd | grep $user &> /dev/null && EXEC "useradd -m $user"

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath/{data,logs} && cd $installPath"

# download tarball
EXEC "curl -SsL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# register path
EXEC "sed -i '/postgres\/bin/d' /etc/profile"
EXEC "echo 'export PATH=\$PATH:$installPath/bin' >> /etc/profile"
EXEC "echo 'export LD_LIBRARY_PATH=$installPath/lib' >> /etc/profile"
EXEC "ln -fs $installPath/bin/* /usr/bin/"
EXEC "source /etc/profile"
EXEC "psql --version" && psql --version

# chown
EXEC "chown -R $user.$user $installPath" 

# init db
EXEC "su $user -c '$installPath/bin/initdb -E UTF8 --locale=en_US.utf8 -D $installPath/data'"

# register service
cat > /lib/systemd/system/${serviceName}.service << EOF
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

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable --now $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "version: $version"
YELLOW "install path: $installPath"
YELLOW "data path: $installPath/data"
YELLOW "log path: $installPath/logs"
YELLOW "conncetion cmd: su $user && psql -p $port"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main