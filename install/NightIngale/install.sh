#!/usr/bin/env bash

#
# 2025/04/23
# xiechengqi
# install nightingale
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/NightIngale/install.sh | sudo bash
# doc: https://flashcat.cloud/docs/content/flashcat-monitor/nightingale-v7/install/binary/
# config: https://github.com/ccfos/nightingale/blob/main/etc/config.toml
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
serviceName="n9e"
version="8.0.0-beta.10"
installPath="/data/${serviceName}"
downloadUrl="https://github.com/ccfos/nightingale/releases/download/v${version}/n9e-v${version}-linux-amd64.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
configUrl="https://github.com/ccfos/nightingale/blob/v${version}/etc/config.toml"
[ "${countryCode}" = "China" ] && configUrl="${GITHUB_PROXY}/${configUrl}"
binary="n9e"
port="17000"
redis="127.0.0.1:6379"
pushgwWritersUrl="http://127.0.0.1:8424/api/v1/write"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{conf,bin,logs}"

# download tarball
EXEC "rm -rf /tmp/${serviceName} && mkdir -p /tmp/${serviceName}"
EXEC "curl -SsL ${downloadUrl} | tar zx -C /tmp/${serviceName}/"
EXEC "mv /tmp/${serviceName}/{n9e,n9e-cli,n9e-edge} ${installPath}/bin/"
EXEC "chmod +x ${installPath}/bin/*"

# register bin
EXEC "ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
INFO "${binary} -version" && ${binary} -version

# create conf
EXEC "curl -SsL ${configUrl} -o ${installPath}/conf/config.toml"
sed -i "s#^Port =.*#Port = ${port}#;s#^Address =.*#Address = \"${redis}\"#;s#^Url =.*#Url = \"${pushgwWritersUrl}\"#" ${installPath}/conf/config.toml

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

export installPath="${installPath}" && cd \${installPath}

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/${binary} -configs \${installPath}/conf &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=https://github.com/ccfos/nightingale
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
