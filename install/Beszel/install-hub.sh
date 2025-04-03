#!/usr/bin/env bash

#
# xiechengqi
# 2025/03/18
# install beszel-hub
# curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Beszel/install-hub.sh | sudo bash
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

export serviceName="beszel-hub"
export port=8090
export installPath="/data/${serviceName}"
export GITHUB_PROXY_URL="https://gh-proxy.com/"
export downloadUrl="${GITHUB_PROXY_URL}https://github.com/henrygd/beszel/releases/latest/download/beszel_Linux_amd64.tar.gz"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{data,bin,logs,src}"

# download and install
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}/src"
EXEC "mv ${installPath}/src/beszel ${installPath}/bin/"
EXEC "chmod +x ${installPath}/bin/beszel"
EXEC "ln -fs ${installPath}/bin/beszel /usr/local/bin/beszel"
INFO "beszel -h" && beszel -h

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

export installPath="${installPath}"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/beszel serve --dir \${installPath}/data --http 0.0.0.0:${port} &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=Beszel Hub Service
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
