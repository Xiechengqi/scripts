#!/usr/bin/env bash

#
# 2025/04/15
# xiechengqi
# install filebeat
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Filebeat/install.sh | sudo bash
# OS: ubuntu
#

source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20|ubuntu22|centos7|centos8' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20、ubuntu22、centos7、centos8"

# environments
serviceName="filebeat"
version="8.15.3"
installPath="/data/${serviceName}"
downloadUrl="https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${version}-linux-x86_64.tar.gz"
[ "${countryCode}" = "China" ] && configUrl=${1-"${GITHUB_PROXY}/https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Filebeat/sao-filebeat.yaml"} || configUrl=${1-"https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Filebeat/sao-filebeat.yaml"}

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "$serviceName has been installed ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{src,bin,logs,conf}"

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx --strip-components 1 -C ${installPath}/src"
EXEC "cp -f ${installPath}/src/filebeat ${installPath}/bin/"

# register path
EXEC "ln -fs ${installPath}/bin/* /usr/local/bin/"
INFO "filebeat version" && filebeat version

# download config
EXEC "curl -SsL ${configUrl} -o ${installPath}/conf/config.yaml"
INFO "cat ${installPath}/conf/config.yaml" && cat ${installPath}/conf/config.yaml

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

installPath=${installPath}
timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

filebeat -e -c \${installPath}/conf/config.yaml &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /etc/systemd/system/${serviceName}.service"
cat > /etc/systemd/system/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=${serviceName}
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
YELLOW "version: ${version}"
YELLOW "install: ${installPath}"
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
