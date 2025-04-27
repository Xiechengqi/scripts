#!/usr/bin/env bash

#
# xiechengqi
# 2025/04/27
# install chartmuseum
# doc: https://chartmuseum.com/docs/
# config: https://chartmuseum.com/docs/#configuration
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Helm/ChartMuseum/install.sh | sudo bash
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

# environment
serviceName="chartmuseum"
installPath="/data/${serviceName}"
version="0.16.2"
downloadUrl="https://get.helm.sh/chartmuseum-v${version}-linux-amd64.tar.gz"
binary="chartmuseum"
port="18088"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{data,bin,logs}"

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx --strip-components 1 -C /tmp/"
EXEC "mv /tmp/chartmuseum ${installPath}/bin/${binary} && chmod +x ${installPath}/bin/${binary}"

# register bin
EXEC "ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
INFO "${binary} -v" && ${binary} -v || return 1

# create config
cat > ${installPath}/config.yaml << EOF
debug: true
port: ${port}
storage.backend: local
storage.local.rootdir: ${installPath}/data
depth: 2
EOF

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

timestamp=\$(date +%Y%m%d-%H%M%S)
installPath="${installPath}"

touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/${binary} --config \${installPath}/config.yaml --enable-metrics &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /etc/systemd/system/${serviceName}.service"
cat > /etc/systemd/system/${serviceName}.service << EOF
[Unit]
Description=helm chartmuseum
Documentation=https://github.com/helm/chartmuseum
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
