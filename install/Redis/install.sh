#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/11
# make install redis
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# environment
serviceName="redis"
version=${1-"5.0.3"}
installPath="/data/${serviceName}-${version}"
downloadUrl="http://download.redis.io/releases/redis-${version}.tar.gz"
port="6379"  # redis default port

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

dir $installPath/data
logfile "$installPath/logs/redis.log"
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
YELLOW "install path: $installPath"
YELLOW "config path: $installPath/redis.conf"
YELLOW "data path: $installPath/data"
YELLOW "log cmd: tail -f $installPath/logs/redis.log"
YELLOW "connect cmd: redis-cli -h 127.0.0.1 -p $port" 
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
