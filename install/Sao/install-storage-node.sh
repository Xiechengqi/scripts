#!/usr/bin/env bash

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'centos7|ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: centos7、ubuntu18、ubuntu20"

# environments
serviceName="sao-node"
installPath="/data/${serviceName}"
binaryName="saonode"
binaryDownloadUrl="http://205.204.75.250:5000/sao/${binaryName}"

# check saod service
EXEC "systemctl is-active saod && ss -plunt | grep 26657"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,data,storage,home,logs}"

# download binary
EXEC "curl -SsL ${binaryDownloadUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"
EXEC "ln -fs ${installPath}/bin/${binaryName} /usr/local/bin/${binaryName}"
INFO "${binaryName} -v" && ${binaryName} -v

# config
EXEC "sed -i /SAO_CHAIN_API/d /etc/profile"
EXEC "sed -i /SAO_NODE_PATH/d /etc/profile"
EXEC "sed -i /SAO_KEYRING_HOME/d /etc/profile"
cat >> /etc/profile << EOF
export SAO_CHAIN_API=http://127.0.0.1:26657
export SAO_NODE_PATH=${installPath}/storage
export SAO_KEYRING_HOME=${installPath}/home
EOF

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

installPath="${installPath}"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \$installPath/logs/\${timestamp}.log && ln -fs \$installPath/logs/\${timestamp}.log \$installPath/logs/latest.log

\${installPath}/bin/${binaryName} run &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=SAO Storage Node
Documentation=https://github.com/SaoNetwork/sao-node
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
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
EXEC "ln -fs ${installPath}/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName}"
INFO "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# INFO
YELLOW "You need init first, then start service!"
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "control cmd: systemctl [stop|start|restart|reload] ${serviceName}"
YELLOW "Init Cmd:"
INFO "  Load environment: source /etc/profile"
INFO "  Create a address: saonode account create"
INFO "  Init node to join network: saonode init --creator [address]"
INOF "  Start service: systemctl start ${serviceName}"

}

main $@
