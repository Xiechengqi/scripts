#!/usr/bin/env bash

#
# xiechengqi
# 2025/03/18
# install beszel-agent
# curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Beszel/install-agent.sh | sudo bash -s hub_ssh_key
#

source /etc/profile
# BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

export serviceName="beszel-agent"
export installPath="/data/${serviceName}"
export port="45876"
[ ".${1}" != "." ] && export sshKey="ssh-ed25519 ${1}" || ERROR "Less sshKey, exit ..."
INFO "ssh key: ${sshKey}"
export version="v0.11.0"
export downloadUrl="https://github.com/henrygd/beszel/releases/download/${version}/beszel-agent_linux_amd64.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{data,bin,logs}"

# download and install
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}/bin/"
EXEC "chmod +x ${installPath}/bin/beszel-agent"
EXEC "ln -fs ${installPath}/bin/beszel-agent /usr/local/bin/beszel-agent"
INFO "beszel-agent version" && beszel-agent version

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

export installPath="${installPath}"
export KEY="${sshKey}"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/beszel-agent serve -listen ${port} &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=Beszel Agent Service
Documentation=https://github.com/henrygd/beszel
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
