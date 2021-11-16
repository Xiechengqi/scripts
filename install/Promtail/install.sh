#!/usr/bin/env bash

#
# xiechengqi
# 2021/11/16
# install promtail
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'centos7|ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: centos7、ubuntu18、ubuntu20"

# environments
serviceName="promtail"
version=${1-"2.4.1"}
installPath="/data/${serviceName}-${version}"
downloadUrl="https://github.com/grafana/loki/releases/download/v${version}/promtail-linux-amd64.zip"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName has been installed ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{bin,conf,logs}"

# install unzip
if [[ "$osInfo" =~ "centos" ]]
then
EXEC "yum install -y unzip"
else
EXEC "apt update && apt install -y unzip"
fi

# download
EXEC "rm -rf /tmp/${serviceName} && mkdir /tmp/${serviceName}"
EXEC "curl -SsL $downloadUrl -o /tmp/${serviceName}/${serviceName}.zip"
EXEC "unzip /tmp/${serviceName}/${serviceName}.zip -d ${installPath}/bin"
EXEC "mv ${installPath}/bin/promtail-linux-amd64 ${installPath}/bin/promtail"

# register bin
EXEC "ln -fs $installPath/bin/promtail /usr/local/bin/promtail"

# conf
cat > $installPath/conf/config.yaml << EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://\${LOKI_URL}/loki/api/v1/push

scrape_configs:
- job_name: \${DEFAULT_JOB_NAME}
  static_configs:
  - targets:
      - localhost
    labels:
      __path__: \${DEFAULT_LOG_PATH}
EOF

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

export LOKI_URL="10.0.26.40:3100"
export DEFAULT_JOB_NAME="system"
export DEFAULT_LOG_PATH="/var/log/*.log"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch $installPath/logs/\${timestamp}.log && ln -fs $installPath/logs/\${timestamp}.log $installPath/logs/latest.log

promtail -config.file=$installPath/conf/config.yaml  &> $installPath/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=Promtail
Documentation=https://github.com/grafana/loki
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

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "${serviceName} version: $version"
YELLOW "install: $installPath"
YELLOW "config: $installPath/conf"
YELLOW "data: $installPath/data"
YELLOW "log: tail -f $installPath/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
