#!/usr/bin/env bash

#
# 2023/05/31
# xiechengqi
# deploy saod
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

### 下载二进制文件
export SAOD_VERSION=${1-"v0.1.4"}
export BINARY="saod"
export SERVICE_NAME="saod"
export BINARY_URL="https://github.com/SAONetwork/sao-consensus/releases/download/${SAOD_VERSION}/saod-linux"
export INSTALL_PATH="${HOME}/.sao"
export PUBLIC_RPC=${2-"rpc-testnet-node0.sao.network"}
export PEERS=${3-"63284431d62d0b271bd4fd406ff1e0d975fa603c@8.219.208.132:26656,2230361011f7d55e359659a90a0f3528137449d9@8.222.241.135:26656"}
### 检查 PUBLIC_PRC
curl -SsL ${PUBLIC_RPC}/status | jq -r .result.sync_info.catching_up | grep 'false' &> /dev/null || ERROR "The block height of ${PUBLIC_RPC} has not been synchronized, please check"
export CHAIN_ID=$(curl -SsL ${PUBLIC_RPC}/status | jq -r .result.node_info.network)

### 检查服务
EXEC "! systemctl is-active ${SERVICE_NAME}"

### 检查依赖
EXEC "which jq"
EXEC "which lz4"

### 初始化安装目录
EXEC "mkdir -p ${INSTALL_PATH}/{bin,logs}"

### 下载可执行文件
EXEC "curl -SsL ${BINARY_URL} -o ${INSTALL_PATH}/bin/${BINARY}"
EXEC "chmod +x ${INSTALL_PATH}/bin/${BINARY}"
EXEC "rm -f /usr/local/bin/${BINARY}"
EXEC "ln -fs ${INSTALL_PATH}/bin/${BINARY} /usr/local/bin/${BINARY}"
INFO "which ${BINARY} && ${BINARY} version" && which ${BINARY} && ${BINARY} version

### 初始化网络
## This will generate, in the $HOME/.sao folder, the following files:
## config/app.toml: Application-related configuration file.
## config/client.toml: Client-oriented configuration file (not used when running a node).
## config/config.toml: Tendermint-related configuration file.
## config/genesis.json: The network's genesis file.
## config/node_key.json: Private key to use for node authentication in the p2p protocol.
## config/priv_validator_key: Private key to use as a validator in the consensus protocol.
## data: The node's database.
export NODE_NAME="$(hostname)"
EXEC "${BINARY} init ${NODE_NAME} --chain-id=${CHAIN_ID} --overwrite"

### 修改 keyring-backend 为 test
EXEC "${BINARY} config keyring-backend test"

### 修改 client-id 为 ${CHAIN_ID}
EXEC "${BINARY} config chain-id ${CHAIN_ID}"

### 设置 moniker
INFO "Modify config.toml [moniker] ..."
sed -i -e "s/^moniker *=.*/moniker = \"$NODE_NAME\"/" ${INSTALL_PATH}/config/config.toml

### 设置 p2p 节点
INFO "Modify config.toml [PEERS]  ..."
sed -i -e 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' ${INSTALL_PATH}/config/config.toml

### 开启 prometheus metric
INFO "Modify config.toml [prometheus] ..."
sed -i -e "s/prometheus = false/prometheus = true/" ${INSTALL_PATH}/config/config.toml

### 下载创世区块文件 genesis.json
curl -SsL "${PUBLIC_RPC}/genesis" | jq '.result.genesis' > ${INSTALL_PATH}/config/genesis.json

### 设置裁剪，降低磁盘空间使用率
INFO "Modify app.toml [pruning] [pruning-keep-recent] [pruning-keep-every] [pruning-interval] ..."
export PRUNING="custom"
export PRUNING_KEEP_RECENT="5000"
export PRUNING_KEEP_EVERY="1000"
export PRUNING_INTERVAL="100"
sed -i -e "s/^pruning *=.*/pruning = \"$PRUNING\"/" ${INSTALL_PATH}/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$PRUNING_KEEP_RECENT\"/" ${INSTALL_PATH}/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$PRUNING_KEEP_EVERY\"/" ${INSTALL_PATH}/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$PRUNING_INTERVAL\"/" ${INSTALL_PATH}/config/app.toml

# 重置安装目录
[ -f ${INSTALL_PATH}/data/priv_validator_state.json ] && EXEC "cp -f ${INSTALL_PATH}/data/priv_validator_state.json ${INSTALL_PATH}/priv_validator_state.json.backup"
EXEC "rm -rf ${INSTALL_PATH}/data"
EXEC "${BINARY} tendermint unsafe-reset-all --home ${INSTALL_PATH} --keep-addr-book"

### 设置从 snapshot 同步块高
INFO "Sync from snapshot ..."
sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1false|" ${INSTALL_PATH}/config/config.toml
SNAP_NAME=$(curl -s https://ss-t.sao.nodestake.top/ | egrep -o ">20.*\.tar.lz4" | tr -d ">")
INFO "curl -o - -L https://ss-t.sao.nodestake.top/${SNAP_NAME}  | lz4 -c -d - | tar -x -C ${INSTALL_PATH}"
curl -o - -L https://ss-t.sao.nodestake.top/${SNAP_NAME}  | lz4 -c -d - | tar -x -C ${INSTALL_PATH} || ERROR "download and tar snapshot error ..."

[ -f ${INSTALL_PATH}/priv_validator_state.json.backup ] && EXEC "mv ${INSTALL_PATH}/priv_validator_state.json.backup ${INSTALL_PATH}/data/priv_validator_state.json"


# 创建 start.sh
cat > ${INSTALL_PATH}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

export installPath="${INSTALL_PATH}"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \$installPath/logs/\${timestamp}.log \${installPath}/logs/latest.log

/usr/local/bin/${BINARY} start &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${INSTALL_PATH}/start.sh"

### 配置 systemd 运行
cat > ${INSTALL_PATH}/${SERVICE_NAME}.service << EOF
[Unit]
Description=SAO Consensus Node
Documentation=https://github.com/SaoNetwork/sao-consensus
After=network.target
[Service]
User=root
Group=root
ExecStart=/bin/bash ${INSTALL_PATH}/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
EXEC "rm -f /lib/systemd/system/${SERVICE_NAME}.service"
EXEC "ln -fs ${INSTALL_PATH}/${SERVICE_NAME}.service /lib/systemd/system/${SERVICE_NAME}.service"

### 启动 service
EXEC "systemctl daemon-reload && systemctl enable ${SERVICE_NAME} && systemctl start ${SERVICE_NAME}"
EXEC "systemctl status ${SERVICE_NAME} --no-pager" && systemctl status ${SERVICE_NAME} --no-pager

# INFO
YELLOW "${SERVICE_NAME} version: ${SAOD_VERSION}"
YELLOW "log: tail -f ${INSTALL_PATH}/logs/latest.log"
YELLOW "check cmd: ${BINARY} status"
YELLOW "control cmd: systemctl [stop|start|restart|reload] ${SERVICE_NAME}"
