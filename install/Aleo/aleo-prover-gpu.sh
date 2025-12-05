#!/usr/bin/env bash

#
# 2021/12/05
# xiechengqi
# install offical gpu aleo prover
#

source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

function install() {

local key=$1
local gpu_num=$2
local client=$3
local port=$4

installPath="/scratch/aleo-gpu/${gpu_num}"
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,logs}"
EXEC "curl -SsL ${downloadUrl} -o ${installPath}/bin/snarkos"
EXEC "chmod +x ${installPath}/bin/snarkos"

INFO "create /etc/supervisor/conf.d/aleo-gpu-${gpu_num}.conf ..."
cat > /etc/supervisor/conf.d/aleo-gpu-${gpu_num}.conf << EOF
[program:aleo-gpu-${gpu_num}]
environment=CUDA_VISIBLE_DEVICES="${gpu_num}"
directory=/scratch/aleo-gpu/${gpu_num}
command=/scratch/aleo-gpu/${gpu_num}/bin/snarkos start --nodisplay true --prover ${key} --connect ${client} --verbosity 1 --node 0.0.0.0:${port}
stdout_logfile=/scratch/aleo-gpu/${gpu_num}/logs/latest.log
redirect_stderr=true
EOF

}

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# aleo prover private key
PROVER_PRIVATE_KEY=${1-"APrivateKey1zkp8R76H3DGcrPGe4k76HGgLFpmPRHV7xStZmLi5sry2eTo"}
# aleo client url
aleo_client=${2-"10.19.10.244:4133"}
# download url
downloadUrl=${3-"http://10.19.5.20:5000/aleo/bin/snarkos"}
# aleo node port
node_port="4100"

# check service
supervisorctl status | grep aleo &> /dev/null && YELLOW "aleo is running ..." && return 0

# check nvidia gpu
! nvidia-smi -L &> /dev/null && ERROR "No Nvidia GPU ..."
gpu_sum=$(nvidia-smi -L | wc -l)

# check cuda
! ls /usr/local | grep cuda &> /dev/null && ERROR "No Cuda ..."

# install supervisor
! systemctl is-active supervisor &> /dev/null && EXEC "apt install -y supervisor"

# install aleo-gpu
for num in $(seq 0 `expr ${gpu_sum} - 1`)
do

INFO "install ${PROVER_PRIVATE_KEY} ${num} ${aleo_client} ${node_port}"
install ${PROVER_PRIVATE_KEY} ${num} ${aleo_client} ${node_port}
((node_port++))

done

# start
EXEC "supervisorctl update"

# sleep
EXEC "sleep 5"

# status
INFO "supervisorctl status" && supervisorctl status

}

main $@
