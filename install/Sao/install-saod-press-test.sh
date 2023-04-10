#!/usr/bin/env bash

### 下载依赖
apt install -y jq

### 下载 cosmovisor
if ! which cosmovisor
then
curl -SsL 'https://github.com/cosmos/cosmos-sdk/releases/download/cosmovisor%2Fv1.3.0/cosmovisor-v1.3.0-linux-amd64.tar.gz' | tar zx -C /tmp
mv /tmp/cosmovisor /usr/local/bin/
chmod +x /usr/local/bin/cosmovisor
fi

### 创建 cosmovisor 目录和环境变量文件
rm -rf /data/cosmovisor
mkdir -p /data/cosmovisor/{data,cosmovisor,backup}
cat >> /etc/profile << EOF
export DAEMON_NAME=saod
export DAEMON_HOME=/data/cosmovisor
export DAEMON_DATA_BACKUP_DIR=/data/cosmovisor/backup
export PATH=\$DAEMON_HOME/cosmovisor/current/bin:\$PATH
EOF
source /etc/profile

### 下载二进制文件
export SAOD_VERSION="v0.1.3"
rm -rf $(which saod)
curl -SsL https://github.com/SAONetwork/sao-consensus/releases/download/${SAOD_VERSION}/saod-linux -o /tmp/saod
chmod +x /tmp/saod

### 初始化 cosmovisor
cosmovisor init /tmp/saod
cosmovisor version

### 初始化网络
export NODE_NAME="$(hostname)"
cosmovisor run init ${NODE_NAME}

### 修改 keyring-backend 为 test
cosmovisor run config keyring-backend test

### 下载创世区块文件 genesis.json
# curl -SsL https://github.com/SAONetwork/sao-consensus/releases/download/${SAOD_VERSION}/genesis.json -o ${HOME}/.sao/config/genesis.json
export PUBLIC_RPC="205.204.75.250:36657" # 压测环境
curl -SsL "${PUBLIC_RPC}/genesis" | jq '.result.genesis' > ${HOME}/.sao/config/genesis.json

### 设置种子节点、p2p 节点和当前安装的是否为种子节点
export SEEDS=""
export PEERS="$(saod status -n tcp://${PUBLIC_RPC} | jq -r .NodeInfo.id)@$(echo ${PUBLIC_RPC} | awk -F ':' '{print $1}'):$(saod status -n tcp://${PUBLIC_RPC} | jq -r .NodeInfo.listen_addr | awk -F ':' '{print $NF}')" && echo "PEERS: $PEERS"
export SEED_MODE="false"
sed -i -e 's|^seeds *=.*|seeds = "'$SEEDS'"|;' ${HOME}/.sao/config/config.toml
sed -i -e 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' ${HOME}/.sao/config/config.toml
sed -i -e "s/^seed_mode *=.*/seed_mode = \"$SEED_MODE\"/" ${HOME}/.sao/config/config.toml

### 为了降低磁盘空间使用率，可以使用以下配置设置修剪
export PRUNING="custom"
export PRUNING_KEEP_RECENT="10"
export PRUNING_INTERVAL="10"
sed -i -e "s/^pruning *=.*/pruning = \"$PRUNING\"/" ${HOME}/.sao/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$PRUNING_KEEP_RECENT\"/" ${HOME}/.sao/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$PRUNING_INTERVAL\"/" ${HOME}/.sao/config/app.toml

### 【可选】配置 systemd 运行

mkdir ~/.sao/logs
cat > ~/.sao/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

monikerName="\$(hostname)"
installPath="\${HOME}/.sao"
timestamp=\$(date +%Y%m%d-%H%M%S)
touch \$installPath/logs/\${timestamp}.log && ln -fs \$installPath/logs/\${timestamp}.log \$installPath/logs/latest.log
saod start --moniker \${monikerName} &> \${installPath}/logs/latest.log
EOF
chmod +x ~/.sao/start.sh
cat > /lib/systemd/system/saod.service << EOF
[Unit]
Description=SAO Consensus Node
Documentation=https://github.com/SaoNetwork/sao-consensus
After=network.target
[Service]
User=root
Group=root
ExecStart=bash \${HOME}/.sao/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=2
LimitNOFILE=4096
[Install]
WantedBy=multi-user.target
EOF

### 启动 service
systemctl daemon-reload
systemctl enable --now saod
systemctl status saod

### 查看同步状态
curl -s localhost:26657/status | jq .result.sync_info
