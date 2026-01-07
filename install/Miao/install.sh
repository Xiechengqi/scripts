#!/usr/bin/env bash
#
# xiechengqi
# 2026/01/07
# install miao proxy
# curl -SsL https://install.xiechengqi.top/install/Miao/install.sh | sudo bash
#

source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

export serviceName="miao"
export installPath="/data/${serviceName}"
export port="6161"
export downloadUrl="https://github.com/Xiechengqi/miao/releases/download/latest/miao-rust-linux-amd64"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
export binary="miao"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,logs}"

# download and install
EXEC "curl -SsL ${downloadUrl} -o ${installPath}/bin/${binary} && chmod +x ${installPath}/bin/${binary}"
EXEC "ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"

# conf
cat > ${installPath}/config.yaml << EOF
# Miao Configuration Example

# HTTP API port (optional, default: 6161)
port: ${port}

# sing-box home directory (optional)
# If not specified, miao will use embedded sing-box binary
# and extract it to ./runtime directory
# sing_box_home: /home/alice/pros/miao/sing-box

# Subscription URLs (optional)
subs:
  - https://example.com/subscription1
  - https://example.com/subscription2

# Manual nodes in JSON format (optional)
nodes:
  # - '{"type":"hysteria2","tag":"my-node","server":"example.com","server_port":443,"password":"xxx"}'
EOF

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

export installPath="${installPath}"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

cd \${installPath} && ${binary} &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=Miao Service
Documentation=https://github.com/Xiechengqi/miao
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
