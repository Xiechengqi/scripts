#!/usr/bin/env bash

#
# xiechengqi
# 2024/03/13
# install frps
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'centos7|ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: centos7、ubuntu18、ubuntu20"

countryCode=`curl -SsL https://api.ip.sb/geoip | sed 's/,/\n/g' | grep country_code | awk -F '"' '{print $(NF-1)}'`

# environment
serviceName="frps"
version=${1-"0.55.1"}
installPath="/data/${serviceName}-${version}"
downloadUrl="https://github.com/fatedier/frp/releases/download/v${version}/frp_${version}_linux_amd64.tar.gz"
[ "${countryCode}" = "CN" ] && downloadUrl="https://gh-proxy.com/${downloadUrl}"

# check servcie
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath} $(dirname ${installPath})/${serviceName}"
EXEC "mkdir -p ${installPath}/{bin,conf,logs}"

# download tarball
EXEC "mkdir -p /tmp/${serviceName}-${version}"
EXEC "curl -SsL $downloadUrl | tar zx --strip-components 1 -C /tmp/${serviceName}-${version}"
EXEC "cp -fv /tmp/${serviceName}-${version}/frps ${installPath}/bin/"
EXEC "ln -fs ${installPath}/bin/frps /usr/local/bin/frps"
INFO "frps -v" && frps -v

# conf
EXEC "curl -SsL $BASEURL/install/frp/frps-default.ini > ${installPath}/conf/config.ini"

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

installPath="${installPath}"
timestamp=\$(date +%Y%m%d-%H%M%S)

touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/frps -c \${installPath}/conf/config.ini &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description = frp server
After = network.target syslog.target

[Service]
ExecStart=/bin/bash ${installPath}/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
TimeoutSec=300
RestartSec=90
Restart=always

[Install]
WantedBy=multi-user.target
EOF
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
EXEC "ln -fs ${installPath}/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# change softlink
EXEC "ln -fs ${installPath} $(dirname ${installPath})/${serviceName}"

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName} && systemctl start ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# info
YELLOW "${serviceName} version: $version"
YELLOW "install path: ${installPath}"
YELLOW "config path: ${installPath}/config.ini"
YELLOW "log cmd: tail -f ${installPath}/logs/frps.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
