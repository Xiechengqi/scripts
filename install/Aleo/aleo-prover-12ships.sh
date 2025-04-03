#!/usr/bin/env bash

#
# 2022/12/02
# xiechengqi
# install aleo client and prover
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# check
[[ ! "$@" =~ "force" ]] && systemctl is-active aleo-prover &> /dev/null && YELLOW "aleo-prover is running ..." && return 0

# service name
serviceName="aleo-prover"
# Prover key
PROVER_PRIVATE_KEY="$1"
[ ".${PROVER_PRIVATE_KEY}" = "." ] && ERROR "Miss PROVER_PRIVATE_KEY"
installPath="/data/aleo"
# download url
binaryDownloadUrl="http://10.19.5.20:5000/aleo/bin/snarkos"

# download
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{logs,bin,conf}"
EXEC "curl -SsL ${binaryDownloadUrl} -o ${installPath}/bin/snarkos"
EXEC "chmod +x ${installPath}/bin/snarkos"
EXEC "ln -fs ${installPath}/bin/snarkos /usr/local/bin/snarkos"
INFO "snarkos --help" && snarkos --help

# install deps
EXEC "apt update"
EXEC "apt install -y make clang pkg-config libssl-dev build-essential gcc xz-utils git curl vim tmux ntp jq llvm ufw"

# open ports
EXEC "ufw allow 4133/tcp"
EXEC "ufw allow 3033/tcp"

# creat start.sh
cat > ${installPath}/bin/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

installPath="${installPath}"
timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

/usr/local/bin/snarkos start --nodisplay --prover ${PROVER_PRIVATE_KEY} &> \${installPath}/logs/latest.log
EOF

# register aleo-prover.service
cat > /lib/systemd/system/aleo-prover.service << EOF
[Unit]
Description=Aleo Prover Node
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

# start aleo-prover
EXEC "systemctl daemon-reload && systemctl enable --now aleo-prover"
EXEC "systemctl status aleo-prover --no-pager" && systemctl status aleo-prover --no-pager

}

main $@
