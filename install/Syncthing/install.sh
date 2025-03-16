#!/usr/bin/env bash

#
# xiechengqi
# 2025/03/16
# install syncthing
# doc: https://apt.syncthing.net/
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20|ubuntu22' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20、ubuntu22"

# environment
serviceName="syncthing"
installPath="/data/${serviceName}"
port="8384"

# check servcie
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/logs"

# install
EXEC "cd ${installPath}"
EXEC "mkdir -p /etc/apt/keyrings && curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg"
EXEC "echo 'deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable' > /etc/apt/sources.list.d/syncthing.list"
EXEC "apt update"
EXEC "apt install syncthing -y"
INFO "syncthing serve --version" && syncthing serve --version || exit 1

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

export installPath="${installPath}"
export HOME="/root"
export PORT=${port}
mkdir -p \${installPath}/logs
timestamp=\$(TZ=UTC-8 date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

/usr/bin/syncthing serve --no-browser --no-restart --logflags=0 --gui-address=0.0.0.0:\${PORT} &>> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=Syncthing
After=syslog.target
After=network.target

[Service]
ExecStart=/bin/bash ${installPath}/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
TimeoutSec=300
RestartSec=90
Restart=always

# Hardening
ProtectSystem=full
PrivateTmp=true
SystemCallArchitectures=native
MemoryDenyWriteExecute=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
EXEC "ln -fs ${installPath}/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName} && systemctl start ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# info
YELLOW "${serviceName}"
YELLOW "install path: ${installPath}"
YELLOW "log cmd: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
