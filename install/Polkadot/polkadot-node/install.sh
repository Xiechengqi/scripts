#!/usr/bin/env bash

# 
# xiechengqi
# OS: Ubuntu 18.04
# 2021/08/04
# install Polkadot Node
# 

source /etc/profile
source <(curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/tool/common.sh)

main() {
# check os
OS "ubuntu" "18"

# get net option
if [ "$1" = "polkadot" ]; then
net="polkadot"
elif [ "$1" = "kusama" ]; then
net="kusama"
elif [ "$1" = "westend" ]; then
net="westend"
else
ERROR "You can only choose network: polkadot、kusama or westend"
fi

# environments
serviceName="polkadot-node"
version="0.9.8"
downloadUrl="https://github.com/paritytech/polkadot/releases/download/v${version}/polkadot"
installPath="/data/Polkadot/${serviceName}-${version}"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName has been installed ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{bin,conf,data,logs}"

# download
EXEC "curl -SsL $downloadUrl -o $installPath/bin/polkadot"
EXEC "chmod +x $installPath/bin/polkadot"

# register bin
EXEC "ln -fs $installPath/bin/* /usr/local/bin"
EXEC "polkadot --version" && polkadot --version

# create start.sh
# --pruning archive: 运行归档节点，同步所有的区块
# --name: 指定节点名
# -d,--base-path: 指定运行目录
# --rpc-external: 监听所有 rpc 接口
# --rpc-external: 监听所有 websocket 接口
# --rpc-cors all: 允许远程访问节点需要开启
# --rpc-port: 指定 http rpc 端口，默认 9933
# --ws-port: 指定 websocket rpc 端口，默认 9944
# --chain 指定要使用的网络，默认为 Polkadot CC1 网络, kusama 是准生产网
# --wasm-execution Compiled: 使此节点使用更多的 CPU 和 RAM，同步速度能达到 4 倍。建议在同步结束后关闭这个参数
# --help: 参数说明查看
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

polkadot --pruning archive --name "$serviceName-$net" --chain $net -d $installPath/data --rpc-external --ws-external --rpc-cors all &> $installPath/logs/$(date +%Y%m%d%H%M%S).log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=Polkadot Node Implementation
Documentation=https://github.com/paritytech/polkadot
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

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/${serviceName}"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# INFO
YELLOW "version: ${version}"
YELLOW "install path: $installPath"
YELLOW "log path: $installPath/logs"
YELLOW "db path: $installPath/data"
YELLOW "view block height: curl -SsL -H \"Content-Type: application/json\" -d '{\"id\":1, \"jsonrpc\":\"2.0\", \"method\": \"chain_getBlock\"}' http://localhost:9933/ | jq .result.block.header.number"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
