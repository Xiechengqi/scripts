#!/usr/bin/env bash

#
# 2025/07/31
# xiechengqi
# install goproxy
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Goproxy/install.sh | sudo bash
# doc: https://snail007.host900.com/goproxy/manual/zh/
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
serviceName="goproxy"
version="15.1"
installPath="/data/${serviceName}"
downloadUrl="https://github.com/snail007/goproxy/releases/download/v${version}/proxy-linux-amd64.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
binary="goproxy"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,logs}"

# download tarball
EXEC "rm -rf /tmp/${serviceName} && mkdir -p /tmp/${serviceName}"
EXEC "curl -SsL ${downloadUrl} | tar zx -C /tmp/${serviceName}/"
EXEC "mv /tmp/${serviceName}/proxy ${installPath}/bin/${binary} && chmod +x ${installPath}/bin/${binary}"

# register bin
EXEC "ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
INFO "${binary} --version" && ${binary} --version

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
#
# config docs: https://snail007.host900.com/goproxy/manual/zh
#

export installPath="${installPath}" && cd \${installPath}

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/${binary} socks -t tcp -p "0.0.0.0:10080" &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=https://github.com/snail007/goproxy
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
