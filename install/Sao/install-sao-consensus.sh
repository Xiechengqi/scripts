#!/usr/bin/env bash

#
# 2023/04/18
# xiechengqi
# deploy saod
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu' &> /dev/null && ERROR "You could only install on os: ubuntu"

### ENV
export BASE_URL="http://8.222.210.19:5000"
export BRANCH=${1}
[ ".${BRANCH}" = "." ] && ERROR "Less Params BRANCH"
echo "BRANCH: ${BRANCH}"
# export PUBLIC_RPC="8.214.46.204:26657" # sao-testnet1
# export PUBLIC_RPC="205.204.75.250:36657" # 压测环境
export PUBLIC_RPC=${2}
[ ".${PUBLIC_RPC}" = "." ] && ERROR "Less Params PUBLIC_RPC"
echo "PUBLIC RPC: ${PUBLIC_RPC}"
export CHAIN_ID=${3-""}
[ "${CHAIN_ID}." != "." ] && chainIdOption="--chain-id=${CHAIN_ID}" || chainIdOption=""

serviceName="saod"
installPath="/root/.sao"

### 下载依赖
EXEC "apt install -y jq"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/logs"

### 下载 cosmovisor
if ! which cosmovisor
then
EXEC "curl -SsL ${BASE_URL}/cosmovisor/v1.3.0/cosmovisor -o /usr/local/bin/cosmovisor"
fi
EXEC "chmod +x /usr/local/bin/cosmovisor"

### 创建 cosmovisor 目录和环境变量文件
EXEC "rm -rf /data/cosmovisor"
EXEC "mkdir -p /data/cosmovisor/{data,cosmovisor,backup}"
cat >> /etc/profile << EOF
export DAEMON_NAME=saod
export DAEMON_HOME=/data/cosmovisor
export DAEMON_DATA_BACKUP_DIR=/data/cosmovisor/backup
export PATH=\$DAEMON_HOME/cosmovisor/current/bin:\$PATH
EOF
INFO "cat /etc/profile" && cat /etc/profile
source /etc/profile

### 下载二进制文件
export SAOD_VERSION="v0.1.3"
EXEC "rm -rf $(which saod)"
EXEC "curl -SsL ${BASE_URL}/sao-consensus/${BRANCH}/saod -o /tmp/saod"
EXEC "chmod +x /tmp/saod"

### 初始化 cosmovisor
INFO "cosmovisor init /tmp/saod" && cosmovisor init /tmp/saod || exit 1
INFO "cosmovisor version" && cosmovisor version

### 初始化网络
export NODE_NAME="$(hostname)"
INFO "cosmovisor run init ${NODE_NAME} ${chainIdOption}" && cosmovisor run init ${NODE_NAME} ${chainIdOption} || exit 1

### 修改 keyring-backend 为 test
EXEC "cosmovisor run config keyring-backend test"

### 下载创世区块文件 genesis.json
curl -SsL "${PUBLIC_RPC}/genesis" | jq '.result.genesis' > ${installPath}/config/genesis.json

### 设置种子节点、p2p 节点和当前安装的是否为种子节点
export SEEDS=""
export PEERS="$(saod status -n tcp://${PUBLIC_RPC} | jq -r .NodeInfo.id)@$(echo ${PUBLIC_RPC} | awk -F ':' '{print $1}'):$(saod status -n tcp://${PUBLIC_RPC} | jq -r .NodeInfo.listen_addr | awk -F ':' '{print $NF}')" && echo "PEERS: $PEERS"
export SEED_MODE="false"
sed -i -e 's|^seeds *=.*|seeds = "'$SEEDS'"|;' ${installPath}/config/config.toml
sed -i -e 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' ${installPath}/config/config.toml
sed -i -e "s/^seed_mode *=.*/seed_mode = \"$SEED_MODE\"/" ${installPath}/config/config.toml

### 为了降低磁盘空间使用率，可以使用以下配置设置修剪
export PRUNING="custom"
export PRUNING_KEEP_RECENT="10"
export PRUNING_INTERVAL="10"
sed -i -e "s/^pruning *=.*/pruning = \"$PRUNING\"/" ${installPath}/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$PRUNING_KEEP_RECENT\"/" ${installPath}/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$PRUNING_INTERVAL\"/" ${installPath}/config/app.toml

# prometheus metrics
sed -i 's/prometheus = false/prometheus = true/g' ${installPath}/config/config.toml

cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

monikerName="${NODE_NAME}"
installPath="/root/.sao"
timestamp=\$(date +%Y%m%d-%H%M%S)
touch \$installPath/logs/\${timestamp}.log && ln -fs \$installPath/logs/\${timestamp}.log \$installPath/logs/latest.log
cosmovisor run start --moniker \${monikerName} &> \${installPath}/logs/latest.log
EOF

EXEC "chmod +x ${installPath}/start.sh"
cat > ${installPath}/saod.service << EOF
[Unit]
Description=SAO Consensus Node
Documentation=https://github.com/SaoNetwork/sao-consensus
After=network.target
[Service]
User=root
Group=root
ExecStart=bash /root/.sao/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=2
LimitNOFILE=4096
[Install]
WantedBy=multi-user.target
EOF
EXEC "ln -fs ${installPath}/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName} && systemctl start ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# INFO
YELLOW "${serviceName} version: ${SAOD_VERSION}"
YELLOW "log: tail -f $installPath/logs/latest.log"
YELLOW "check cmd: saod status"
YELLOW "control cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
