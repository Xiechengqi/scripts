#!/usr/bin/env bash

#
# 2025/04/02
# xiechengqi
# install bitdeer node-exporter
# https://github.com/BitdeerAI/node_exporter/releases
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Nvidia/install-node-exporter.sh | sudo bash
#

source /etc/profile
# BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

# environment
serviceName="node-exporter"
version="v1.1"
installPath="/data/${serviceName}"
downloadUrl="https://github.com/BitdeerAI/node_exporter/releases/download/${version}/node_exporter_amd64.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
port=${1-"9009"}

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/logs"
EXEC "mkdir -p /data/metric"

# download tarball
EXEC "curl -sSL ${downloadUrl} | tar zx --strip-components 1 -C ${installPath}"
EXEC "chown -R root.root ${installPath}"

# register bin
EXEC "ln -fs ${installPath}/node_exporter /usr/bin/node_exporter"
EXEC "node_exporter --version" && node_exporter --version

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

export installPath="${installPath}"
\${installPath}/node_exporter --collector.textfile.directory=/data/metric --web.listen-address=":${port}" &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=node-exporter
Documentation=https://github.com/BitdeerAI/node_exporter
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
YELLOW "port: ${port}"
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
