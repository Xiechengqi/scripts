#!/usr/bin/env bash

#
# 2022/12/05
# xiechengqi
# install aleo client
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20|centos' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20、centos"

# service name
serviceName="aleo-client"
installPath="/data/${serviceName}"
# aleo address PROVER_PRIVATE_KEY
PROVER_PRIVATE_KEY="$1"
[ ".${PROVER_PRIVATE_KEY}" = "." ] && ERROR "curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Aleo/aleo-client.sh | sudo bash -s [PROVER_PRIVATE_KEY]"
# download url
binaryDownloadUrl="https://install.xiechengqi.top/aleo/bin/snarkos"

# check
[[ ! "$@" =~ "force" ]] && systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# download
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{logs,bin,conf}"
EXEC "curl -SsL ${binaryDownloadUrl} -o ${installPath}/bin/snarkos"
EXEC "chmod +x ${installPath}/bin/snarkos"
EXEC "ln -fs ${installPath}/bin/snarkos /usr/local/bin/snarkos"
INFO "snarkos --help" && snarkos --help

# creat start.sh
cat > ${installPath}/bin/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

installPath="${installPath}"
timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

/usr/local/bin/snarkos start --nodisplay true --client ${PROVER_PRIVATE_KEY} &> \${installPath}/logs/latest.log
EOF

# register service
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=Aleo Client
After=network-online.target
[Service]
User=root
Group=root
ExecStart=/bin/bash ${installPath}/bin/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

# start service
EXEC "systemctl daemon-reload && systemctl enable --now ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

}

main $@
