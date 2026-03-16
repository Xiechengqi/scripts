#!/usr/bin/env bash

#
# xiechengqi
# 2026/03/16
# install kula
#

source /etc/profile
BASEURL="https://install.xiecq.top"
source <(curl -SsL ${BASEURL}/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: ${osInfo}"
! echo "${osInfo}" | grep -E 'centos7|ubuntu18|ubuntu20|ubuntu22' &> /dev/null && ERROR "You could only install on os: centos7、ubuntu18、ubuntu20、ubuntu22"

# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

# environments
serviceName="kula"
version=${1-"0.9.2"}
installPath="/data/${serviceName}"
downloadUrl="https://github.com/c0m4r/kula/releases/download/${version}/kula-${version}-amd64.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
binary="kula"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} has been installed ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{src,logs}"

# download
EXEC "curl -sSL ${downloadUrl} | tar zx --strip-components 1 -C ${installPath}/src/"
EXEC "${installPath}/src/${binary} -v" && ${installPath}/src/${binary} -v

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

installPath=${installPath}
timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/src/${binary} &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=https://github.com/c0m4r/kula
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
EXEC "rm -f /etc/systemd/system/${serviceName}.service"
EXEC "ln -fs ${installPath}/${serviceName}.service /etc/systemd/system/${serviceName}.service"

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName} && systemctl start ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# info
YELLOW "${serviceName} version: ${version}"
YELLOW "install path: ${installPath}"
YELLOW "tail log cmd: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
