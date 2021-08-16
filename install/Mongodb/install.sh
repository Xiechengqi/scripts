#!/usr/bin/env bash

#
# xiechengqi
# 2021/07/23
# install mongodb
#

source /etc/profile
source <(curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/tool/common.sh)

main() {
# check os
OS "ubuntu" "18"

# environments
serviceName="mongod"
version=${1-"4.0.25"}
installPath="/data/${serviceName}-${version}"
downloadUrl="https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${version}.tgz"
port="27017"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{data,logs}"

# download tarball
EXEC "curl -SsL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# register path
EXEC "sed -i '/mongod.*\/bin/d' /etc/profile"
EXEC "echo 'export PATH=\$PATH:$installPath/bin' >> /etc/profile"
EXEC "ln -fs $installPath/bin/* /usr/bin/"
EXEC "source /etc/profile"
EXEC "mongo --version" && mongo --version

# config
cat > ${installPath}/${serviceName}.conf << EOF
dbpath = $installPath/data/ #数据文件存放目录
logpath = $installPath/logs/${serviceName}.log #日志文件存放目录
port = $port  #端口
# fork = true  #以守护程序的方式启用，即在后台运行
bind_ip = 0.0.0.0    #允许所有的连接
EOF

# register service
cat > $installPath/${serviceName}.service << EOF
[Unit]
Description=MongoDB Database Server
Documentation=https://docs.mongodb.org/manual
After=network-online.target
Wants=network-online.target

[Service]
User=root
Group=root
Environment="OPTIONS=-f $installPath/${serviceName}.conf"
ExecStart=$installPath/bin/mongod \$OPTIONS
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=2
StartLimitInterval=0
# file size
LimitFSIZE=infinity
# cpu time
LimitCPU=infinity
# virtual memory size
LimitAS=infinity
# open files
LimitNOFILE=64000
# processes/threads
LimitNPROC=64000
# locked memory
LimitMEMLOCK=infinity
# total threads (user+kernel)
TasksMax=infinity
TasksAccounting=false
# Recommended limits for mongod as specified in
# https://docs.mongodb.com/manual/reference/ulimit/#recommended-ulimit-settings

[Install]
WantedBy=multi-user.target
EOF
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
EXEC "ln -fs $installPath/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/${serviceName}"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName" && systemctl status $serviceName

# info
YELLOW "${serviceName} version: $version"
YELLOW "${serviceName} port: $port"
YELLOW "install path: $installPath"
YELLOW "config path: $installPath/conf"
YELLOW "data path: $installPath/data"
YELLOW "log path: $installPath/logs"
YELLOW "conncetion cmd: mongo"
YELLOW "managemanet cmd: systemctl [status|stop|start|restart|reload] $serviceName"
}

main $@
