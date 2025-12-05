#!/usr/bin/env bash

#
# 2024/06/27
# xiechengqi
# doc: https://nubit.sh | https://nubit.sh/start.sh
# cmd: curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Nubit/install-light-node.sh | bash
#

source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu20|ubuntu22' &> /dev/null && ERROR "You could only install on os: ubuntu20、ubuntu22"

# environment
export NETWORK="nubit-alphatestnet-1"
export NODE_TYPE="light"
export VALIDATOR_IP="validator.nubit-alphatestnet-1.com"
export AUTH_TYPE="admin"
export serviceName="nubit"
export installPath="/data/${serviceName}"
export dataPath="/root/.nubit-${NODE_TYPE}-${NETWORK}"
export downloadUrl="https://nubit.sh/nubit-bin/nubit-node-linux-x86_64.tar"
export snapshotUrl="https://nubit.sh/nubit-data/lightnode_data.tgz"
# check
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} has been installed ..." && return 0

# check install path
EXEC "rm -rf ${installPath} ${dataPath} /root/.nubit-validator"
EXEC "mkdir -p ${installPath}/{bin,logs} ${dataPath}"

# download binary
EXEC "curl -SsL ${downloadUrl} | tar x --strip-components 2 -C ${installPath}/bin/"
EXEC "ln -fs ${installPath}/bin/nubit /usr/local/bin/nubit"
EXEC "ln -fs ${installPath}/bin/nkey /usr/local/bin/nkey"

# download snapshot
EXEC "curl -SsL ${snapshotUrl} | tar zx -C ${dataPath}"

mnemonic=$(${installPath}/bin/nubit $NODE_TYPE init --p2p.network $NETWORK | grep -A 1 "MNEMONIC (save this somewhere safe!!!):" | tail -1)
[ ".${mnemonic}" = "." ] && ERROR "Init fail, cannot get mnemonic, eixt ..."
INFO "${installPath}/bin/nkey list --p2p.network $NETWORK --node.type $NODE_TYPE"
address=$(${installPath}/bin/nkey list --p2p.network $NETWORK --node.type $NODE_TYPE | grep -E 'address:' | awk '{print $NF}')
pubkey=$(${installPath}/bin/nkey list --p2p.network $NETWORK --node.type $NODE_TYPE | grep -E 'pubkey:' | awk -F '"' '{print $(NF-1)}')
YELLOW "Address: ${address}"
YELLOW "pubkey: ${pubkey}"
YELLOW "Mnemonic: ${mnemonic}"
echo "${address}: ${pubkey},${mnemonic}"
INFO "${installPath}/bin/nubit $NODE_TYPE auth $AUTH_TYPE --node.store ${dataPath}" && ${installPath}/bin/nubit $NODE_TYPE auth $AUTH_TYPE --node.store ${dataPath}
EXEC "sleep 5"

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env /bash

export installPath="${installPath}"
export HOME="/root"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/nubit $NODE_TYPE start --p2p.network $NETWORK --core.ip $VALIDATOR_IP --metrics.endpoint otel.nubit-alphatestnet-1.com:4318 --rpc.skip-auth &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=Nubit
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
