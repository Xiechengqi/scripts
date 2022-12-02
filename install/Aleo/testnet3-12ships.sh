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
systemctl is-active aleo-prover &> /dev/null && systemctl is-active aleo-client &> /dev/null && YELLOW "aleo-client and aleo-prover are running ..." && return 0

# env
installPath="/data/aleo"
# 12ships
github_token="$1"
[ ".${github_token}" = "." ] && ERROR "Usage: curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Aleo/testnet3.sh | sudo bash -s [github_ssh_token]"
githubRepoUrl="https://${github_token}@github.com/12shipsDevelopment/saurolophus.git"
# offical
# githubRepoUrl="https://github.com/AleoHQ/snarkOS.git"
srcPath="${installPath}/src"

# download
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{src,logs,bin,conf}"
EXEC "git clone ${githubRepoUrl} --depth 1 ${installPath}/src"

# # swap
# INFO 'Setting up swapfile ...'
# INFO "curl -s https://api.nodes.guru/swap4.sh | bash"
# curl -s https://api.nodes.guru/swap4.sh | bash

# install deps
EXEC "apt update"
EXEC "apt install -y make clang pkg-config libssl-dev build-essential gcc xz-utils git curl vim tmux ntp jq llvm ufw"

# install rust
INFO "curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Rust/install.sh | sudo bash"
curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Rust/install.sh | sudo bash
EXEC "source $HOME/.cargo/env"

# ssh-agent
pkill ssh-agent || true
eval `ssh-agent -s`
ssh-add /root/.ssh/id_ed25519

# build snarkos
EXEC "cd ${installPath}/src"
INFO "cargo install --path ."
cargo install --path . || ERROR "Build snarkos error ..."

# bin
EXEC "mv target/release/snarkos ../bin"
EXEC "ln -fs ${installPath}/bin/snarkos /usr/local/bin/snarkos"
INFO "snarkos --help" && snarkos --help

# create account
ls ${installPath}/conf/account &> /dev/null && mv ${installPath}/conf/account ${installPath}/conf/account.$(date +%s).bak
INFO "snarkos account new" && snarkos account new > ${installPath}/conf/account
INFO "cat ${installPath}/conf/account" && cat ${installPath}/conf/account
EXEC "export PROVER_PRIVATE_KEY=$(cat ${installPath}/conf/account | grep 'Private Key' | awk '{print $NF}')"
INFO "echo ${PROVER_PRIVATE_KEY}" && echo ${PROVER_PRIVATE_KEY}

# open ports
EXEC "ufw allow 4133/tcp"
EXEC "ufw allow 3033/tcp"

# creat start-aleo-client.sh
cat > ${installPath}/bin/start-aleo-client.sh << EOF
#!/usr/bin/env bash
source /etc/profile

installPath="${installPath}"
timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}-aleo-client.log && ln -fs \${installPath}/logs/\${timestamp}-aleo-client.log \${installPath}/logs/latest-aleo-client.log

/usr/local/bin/snarkos start --nodisplay --client ${PROVER_PRIVATE_KEY} &> \${installPath}/logs/latest-aleo-client.log
EOF

# register aleo-client.service
cat > /lib/systemd/system/aleo-client.service << EOF
[Unit]
Description=Aleo Client Node
After=network-online.target
[Service]
User=root
Group=root
ExecStart=/bin/bash ${installPath}/bin/start-aleo-client.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

# start aleo-client
EXEC "systemctl daemon-reload && systemctl enable --now aleo-client"
EXEC "systemctl status aleo-client --no-pager" && systemctl status aleo-client --no-pager

# creat start-aleo-prover.sh
cat > ${installPath}/bin/start-aleo-prover.sh << EOF
#!/usr/bin/env bash
source /etc/profile

installPath="${installPath}"
timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}-aleo-prover.log && ln -fs \${installPath}/logs/\${timestamp}-aleo-prover.log \${installPath}/logs/latest-aleo-prover.log

/usr/local/bin/snarkos start --nodisplay --client ${PROVER_PRIVATE_KEY} &> \${installPath}/logs/latest-aleo-prover.log
EOF

# register aleo-prover.service
cat > /lib/systemd/system/aleo-prover.service << EOF
[Unit]
Description=Aleo Prover Node
After=network-online.target
[Service]
User=root
Group=root
ExecStart=/bin/bash ${installPath}/bin/start-aleo-prover.sh
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
