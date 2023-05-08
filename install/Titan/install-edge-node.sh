#!/usr/bin/env bash

#
# 2023/05/08
# xiechengqi
# install Titan Edge Node
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# environment
export LOCATOR_API_INFO="https://120.78.83.177:5000"
export AREA_ID="CN-GD-Shenzhen"
serviceName="titan-edge-node"
installPath="/data/${serviceName}"
binaryName="titan-edge"
binaryUrl="https://install.xiechengqi.top/titan/${binaryName}"

# check servcie
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf $installPath"
EXEC "mkdir -p $installPath/{bin,logs}"

# download tarball
EXEC "curl -k -SsL ${binaryUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"
EXEC "ln -fs ${installPath}/bin/${binaryName} /usr/local/bin/${binaryName}"

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

export installPath="${installPath}"
export LOCATOR_API_INFO=${LOCATOR_API_INFO}

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \$installPath/logs/\${timestamp}.log \${installPath}/logs/latest.log

${binaryName} run &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > $installPath/${serviceName}.service << EOF
[Unit]
Description=Titan CDN+ network
Documentation=https://github.com/Filecoin-Titan/titan
After=network.target
[Service]
User=root
Group=root
ExecStart=/bin/bash $installPath/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=3
LimitNOFILE=100000
[Install]
WantedBy=multi-user.target
EOF
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
EXEC "ln -fs ${installPath}/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName}"

# info
YELLOW "import key: ${binaryName} key import --path private.key"
YELLOW "config: ${binaryName} config set --node-id=your_node_id --area-id=${AREA_ID}"
YELLOW "start: systemctl start ${serviceName}"
YELLOW "log cmd: tail -f ${installPath}/logs/redis.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"

}

main $@
