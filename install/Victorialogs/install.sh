#!/usr/bin/env bash

#
# 2025/04/15
# xiechengqi
# install victorialogs
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Victorialogs/install.sh | sudo bash
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
serviceName="victorialogs"
version="1.18.0"
installPath="/data/${serviceName}"
downloadUrl="https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${version}-victorialogs/victoria-logs-linux-amd64-v${version}-victorialogs.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
binary="victoria-logs-prod"
port="29514"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,logs,data}"

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}/bin/"
EXEC "chmod +x ${installPath}/bin/${binary}"

# register bin
EXEC "ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
INFO "${binary} -version" && ${binary} -version

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

export installPath="${installPath}"
cd \${installPath}

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/${binary} -syslog.listenAddr.tcp=:${port} -storageDataPath=\${installPath}/data -retentionPeriod=8w -retention.maxDiskSpaceUsageBytes=10GiB &> \${installPath}/logs/latest.log
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
