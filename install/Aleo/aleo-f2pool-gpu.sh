#!/usr/bin/env bash

#
# 2021/12/08
# xiechengqi
# https://blog.f2pool.com/zh/mining-tutorial/how-to-mine-aleo-guide-mine-aleo
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

function install() {

local userName=$1
local gpu_num=$2
local cpu_list=$3

installPath="/scratch/aleo-gpu/${gpu_num}"
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,logs}"
EXEC "curl -SsL ${downloadUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"

INFO "create /etc/supervisor/conf.d/aleo-gpu-${gpu_num}.conf ..."
cat > /etc/supervisor/conf.d/aleo-gpu-${gpu_num}.conf << EOF
[program:aleo-gpu-${gpu_num}]
directory=/scratch/aleo-gpu/${gpu_num}
command=taskset -c ${cpu_list} /scratch/aleo-gpu/${gpu_num}/bin/${binaryName} -a ${userName} -g ${gpu_num} -p ${f2pool_proxy}
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
# BASEURL="https://aleo-resource.oss-cn-shenzhen.aliyuncs.com/aleo-prover-cuda"
BASEURL="http://10.19.5.20:5000/aleo/bin"
# binary name
binaryName="aleo-prover-cuda"
# download url
downloadUrl="${BASEURL}/${binaryName}"

# check service
cd /etc/supervisor &> /dev/null && supervisorctl status | grep aleo &> /dev/null && YELLOW "aleo is running ..." && return 0

# check nvidia gpu
! nvidia-smi -L &> /dev/null && ERROR "No Nvidia GPU ..."

# check cuda
! ls /usr/local | grep cuda &> /dev/null && ERROR "No Cuda ..."

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

INFO "install ${f2pool_username} ${num} ${cpu_list}"
install ${f2pool_username} ${num} ${cpu_list}

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
