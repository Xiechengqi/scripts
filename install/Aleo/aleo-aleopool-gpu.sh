#!/usr/bin/env bash

#
# 2021/12/06
# xiechengqi
# https://docs.aleopool.xyz/tutorial/alpha/pool-mode
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

function install() {

local account=$1
local gpu_num=$2
local miner_name="$(hostname -I | awk '{print $1}')-${gpu_num}"

installPath="/scratch/aleo-gpu/${gpu_num}"
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,logs}"
EXEC "curl -SsL ${downloadUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"

INFO "create /etc/supervisor/conf.d/aleo-gpu-${gpu_num}.conf ..."
cat > /etc/supervisor/conf.d/aleo-gpu-${gpu_num}.conf << EOF
[program:aleo-gpu-${gpu_num}]
environment=CUDA_VISIBLE_DEVICES=${gpu_num}
directory=/scratch/aleo-gpu/${gpu_num}
command=/scratch/aleo-gpu/${gpu_num}/bin/${binaryName} --account_name ${account} --miner_name ${miner_name}
stdout_logfile=/scratch/aleo-gpu/${gpu_num}/logs/latest.log
redirect_stderr=true
EOF

}

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# aleo address
account_name=${1-"ca_aleopool"}
# BASEURL="https://nd-valid-data-bintest1.oss-cn-hangzhou.aliyuncs.com/aleo"
BASEURL="http://10.19.5.20:5000/aleo/bin"
# download url
echo "$osInfo" | grep -E 'ubuntu18' &> /dev/null && downloadUrl="${BASEURL}/aleo-pool-prover_ubuntu_1804_gpu" || downloadUrl="${BASEURL}/aleo-pool-prover_ubuntu_2004_gpu"
# binary name
echo "$osInfo" | grep -E 'ubuntu18' &> /dev/null && binaryName="aleo-pool-prover_ubuntu_1804_gpu" || binaryName="aleo-pool-prover_ubuntu_2004_gpu"

# check service
supervisorctl status | grep aleo &> /dev/null && YELLOW "aleo is running ..." && return 0

# check nvidia gpu
! nvidia-smi -L &> /dev/null && ERROR "No Nvidia GPU ..."
gpu_sum=$(nvidia-smi -L | wc -l)

# check cuda
! ls /usr/local | grep cuda &> /dev/null && ERROR "No Cuda ..."

# install supervisor
! systemctl is-active supervisor &> /dev/null && curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Supervisor/install.sh | sudo bash

# install aleo-gpu
for num in $(seq 0 `expr ${gpu_sum} - 1`)
do

INFO "install ${account_name} ${num}"
install ${account_name} ${num}

done

# start
EXEC "supervisorctl update"

# sleep
EXEC "sleep 5"

# status
INFO "supervisorctl status" && supervisorctl status

}

main $@
