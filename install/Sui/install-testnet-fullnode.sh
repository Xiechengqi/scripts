#!/usr/bin/env bash

#
# 2023/01/30
# xiechengqi
# install sui testnet wave2 fullnode
# https://docs.sui.io/devnet/build/fullnode
# https://api.nodes.guru/sui_testnet.sh
#

source /etc/profile
BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
source <(curl -SsL $BASEURL/tool/common.sh)


main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# environment
serviceName="suid"
installPath="/data/${serviceName}"
downloadUrl="https://github.com/MystenLabs/sui.git"

# check node
systemctl is-active ${serviceName} &> /dev/null && INFO "${serviceName} is running ..." && exit 0

# pre env
EXEC "apt update"
EXEC "DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC"
EXEC "apt install -y --no-install-recommends tzdata ca-certificates build-essential pkg-config cmake"

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{src,conf,bin,data,logs}"

# download source
EXEC "git clone -b testnet ${downloadUrl} ${installPath}/src"

# config
EXEC "cp -f ${installPath}/src/crates/sui-config/data/fullnode-template.yaml ${installPath}/conf/fullnode.yaml"
sed -i "s#db-path:.*#db-path: \"${installPath}/data\"#" ${installPath}/conf/fullnode.yaml
sed -i "s#genesis-file-location:.*#genesis-file-location: \"${installPath}/genesis.blob\"#" ${installPath}/conf/fullnode.yaml
INFO "cat ${installPath}/conf/fullnode.yaml" && cat ${installPath}/conf/fullnode.yaml && echo
EXEC "curl -SsL https://github.com/MystenLabs/sui-genesis/raw/main/testnet/genesis.blob -o ${installPath}/genesis.blob"

# install Rust
EXEC "curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Rust/install.sh | sudo bash"
EXEC "source $HOME/.cargo/env"

# build binary
EXEC "cd ${installPath}/src"
INFO "cargo build --release -p sui-node" && cargo build --release -p sui-node
EXEC "cd ${installPath}"
EXEC "cp -f ${installPath}/src/target/release/sui-node ${installPath}/bin/"
EXEC "chmod +x ${installPath}/bin/sui-node"
EXEC "ln -fs ${installPath}/bin/sui-node /usr/local/bin/sui-node"

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

installPath=${installPath}
timestamp=\$(date +%Y%m%d-%H%M%S)
touch \$installPath/logs/\${timestamp}.log && ln -fs \$installPath/logs/\${timestamp}.log \$installPath/logs/latest.log
sui-node --config-path \$installPath/conf/fullnode.yaml &> \$installPath/logs/latest.log
EOF

# register serivce
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=Sui Node
Documentation=https://github.com/MystenLabs/sui.git
After=network.target

[Service]
User=root
Group=root
ExecStart=/bin/bash ${installPath}/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=2
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
EXEC "ln -fs ${installPath}/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# INFO
YELLOW "${serviceName} version: testnet"
YELLOW "install path: $installPath"
YELLOW "config path: $installPath/conf"
YELLOW "data path: $installPath/data"
YELLOW "tail log cmd: tail -f $installPath/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"

}

main $@
