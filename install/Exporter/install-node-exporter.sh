#!/usr/bin/env bash

#
# 2025/04/02
# xiechengqi
# https://github.com/prometheus/node_exporter
# install node-exporter
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
serviceName="node-exporter"
version="1.9.0"
installPath="/data/${serviceName}-${version}"
downloadUrl="https://github.com/prometheus/node_exporter/releases/download/v${version}/node_exporter-${version}.linux-amd64.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
port=${1-"9009"}

# check node
node_exporter --version &> /dev/null && YELLOW "${serviceName} has been installed ..." && return 0

# check install path
EXEC "rm -rf ${installPath} $(dirname ${installPath})/${serviceName}"
EXEC "mkdir -p ${installPath}/logs"
EXEC "mkdir -p /data/metric"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C ${installPath}"
EXEC "chown -R root.root ${installPath}"

# register bin
EXEC "ln -fs ${installPath}/node_exporter /usr/local/bin/node_exporter"
EXEC "node_exporter --version" && node_exporter --version

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

timestamp=\$(date +%Y%m%d-%H%M%S)
installPath="${installPath}"

touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

node_exporter --collector.textfile.directory=/data/metric --web.listen-address=":${port}" &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=node-exporter
Documentation=https://github.com/prometheus/node_exporter
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

# change softlink
EXEC "ln -fs ${installPath} $(dirname ${installPath})/${serviceName}"

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName} && systemctl start ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# info
YELLOW "${serviceName} version: $version"
YELLOW "install: ${installPath}"
YELLOW "port: ${port}"
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
