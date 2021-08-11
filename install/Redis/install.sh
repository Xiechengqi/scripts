#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/11
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
redisPassword="P@ssword"

# check servcie
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{data,logs}"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# install gcc
EXEC "apt update && apt install -y build-essential"

# install
EXEC "cd $installPath"
EXEC "make && make install"
EXEC "cd -"

# conf
sed -i '/^requirepass/d' $installPath/redis.conf
sed -i '/^dir/d' $installPath/redis.conf
sed -i '/^logfile/d' $installPath/redis.conf
cat >> $installPath/redis.conf << EOF

requirepass $redisPassword
dir $installPath/data
logfile \"$installPath/logs/redis.log\"
EOF

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

redis-server $installPath/redis.conf
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > $installPath/${serviceName}.service << EOF
[Unit]
Description=Redis Server
After=syslog.target
After=network.target

[Service]
ExecStart=/bin/bash $installPath/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
TimeoutSec=300
RestartSec=90
Restart=always

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
YELLOW "$serviceName version: $version"
YELLOW "$serviceName password: $redisPassword"
YELLOW "install path: $installPath"
YELLOW "config path: $installPath/redis.conf"
YELLOW "data path: $installPath/data"
YELLOW "log cmd: tail -f $installPath/logs/redis.log"
YELLOW "connect cmd: redis-cli -h 127.0.0.1 -p 6379 -a ${redisPassword}" 
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
