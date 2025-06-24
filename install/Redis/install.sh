#!/usr/bin/env bash

#
# xiechengqi
# 2025/05/30
# make install redis
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Redis/install.sh | sudo bash
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

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20|ubuntu22' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20、ubuntu22"

# environment
serviceName="redis"
version=${1-"6.2.9"}
installPath="/data/${serviceName}"
[ "${countryCode}" = "China" ] && downloadUrl="https://mirrors.huaweicloud.com/redis/redis-${version}.tar.gz" || downloadUrl="http://download.redis.io/releases/redis-${version}.tar.gz"
port="6379"  # redis default port

# check servcie
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{data,logs}"

# download tarball
EXEC "curl -sSL ${downloadUrl} | tar zx --strip-components 1 -C ${installPath}"

# install gcc
EXEC "apt update && apt install -y build-essential"

# install
EXEC "cd ${installPath}"
EXEC "make && make install"

# conf
sed -i '/^requirepass/d' ${installPath}/redis.conf
sed -i '/^bind/d' ${installPath}/redis.conf
sed -i '/^port/d' ${installPath}/redis.conf
sed -i '/^dir/d' ${installPath}/redis.conf
sed -i '/^logfile/d' ${installPath}/redis.conf
cat >> ${installPath}/redis.conf << EOF

bind 0.0.0.0
port ${port}
dir ${installPath}/data
logfile "${installPath}/logs/latest.log"
EOF

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

export installPath="${installPath}"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

redis-server ${installPath}/redis.conf
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=Redis Server
After=syslog.target
After=network.target

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

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName} && systemctl start ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# info
YELLOW "${serviceName} version: ${version}"
YELLOW "install path: ${installPath}"
YELLOW "config path: ${installPath}/redis.conf"
YELLOW "data path: ${installPath}/data"
YELLOW "log cmd: tail -f ${installPath}/logs/redis.log"
YELLOW "connect cmd: redis-cli -h 127.0.0.1 -p ${port}"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
