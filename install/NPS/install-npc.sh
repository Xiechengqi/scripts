#!/usr/bin/env bash

#
# 2025/12/05
# xiechengqi
# install NPC
# docs:
#  https://ehang-io.github.io/nps/
#  https://ai.feishu.cn/wiki/FmVVwDcEGiTZxekYJl5ccuFanlg
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/NPS/install-npc.sh | sudo bash -s [OPTS]
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
serviceName="npc"
version="0.26.27"
installPath="/data/${serviceName}"
downloadUrl="https://github.com/yisier/nps/releases/download/v${version}/linux_amd64_client.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
binary="npc"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/logs"

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}"

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

export installPath="${installPath}"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

echo "=> \${installPath}/${binary} $@" > \${installPath}/logs/latest.log
\${installPath}/${binary} $@ &>> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=https://github.com/yisier/nps
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
