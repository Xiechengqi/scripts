#!/usr/bin/env bash

#
# xiechengqi
# 2025/05/12
# http://docs.minio.org.cn/docs/
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Minio/install.sh | sudo bash
#

source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: ${osInfo}"
! echo "${osInfo}" | grep -E 'centos7|centos8|ubuntu16|ubuntu18|ubuntu20|ubuntu22' &> /dev/null && ERROR "You could only install on os: centos7、centos8、ubuntu16、ubuntu18、ubuntu20、ubuntu22"

# environments
export serviceName="minio"
export installPath="/data/${serviceName}"
export downloadUrl="http://dl.minio.org.cn/server/minio/release/linux-amd64/minio"
export clientDownloadUrl="http://dl.minio.org.cn/client/mc/release/linux-amd64/mc"
export binary="minio"
export webPort="9001"
export minio_root_user="admin"
export minio_root_password="password"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,data,logs}"

# download
EXEC "curl -SsL ${downloadUrl} -o ${installPath}/bin/${binary} && chmod +x ${installPath}/bin/${binary} && ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
EXEC "curl -SsL ${clientDownloadUrl} -o ${installPath}/bin/mc && chmod +x ${installPath}/bin/mc && ln -fs ${installPath}/bin/mc /usr/local/bin/mc"
INFO "minio -v" && minio -v || exit 1

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

installPath="${installPath}"
export MINIO_ROOT_USER=${minio_root_user}
export MINIO_ROOT_PASSWORD=${minio_root_password}

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/${binary} server \${installPath}/data --console-address ":${webPort}" &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=Minio
Documentation=http://docs.minio.org.cn/docs
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

# # set root_user and root_password
# sed -i '/MINIO_ROOT_USER/d;/MINIO_ROOT_PASSWORD/d' /etc/profile
# cat > /etc/profile << EOF
# export MINIO_ROOT_USER=${minio_root_user}
# export MINIO_ROOT_PASSWORD=${minio_root_password}
# EOF

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName} && systemctl start ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# info
YELLOW "${serviceName} version: $version"
YELLOW "data: ${installPath}/data"
YELLOW "log: ${installPath}/logs"
YELLOW "web port: ${webPort}"
YELLOW "web user: ${minio_root_user}"
YELLOW "web password: ${minio_root_password}"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
