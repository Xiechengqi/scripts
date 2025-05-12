#!/usr/bin/env bash

#
# xiechengqi
# 2025/05/12
# http://docs.minio.org.cn/docs/
# docker install minio server and client
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

trap _clean "EXIT"

_clean() {
rm -f /data/$$_minio
}

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'centos7|centos8|ubuntu16|ubuntu18|ubuntu20|ubuntu22' &> /dev/null && ERROR "You could only install on os: centos7、centos8、ubuntu16、ubuntu18、ubuntu20、ubuntu22"

# environments
serviceName="minio"
webPort="9001"
minio_root_user_="admin"
minio_root_password="password"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

downloadUrl="http://dl.minio.org.cn/server/minio/release/linux-amd64/minio"
EXEC "curl -SsL $downloadUrl -o /data/$$_minio"
EXEC "chmod +x /data/$$_minio && sleep 2"
EXEC "version=`/data/$$_minio -v | awk '{print $NF}'`"
installPath="/data/${serviceName}-${version}"

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{bin,data,logs}"

# install minio server and client
EXEC "mv /data/$$_minio $installPath/bin/minio"
EXEC "curl -SsL http://dl.minio.org.cn/client/mc/release/linux-amd64/mc -o $installPath/bin/mc && chmod +x $installPath/bin/mc"

# register bin
EXEC "ln -fs $installPath/bin/* /usr/local/bin/"
EXEC "minio -v" && minio -v

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

installPath="${installPath}"
timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

minio server \${installPath}/data --console-address ":$webPort" &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

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
ExecStart=/bin/bash $installPath/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# set root_user and root_password
cat > /etc/profile << EOF
export MINIO_ROOT_USER=$minio_root_user
export MINIO_ROOT_PASSWORD=$minio_root_password
EOF

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "${serviceName} version: $version"
YELLOW "data: $installPath/data"
YELLOW "log: $installPath/logs"
YELLOW "web port: $webPort"
YELLOW "web user: $minio_root_user"
YELLOW "web password: $minio_root_password"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
