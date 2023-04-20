#!/usr/bin/env bash

#
# 2023/04/20
# xiechengqi
# install GreenField Testnet Node
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu22' &> /dev/null && ERROR "You could only install on os: ubuntu22"

### ENV
export VERSION="v0.1.1"
export BIN="gnfd"
export BASE_URL="http://8.222.210.19:5000"
installPath="/root/.gnfd"
serviceName="gnfd"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

### 检查并创建目录
EXEC "! ls ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,config,logs}"

### 下载依赖
which jq &> /dev/null || EXEC "apt install -y jq"

### 下载二进制文件
EXEC "curl -SsL ${BASE_URL}/greenfield/${VERSION}/${BIN} -o ${installPath}/bin/${BIN}"
EXEC "chmod +x ${installPath}/bin/${BIN}"
EXEC "ln -fs ${installPath}/bin/${BIN} /usr/local/bin/${BIN}"
INFO "${BIN} version" && ${BIN} version

### 下载配置文件 app.toml、config.toml、client.toml
EXEC "curl -SsL ${BASE_URL}/greenfield/${VERSION}/config/app.toml -o ${installPath}/config/app.toml"
EXEC "curl -SsL ${BASE_URL}/greenfield/${VERSION}/config/config.toml -o ${installPath}/config/config.toml"
EXEC "curl -SsL ${BASE_URL}/greenfield/${VERSION}/config/client.toml -o ${installPath}/config/client.toml"

### 下载创世区块文件 genesis.json
# rpc 26657: https://gnfd-testnet-fullnode-tendermint-us.bnbchain.org or https://gnfd-testnet-fullnode-tendermint-us.nodereal.io
export PUBLIC_RPC="https://gnfd-testnet-fullnode-tendermint-us.bnbchain.org"
EXEC "curl -SsL ${PUBLIC_RPC}/genesis | jq .result.genesis > ${installPath}/config/genesis.json"

### 设置 p2p 节点
# export PEERS="$(saod status -n tcp://${PUBLIC_RPC} | jq -r .NodeInfo.id)@$(echo ${PUBLIC_RPC} | awk -F ':' '{print $1}'):$(saod status -n tcp://${PUBLIC_RPC} | jq -r .NodeInfo.listen_addr | awk -F ':' '{print $NF}')" && echo "PEERS: $PEERS"
# sed -i -e 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' ${installPath}/config/config.toml

### 为了降低磁盘空间使用率，可以使用以下配置设置修剪
export PRUNING="custom"
export PRUNING_KEEP_RECENT="10"
export PRUNING_INTERVAL="10"
sed -i -e "s/^pruning *=.*/pruning = \"$PRUNING\"/" ${installPath}/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$PRUNING_KEEP_RECENT\"/" ${installPath}/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$PRUNING_INTERVAL\"/" ${installPath}/config/app.toml

### 启动脚本
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

monikerName="$(hostname)"
installPath="${installPath}"
timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/${BIN} start --moniker \${monikerName} &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

### 配置 systemd 运行
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=GreenField Testnet Node
Documentation=https://github.com/bnb-chain/greenfield
After=network.target
[Service]
User=root
Group=root
ExecStart=/bin/bash ${installPath}/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=2
LimitNOFILE=4096
[Install]
WantedBy=multi-user.target
EOF
EXEC "rm -f /etc/systemd/system/${serviceName}.service"
EXEC "ln -fs ${installPath}/${serviceName}.service /etc/systemd/system/${serviceName}.service"

### 启动 service
EXEC "systemctl daemon-reload && systemctl enable --now ${serviceName}"
INFO "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# INFO
YELLOW "${serviceName} version: ${VERSION}"
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "check cmd: ${BIN} status"
YELLOW "control cmd: systemctl [stop|start|restart|reload] ${serviceName}"

}

main $@
