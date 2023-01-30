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

# environment
serviceName="suid"
installPath="/scratch/${serviceName}"
downloadUrl="https://install.xiechengqi.top/sui-node"
githubUrl="https://github.com/MystenLabs/sui.git"
binaryName="sui-node"

# check node
systemctl is-active ${serviceName} &> /dev/null && INFO "${serviceName} is running ..." && exit 0

# check install path
EXEC "cd /scratch"
EXEC "rm -rf ${serviceName}"
EXEC "mkdir -p ${installPath}/{src,conf,bin,data,logs}"

# download binary
EXEC "curl -k -SsL ${downloadUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"
EXEC "ln -fs ${installPath}/bin/${binaryName} /usr/local/bin/${binaryName}"

# download github repo
EXEC "git clone -b testnet ${downloadUrl} ${installPath}/src"

# config
EXEC "cp -f ${installPath}/src/crates/sui-config/data/fullnode-template.yaml ${installPath}/conf/fullnode.yaml"
sed -i "s#db-path:.*#db-path: \"${installPath}/data\"#" ${installPath}/conf/fullnode.yaml
sed -i "s#genesis-file-location:.*#genesis-file-location: \"${installPath}/genesis.blob\"#" ${installPath}/conf/fullnode.yaml
INFO "cat ${installPath}/conf/fullnode.yaml" && cat ${installPath}/conf/fullnode.yaml && echo
EXEC "curl -SsL https://github.com/MystenLabs/sui-genesis/raw/main/testnet/genesis.blob -o ${installPath}/genesis.blob"


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
