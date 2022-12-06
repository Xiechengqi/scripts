#!/usr/bin/env bash

#
# 2021/12/06
# xiechengqi
# https://blog.f2pool.com/zh/mining-tutorial/how-to-mine-aleo-guide-mine-aleo
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

function install() {

local userName=$1
local gpu_num=$2

installPath="/scratch/aleo-gpu/${gpu_num}"
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,logs}"
EXEC "curl -SsL ${downloadUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"

INFO "create /etc/supervisor/conf.d/aleo-gpu-${gpu_num}.conf ..."
cat > /etc/supervisor/conf.d/aleo-gpu-${gpu_num}.conf << EOF
[program:aleo-gpu-${gpu_num}]
directory=/scratch/aleo-gpu/${gpu_num}
command=/scratch/aleo-gpu/${gpu_num}/bin/${binaryName} -a ${userName} -g ${gpu_num} -p ${f2pool_proxy}
stdout_logfile=/scratch/aleo-gpu/${gpu_num}/logs/latest.log
redirect_stderr=true
EOF

}

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# f2pool username
f2pool_username=${1-"xiechengqi"}
# f2pool proxy
f2pool_proxy=${2-"aleo-asia.f2pool.com:4400"}
# BASEURL="https://aleo-resource.oss-cn-shenzhen.aliyuncs.com/aleo-prover-cuda-133"
BASEURL="http://10.19.5.20:5000/aleo/bin"
# binary name
binaryName="aleo-prover-cuda-133"
# download url
downloadUrl="${BASEURL}/${binaryName}"

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

INFO "install ${f2pool_username} ${num}"
install ${f2pool_username} ${num}

done

# start
EXEC "supervisorctl update"

# sleep
EXEC "sleep 5"

# status
INFO "supervisorctl status" && supervisorctl status

}

main $@
