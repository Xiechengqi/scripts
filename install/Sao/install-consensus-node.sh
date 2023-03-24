#!/usr/bin/env bash

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'centos|ubuntu' &> /dev/null && ERROR "You could only install on os: centos、ubuntu"

# environments
serviceName="saod"
installPath="/data/${serviceName}"
binaryName="saod"
version=${1-"v0.1.3"}
binaryDownloadUrl="https://github.com/SAONetwork/sao-consensus/releases/download/${version}/saod-linux"
genesisDownloadUrl="https://github.com/SAONetwork/sao-consensus/releases/download/${version}/genesis.json"
configDownloadUrl="https://github.com/SAONetwork/sao-consensus/releases/download/${version}/config.toml"
appDownloadUrl="https://github.com/SAONetwork/sao-consensus/releases/download/${version}/app.toml"
# configDownloadUrl="http://205.204.75.250:5000/sao/config.tar.gz"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,home,logs}"

# download binary
EXEC "curl -SsL ${binaryDownloadUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"
EXEC "ln -fs ${installPath}/bin/${binaryName} /usr/local/bin/${binaryName}"
INFO "saod version" && saod version

# download config
# EXEC "curl -SsL ${configDownloadUrl} | tar zx -C ${installPath}/home"
EXEC "mkdir ${installPath}/home/config"
EXEC "curl -SsL ${genesisDownloadUrl} -o ${installPath}/home/config/genesis.json"
EXEC "curl -SsL ${configDownloadUrl} -o ${installPath}/home/config/config.toml"
EXEC "curl -SsL ${appDownloadUrl} -o ${installPath}/home/config/app.toml"

# prometheus metrics
sed -i 's/prometheus = false/prometheus = true/g' ${installPath}/home/config/config.toml

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

monikerName="\$(hostname)"
installPath="${installPath}"
timestamp=\$(date +%Y%m%d-%H%M%S)
touch \$installPath/logs/\${timestamp}.log && ln -fs \$installPath/logs/\${timestamp}.log \$installPath/logs/latest.log

\${installPath}/bin/${binaryName} start --home \${installPath}/home --moniker \${monikerName} &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=SAO Consensus Node
Documentation=https://github.com/SaoNetwork/sao-consensus
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

# alias
sed -i '/alias saod/d' /etc/profile
cat >> /etc/profile << EOF
alias saod="saod --home ${installPath}/home"
EOF

# INFO
YELLOW "${serviceName} version: ${version}"
YELLOW "log: tail -f $installPath/logs/latest.log"
YELLOW "check cmd: saod status"
YELLOW "control cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
