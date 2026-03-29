#!/usr/bin/env bash

#
# xiechengqi
# 2026/03/29
# install reconya
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
serviceName="reconya"
version=${1-"latest"}
installPath="/data/${serviceName}"
downloadUrl="https://github.com/Dyneteq/reconya/releases/latest/download/reconya-linux-amd64.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
binary="reconya"
PORT="13008"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} has been installed ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{src,bin,logs}"

# download
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}/src/"
EXEC "cp -f -v ${installPath}/src/reconya-linux-amd64 tar zx -C ${installPath}/bin/${binary}"
EXEC "ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
INFO "which ${binary}" && which ${binary}

# create .env config
cat > ${installPath}/conf/.env << EOF
# Database Configuration
DATABASE_TYPE=sqlite
SQLITE_PATH=${installPath}/reconya.db
DATABASE_NAME="reconya-dev"
# Port for the web server (default: 3008)
PORT=${PORT}
LOGIN_USERNAME=admin
LOGIN_PASSWORD=password
# Secret key for JWT token generation (use a strong random value)
# eg: openssl rand -base64 32
JWT_SECRET_KEY=TdmtK57oqjzyiCrRqSceGhTqgwsiOYtkUDFIr/5Eqes=
# IPv6 Monitoring Configuration
# Enable or disable IPv6 passive monitoring
IPV6_MONITORING_ENABLED=false
# Network interfaces to monitor for IPv6 traffic (comma-separated, leave empty for auto-detection)
IPV6_MONITOR_INTERFACES=
# Monitoring interval in seconds (default: 30)
IPV6_MONITOR_INTERVAL=30
# Enable link-local address monitoring (fe80::/10)
IPV6_LINK_LOCAL_MONITORING=true
# Enable multicast traffic monitoring (experimental)
EOF

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

installPath=${installPath}
timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

cd \${installPath}/src
[ -f \${installPath}/conf/.env ] && ln -fs \${installPath}/conf/.env \${installPath}/src/.env
\${installPath}/bin/${binary} &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=reconYa
Documentation=https://github.com/Dyneteq/reconya
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
YELLOW "config path: ${installPath}/.env"
YELLOW "tail log cmd: tail -f ${installPath}/logs/latest.log"
YELLOW "web interface: http://localhost:${PORT}"
YELLOW "default login: admin / password"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
