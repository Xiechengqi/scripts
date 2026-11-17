#!/usr/bin/env bash

#
# 2026/11/17
# xiechengqi
# Install OpenCode Cli And Web Service
#

source /etc/profile
BASEURL="https://install.xiecq.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

# environment
serviceName="opencode"
binary="opencode"
port="4096"
password="${1}"

versionUrl="https://api.github.com/repos/anomalyco/opencode/releases/latest"
[ "${countryCode}" = "China" ] && versionUrl="${GITHUB_PROXY}/${versionUrl}"
version=$(curl -SsL ${versionUrl} | jq -r .tag_name)
[ ".${version}" != "." ] && version="v1.19.5"
INFO "version: ${version}"

installPath="/data/${serviceName}"
downloadUrl="https://github.com/anomalyco/opencode/releases/download/${version}/opencode-linux-x64.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
# check service
which ${binary} &> /dev/null && YELLOW "${binary} has been installed, please remove $(which ${binary}) first ..." && return 0
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,logs}"

# link config and data dir
export OPENCODE_DATA="$HOME/.local/share/opencode"
export OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
EXEC "mkdir -p ${OPENCODE_DATA} ${OPENCODE_CONFIG_DIR}"
EXEC "ln -fs ${OPENCODE_DATA} ${installPath}/data"
EXEC "ln -fs ${OPENCODE_CONFIG_DIR} ${installPath}/conf"

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}/bin/ && chmod +x ${installPath}/bin/${binary}"

# register bin
EXEC "rm -f -v /usr/local/bin/${binary} && ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
EXEC "${binary} --version" && ${binary} --version

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

export installPath="${installPath}"
export OPENCODE_SERVER_USERNAME="admin"
export OPENCODE_SERVER_PASSWORD="${password}"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/${binary} web --hostname 0.0.0.0 --port ${port} &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"


# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=https://github.com/k3s-io/k3s
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

# upgrade script
EXEC "curl -SsL ${BASEURL}/install/OpenCode/upgrade.sh -o ${installPath}/upgrade.sh && chmod +x ${installPath}/upgrade.sh"

# info
YELLOW "${serviceName} version: ${version}"
YELLOW "install: ${installPath}"
YELLOW "log: tail -f ${installPath}/logs/latest.log"
[ ".${password}" != "." ] && YELLOW "username: admin" && YELLOW "login password: ${password}"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
