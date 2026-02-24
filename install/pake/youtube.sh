#!/usr/bin/env bash

#
# xiechengqi
# 2026/02/24
# install pake
# curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/pake/youtube.sh | sudo bash
#

source /etc/profile
BASEURL="https://install.xiecq.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

export serviceName="pake-youtube"
export serviceUrl="https://youtube.com"
export serviceTaskbar="Youtube"
export installPath="/data/${serviceName}"
export downloadUrl="https://github.com/Xiechengqi/Pake/releases/download/latest/pake-native-linux-amd64-ubuntu22"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
export binary="pake"
export startCmd="WAYLAND_DISPLAY=wayland-1 /usr/local/bin/${binary} ${serviceUrl} --native --name ${serviceTaskbar} --data-dir ${installPath}/data"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{data,logs}"

# download and install
! which ${binary} && EXEC "curl -SsL ${downloadUrl} -o /usr/local/bin/${binary} && chmod +x /usr/local/bin/${binary}"
EXEC "which ${binary}"

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

export installPath="${installPath}"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

${startCmd}  &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=Pake ${serviceTaskbar} Service
Documentation=https://github.com/xiechengqi/Pake
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
