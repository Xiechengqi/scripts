#!/usr/bin/env bash
#
# xiechengqi
# 2025/06/08
# install socks5 localhost:1080
# usage: curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/refs/heads/master/install/Socks-Proxy/install.sh | sudo bash
#

source /etc/profile
# BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

# check os
osInfo=`get_os` && INFO "current os: $osInfo"

# environment
export serviceName="socks-proxy"
export installPath="/data/${serviceName}"
port=${1-"1080"}

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} has been installed ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/logs"

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

timestamp=\$(date +%Y%m%d-%H%M%S)
installPath="${installPath}"
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

while :
do
if ! timeout 3 curl -x socks://localhost:${port} https://checkip.amazonaws.com &> /dev/null && ! ss -plunt | grep ':${port}' &> /dev/null
then
echo -e \$(TZ=UTC-8 date +"%Y-%m-%d %H:%M:%S")" set socks5 localhost:${port} ... " >> \${installPath}/logs/latest.log
ssh -p 22 -f -N -D *:${port} root@localhost && echo "[ok]" >> \${installPath}/logs/latest.log || echo "[fail]" >> \${installPath}/logs/latest.log
fi
echo \$(TZ=UTC-8 date +"%Y-%m-%d %H:%M:%S")" sleep 1m ..." >> \${installPath}/logs/latest.log
sleep 1m
done
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
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
YELLOW "${serviceName}"
YELLOW "install: ${installPath}"
YELLOW "socks5 port: ${port}"
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
