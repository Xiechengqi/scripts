#!/usr/bin/env bash

#
# 2025/04/08
# xiechengqi
# https://github.com/komodorio/helm-dashboard
# install helm dashboard
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
serviceName="helm-dashboard"
version="2.0.3"
installPath="/data/${serviceName}"
downloadUrl="https://github.com/komodorio/helm-dashboard/releases/download/v${version}/helm-dashboard_${version}_Linux_x86_64.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
port=${1-"18080"}

# check node
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} has been installed ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/logs"

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}"
EXEC "chown -R root.root ${installPath}"

# register bin
EXEC "ln -fs ${installPath}/helm-dashboard /usr/local/bin/helm-dashboard"
EXEC "helm-dashboard --version" && helm-dashboard --version

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

timestamp=\$(date +%Y%m%d-%H%M%S)
installPath="${installPath}"

touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

helm-dashboard --bind 0.0.0.0 --port ${port} --no-analytics &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=helm-dashboard
Documentation=https://github.com/komodorio/helm-dashboard
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
