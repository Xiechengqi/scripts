#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/13
# install consul
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
OS "ubuntu"

# environments
serviceName="consul"
version=${1-"1.10.1"}
installPath="/data/${serviceName}-${version}"
downloadUrl="https://releases.hashicorp.com/consul/${version}/consul_${version}_linux_amd64.zip"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName has been installed ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{bin,conf,data,logs}"

# install unzip
EXEC "apt update && apt install -y unzip"

# download
EXEC "rm -rf /tmp/${serviceName} && mkdir /tmp/${serviceName}"
EXEC "curl -SsL $downloadUrl -o /tmp/${serviceName}/${serviceName}.zip"
EXEC "unzip /tmp/${serviceName}/${serviceName}.zip -d ${installPath}/bin"

# register bin
EXEC "ln -fs $installPath/bin/consul /usr/local/bin/consul"

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

timestamp=\$(date +%Y%m%d%H%M%S)
touch $installPath/logs/\${timestamp}.log && ln -fs $installPath/logs/\${timestamp}.log $installPath/logs/latest.log
consul agent -server -bootstrap-expect=1 -data-dir=$installPath/data -node=master -bind=127.0.0.1 -config-dir=$installPath/conf -client 0.0.0.0 -ui &> $installPath/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > $installPath/${serviceName}.service << EOF
[Unit]
Description=Consul
Documentation=https://github.com/hashicorp/consul
After=network.target

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
YELLOW "config path: $installPath/conf"
YELLOW "data path: $installPath/data"
YELLOW "tail log cmd: tail -f $installPath/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
