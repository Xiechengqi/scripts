#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/02
# make install redis
#

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

# environment
serviceName="redis"
version=${1-"5.0.3"}
installPath="/data/${serviceName}-${version}"
downloadUrl="http://download.redis.io/releases/redis-${version}.tar.gz"

# check servcie
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# install gcc
EXEC "apt update && apt install -y build-essential"

# install
EXEC "cd $installPath"
EXEC "make && make install"
EXEC "cd -"

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

redis-server $installPath/redis.conf
EOF

# register redis
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=EthereumTransactionStorage
After=syslog.target
After=network.target
After=postgres.service

[Service]
ExecStart=/bin/bash $installPath/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
TimeoutSec=300
RestartSec=90
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "version: $version"
}

main $@