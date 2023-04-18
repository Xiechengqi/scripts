#!/usr/bin/env bash

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# environments
serviceName="sao-node"
installPath="/root/.sao-node"
binaryName="saonode"
export BRANCH=${1}
[ ".${BRANCH}" = "." ] && ERROR "Less Params BRANCH"
export SAO_CHAIN_API=${2}
[ ".${SAO_CHAIN_API}" = "." ] && ERROR "Less Params BRSAO_CHAIN_API"

binaryDownloadUrl="http://8.222.210.19:5000/sao-node/${BRANCH}/saonode"

# increase udp maximum buffer
EXEC "sysctl -w net.core.rmem_max=2500000"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,logs}"

# download binary
EXEC "curl -SsL ${binaryDownloadUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"
EXEC "ln -fs ${installPath}/bin/${binaryName} /usr/local/bin/${binaryName}"
INFO "${binaryName} -v" && ${binaryName} -v

# config
EXEC "sed -i /SAO_CHAIN_API/d /etc/profile"
cat >> /etc/profile << EOF
export SAO_CHAIN_API=${SAO_CHAIN_API}
EOF
source /etc/profile

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
YELLOW "  Load environment: source /etc/profile"
YELLOW "  Create a address: saonode account create --key-name [account_name]"
YELLOW "  Get token: https://faucet.testnet.sao.network/"
YELLOW "  Check new address: saonode account list"
YELLOW "  Init node to join network: saonode --chain-address ${SAO_CHAIN_API} init --creator [address]"
YELLOW "  Start service: systemctl start ${serviceName}"

}

main $@
