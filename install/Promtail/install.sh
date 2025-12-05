#!/usr/bin/env bash

#
# 2025/04/15
# xiechengqi
# install promtail
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Promtail/install.sh | sudo bash [-s LOKI_URL]
#

source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'centos7|ubuntu18|ubuntu20|ubuntu22' &> /dev/null && ERROR "You could only install on os: centos7、ubuntu18、ubuntu20、ubuntu22"

# environments
serviceName="promtail"
version="3.4.3"
installPath="/data/${serviceName}"
downloadUrl="https://github.com/grafana/loki/releases/download/v${version}/promtail-linux-amd64.zip"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
ip=$(hostname -I | awk '{print $1}')
LOKI_URL="$1"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} has been installed ..." && return 0

# check install path
EXEC "rm -rf ${installPath} $(dirname ${installPath})/${serviceName}"
EXEC "mkdir -p ${installPath}/{bin,conf,logs}"

# download
EXEC "which unzip"
EXEC "rm -rf /tmp/${serviceName} && mkdir /tmp/${serviceName}"
EXEC "curl -SsL ${downloadUrl} -o /tmp/${serviceName}/${serviceName}.zip"
EXEC "unzip /tmp/${serviceName}/${serviceName}.zip -d ${installPath}/bin"
EXEC "mv ${installPath}/bin/promtail-linux-amd64 ${installPath}/bin/promtail"

# register bin
EXEC "ln -fs ${installPath}/bin/promtail /usr/local/bin/promtail"

# conf
cat > ${installPath}/conf/config.yaml << EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://${LOKI_URL}/loki/api/v1/push

scrape_configs:
- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      ip: ${ip}
      hostname: $(hostname)
      __path__: /var/log/containers/*
EOF

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
# source /etc/profile

installPath="${installPath}"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

promtail -config.file=\${installPath}/conf/config.yaml  &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

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
ExecStart=/bin/bash ${installPath}/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName} && systemctl start ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# info
YELLOW "${serviceName} version: ${version}"
YELLOW "install: ${installPath}"
YELLOW "config: ${installPath}/conf"
YELLOW "data: ${installPath}/data"
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
