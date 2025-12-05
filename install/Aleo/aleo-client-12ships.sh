#!/usr/bin/env bash

#
# 2022/12/05
# xiechengqi
# install aleo client
#

source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# check
systemctl is-active aleo-client &> /dev/null && YELLOW "aleo-client and aleo-prover are running ..." && return 0

# env
serviceName="aleo-client"
installPath="/data/${serviceName}"
# 12ships
github_token="$1"
[ ".${github_token}" = "." ] && ERROR "Usage: curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Aleo/aleo-client-12ships.sh | sudo bash -s [github_ssh_token] [s-file.prd.com host] [PROVER_PRIVATE_KEY]"
githubRepoUrl="https://${github_token}@github.com/12shipsDevelopment/saurolophus.git"
# offical
# githubRepoUrl="https://github.com/AleoHQ/snarkOS.git"
srcPath="${installPath}/src"
# s-file.prd.com host ip
filePrdComHost="$2"
[ ".${filePrdComHost}" = "." ] && ERROR "curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Aleo/aleo-client-12ships.sh | sudo bash -s [github_ssh_token] [s-file.prd.com host] [PROVER_PRIVATE_KEY]"
# aleo address PROVER_PRIVATE_KEY
PROVER_PRIVATE_KEY="$3"

# download
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{src,logs,bin,conf}"
EXEC "git clone ${githubRepoUrl} --depth 1 ${installPath}/src"

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
echo "${filePrdComHost} s-file.prd.com" >> /etc/hosts
EXEC "curl -SsL http://s-file.prd.com/ssh/id_ed25519 -o /tmp/id_ed25519"
EXEC "chmod 600 /tmp/id_ed25519"
EXEC "ssh-add /tmp/id_ed25519"

# build snarkos
EXEC "cd ${installPath}/src"
EXEC "cp -f Cargo.toml_gpu Cargo.toml"
EXEC "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"
EXEC "export CUDA_HOME=/usr/local/cuda"
EXEC "export PATH=$PATH:/usr/local/cuda/bin"
INFO "cargo install --path ."
cargo install --path . || ERROR "Build snarkos error ..."

# bin
EXEC "mv target/release/snarkos ../bin"
EXEC "ln -fs ${installPath}/bin/snarkos /usr/local/bin/snarkos"
INFO "snarkos --help" && snarkos --help

# create account
if [ ".${PROVER_PRIVATE_KEY}" = "." ]
then
ls ${installPath}/conf/account &> /dev/null && mv ${installPath}/conf/account ${installPath}/conf/account.$(date +%s).bak
INFO "snarkos account new" && snarkos account new > ${installPath}/conf/account
INFO "cat ${installPath}/conf/account" && cat ${installPath}/conf/account
EXEC "export PROVER_PRIVATE_KEY=$(cat ${installPath}/conf/account | grep 'Private Key' | awk '{print $NF}')"
INFO "echo ${PROVER_PRIVATE_KEY}" && echo ${PROVER_PRIVATE_KEY}
fi

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

/usr/local/bin/snarkos start --nodisplay --client ${PROVER_PRIVATE_KEY} &> \${installPath}/logs/latest.log
EOF

# register service
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=Aleo Client Node
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
