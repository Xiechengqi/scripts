#!/usr/bin/env bash

#
# 2024/06/26
# xiechengqi
# github: https://github.com/bacalhau-project/bacalhau
# cmd: curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/bacalhau/install.sh | bash
#

source /etc/profile
# BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu20|ubuntu22' &> /dev/null && ERROR "You could only install on os: ubuntu20、ubuntu22"

# environment
serviceName="bacalhau"
installPath="/data/${serviceName}"
EXEC "which jq"
# https://github.com/bacalhau-project/bacalhau/releases/download/v1.3.2/bacalhau_v1.3.2_linux_amd64.tar.gz
downloadUrl=$(curl -SsL https://api.github.com/repos/bacalhau-project/bacalhau/releases/latest | jq -r .assets[].browser_download_url | grep -E 'linux_amd64.tar.gz$' | head -1)
binaryName="bacalhau"

# check
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} has been installed ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,data,logs}"

# download
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}/bin/"
EXEC "chmod +x ${installPath}/bin/${binaryName}"
EXEC "ln -fs ${installPath}/bin/${binaryName} /usr/local/bin/${binaryName}"

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env /bash


export installPath="${installPath}"
export LOG_TYPE="json"
export LOG_LEVEL="debug"
export BACALHAU_SERVE_IPFS_PATH="\${installPath}/ipfs"
export BACALHAU_DIR="\${installPath}/data"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/bacalhau serve --node-type compute,requester --peer none --private-internal-ipfs=false &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=Lilypad V2 Bacalhau
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
