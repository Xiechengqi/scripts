#!/usr/bin/env bash

#
# 2023/01/06
# xiechengqi
# https://mp.weixin.qq.com/s/Bc9OQmrQIpYK3U902UnLWA
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

function install() {

local aleo_address=$1
local 1to_proxy=$2
local gpu_num=$3
local cpu_list=$4

installPath="/scratch/aleo-gpu/${gpu_num}"
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,logs}"
EXEC "curl -SsL ${downloadUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"

INFO "create /etc/supervisor/conf.d/aleo-gpu-${gpu_num}.conf ..."
cat > /etc/supervisor/conf.d/aleo-gpu-${gpu_num}.conf << EOF
[program:aleo-gpu-${gpu_num}]
directory=/scratch/aleo-gpu/${gpu_num}
command=taskset -c ${cpu_list} /scratch/aleo-gpu/${gpu_num}/bin/${binaryName} --address ${aleo_address} --solo --ws ${1to_proxy}
stdout_logfile=/scratch/aleo-gpu/${gpu_num}/logs/latest.log
redirect_stderr=true
environment=CUDA_VISIBLE_DEVICES=${gpu_num}
EOF

}

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# aleo address
aleo_address=${1-"aleo1wfz88rr2wnuk65pxzgk8ewlzr2vhltzq2ggev3dq60nrd2e9lggqunt6cg"}
# 1to proxy
1to_proxy=${2-"wss://shadow.aleo1.to:32443"}
# BASEURL="http://cn.1to.sh/builds/aleo/partners/miner-9q57lnd4"
BASEURL="http://10.19.5.20:5000/aleo/bin"
# binary name
binaryName="1to-miner"
# download url
downloadUrl="${BASEURL}/${binaryName}"

# check service
cd /etc/supervisor &> /dev/null && supervisorctl status | grep aleo &> /dev/null && YELLOW "aleo is running ..." && return 0

# check nvidia gpu
! nvidia-smi -L &> /dev/null && ERROR "No Nvidia GPU ..."

# check cuda
! ls /usr/local | grep cuda &> /dev/null && ERROR "No Cuda ..."

# install opencl
EXEC "apt install -y ocl-icd-opencl-dev"

# install supervisor
systemctl is-active supervisor &> /dev/null
if [ "$?" != "0" ]
then
curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Supervisor/install.sh | sudo bash || exit 1
fi

# bind cpu
gpu_sum=$(nvidia-smi -L | grep -E '^GPU' | wc -l)
cpu_cores=$(lscpu | grep '^CPU(s):' | awk '{print $2}')
physical_cores=$(( cpu_cores / 2 ))
append=$(( physical_cores % gpu_sum ))
span=$(( physical_cores / gpu_sum ))

# install aleo-gpu
for num in $(seq 0 `expr ${gpu_sum} - 1`)
do

cpu_list="$((num * span))-$(((num+1) * span - 1)),$((num * span + physical_cores))-$(((num+1) * span + physical_cores - 1))"
if [[ $append -gt 0 ]]; then
cpu_list+=",$(( physical_cores - append )),$(( cpu_cores - append ))"
append=$(( append - 1 ))
fi

INFO "install ${aleo_address} ${1to_proxy} ${num} ${cpu_list}"
install ${aleo_address} ${1to_proxy} ${num} ${cpu_list}

done

# start
EXEC "cd /etc/supervisor"
EXEC "supervisorctl update"

# sleep
EXEC "sleep 5"

# status
INFO "supervisorctl status" && supervisorctl status

}

main $@
