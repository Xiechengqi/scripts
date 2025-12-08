#!/usr/bin/env bash

#
# 2025/04/23
# xiechengqi
# install vmalert
# docs: https://docs.victoriametrics.com/quick-start/
# scrape config: https://docs.victoriametrics.com/scrape_config_examples/
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/VictoriaMetrics/install.sh | sudo bash
#

source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

# environment
serviceName="victoriametrics"
version="1.115.0"
installPath="/data/${serviceName}"
downloadUrl="https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${version}/vmutils-linux-amd64-v${version}.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
binary="vmalert-prod"

export VM_API="http://localhost:8428"
export ALERT_API="http://localhost:9093"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,logs}"

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}/bin/"

# register bin
EXEC "ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
EXEC "${binary} -version" && ${binary} -version

# create alert config
cat > ${installPath}/alert.rules << EOF

EOF

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

export installPath="${installPath}"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

# -rule: Path to the file with rules configuration. Supports wildcard
# -datasource.url: Prometheus HTTP API compatible datasource
# -notifier.url: AlertManager URL (required if alerting rules are used)
# -remoteWrite.url: Default alerts state in the memory, persist alerts state to the configured address in the form of time series ALERTS and ALERTS_FOR_STATE via remote-write protocol
# -remoteRead.url: try to restore alerts state from the configured address
\${installPath}/bin/vmalert -rule=\${installPath}/alert.rules -datasource.url=${VM_API} -notifier.url=${ALERT_API} &> \${installPath}/logs/latest.log

EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=https://github.com/VictoriaMetrics/VictoriaMetrics
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
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
