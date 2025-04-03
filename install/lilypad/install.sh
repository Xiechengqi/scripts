#!/usr/bin/env bash

#
# 2024/06/26
# xiechengqi
# github: https://github.com/lilypad-tech/lilypad
# doc: https://docs.lilypad.tech/lilypad/hardware-providers/run-a-node#disconnecting-a-node
# cmd: curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/lilypad/install.sh | bash
#

source /etc/profile
BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
# BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu20|ubuntu22' &> /dev/null && ERROR "You could only install on os: ubuntu20、ubuntu22"

# check param
export WEB3_PRIVATE_KEY=$1
[ ".${WEB3_PRIVATE_KEY}" = "." ] && ERROR "Less param WEB3_PRIVATE_KEY, exit ..."

# environment
serviceName="lilypad"
installPath="/data/${serviceName}"
if echo ${osInfo} | grep 'ubuntu22' &> /dev/null
then
EXEC "which jq"
downloadUrl=$(curl -SsL https://api.github.com/repos/lilypad-tech/lilypad/releases/latest | jq -r .assets[].browser_download_url | grep -E 'linux-amd64$' | head -1)
else
downloadUrl="https://install.xiechengqi.top/lilypad"
fi
binaryName="lilypad"

# check
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} has been installed ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,data,logs}"

# download
EXEC "curl -SsL ${downloadUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"
EXEC "ln -fs ${installPath}/bin/${binaryName} /usr/local/bin/${binaryName}"

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env /bash

export installPath="${installPath}"
export LOG_TYPE="json"
export LOG_LEVEL="debug"
export HOME="/data/bacalhau/data"
export OFFER_GPU="1"

# WEB3_PRIVATE_KEY=<YOUR_PRIVATE_KEY> (the private key from a NEW MetaMask wallet FOR THE COMPUTE NODE)
export WEB3_PRIVATE_KEY=${WEB3_PRIVATE_KEY}

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/lilypad resource-provider &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=Lilypad V2 Resource Provider GPU
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
ExecStart=/bin/bash ${installPath}/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
TimeoutSec=300
RestartSec=90
Restart=always

[Install]
WantedBy=multi-user.target
EOF
EXEC "ln -fs ${installPath}/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName} && systemctl start ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# info
YELLOW "${serviceName}"
YELLOW "install: ${installPath}"
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"

}

main $@
