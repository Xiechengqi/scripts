#!/usr/bin/env bash
#
# xiechengqi
# 2026/02/14
# install turn server
# curl -SsL https://install.xiecq.top/install/Turn/install.sh | sudo bash
#

source /etc/profile
BASEURL="https://install.xiecq.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

export serviceName="turn-server"
export installPath="/data/${serviceName}"
export port="6161"
export downloadUrl="https://github.com/mycrl/turn-rs/releases/download/v4.0.0/turn-server-x86_64-unknown-linux-gnu"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
export configUrl="https://raw.githubusercontent.com/mycrl/turn-rs/refs/heads/main/turn-server.toml"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${configUrl}"
export binary="turn-server"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,logs}"

# download and install
EXEC "curl -SsL ${downloadUrl} -o ${installPath}/bin/${binary} && chmod +x ${installPath}/bin/${binary}"
EXEC "ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"

# conf
EXEC "curl -SsL ${configUrl} -o ${installPath}/config.toml"

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

export installPath="${installPath}"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

${binary} --config=\${installPath}/config.toml &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=Turn Service
Documentation=https://github.com/mycrl/turn-rs
After=network.target

[Service]
User=root
Group=root
ExecStart=/bin/bash ${installPath}/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
EXEC "ln -fs ${installPath}/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName} && systemctl start ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

}

main $@
