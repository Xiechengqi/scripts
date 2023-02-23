#!/usr/bin/env bash

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# environments
serviceName="sao-faucet"
installPath="/data/${serviceName}"
binaryName="faucet-api"
binaryDownloadUrl="http://205.204.75.250:5000/sao/${binaryName}"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,logs}"

# download binary
EXEC "curl -SsL ${binaryDownloadUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"
EXEC "ln -fs ${installPath}/bin/${binaryName} /usr/local/bin/${binaryName}"
INFO "${binaryDownloadUrl} version" && ${binaryDownloadUrl} version

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env /bash
source /etc/profile

export chainAddress="http://127.0.0.1:26657"
export FAUCET_SECRET_KEY="${FAUCET_SECRET_KEY}"
export FAUCET_FROM="${FAUCET_FROM}"

installPath="/data/sao-faucet"

timestamp=\$(date +%Y%m%d%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/faucet-api &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=SAO Faucet
Documentation=https://github.com/SaoNetwork/faucet-api
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
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
EXEC "ln -fs ${installPath}/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# INFO
YELLOW "log: tail -f $installPath/logs/latest.log"
YELLOW "control cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
