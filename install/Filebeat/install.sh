#!/usr/bin/env bash

#
# xiechengqi
# OS: ubuntu
# 2023/08/21
# binary install golang (adapt to China)
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20|centos7|centos8' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20、centos7、centos8"

# environments
serviceName="filebeat"
version="8.9.1"
installPath="/data/${serviceName}"
downloadUrl="https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${version}-linux-x86_64.tar.gz"
configUrl=${1-""}

# check service
filebeat version &> /dev/null && YELLOW "$serviceName has been installed ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{src,data,path,conf}"

# download tarball
EXEC "curl -SsL $downloadUrl | tar zx --strip-components 1 -C ${installPath}/src"
EXEC "mv ${installPath}/src/filebeat ${installPath}/bin"

# register path
EXEC "ln -fs ${installPath}/data/bin/* /usr/local/bin/"
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
}

main $@
