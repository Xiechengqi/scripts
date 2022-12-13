#!/usr/bin/env bash

#
# 2021/12/04
# xiechengqi
# install https://github.com/damomine/aleominer
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

function install() {

local address=$1
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
directory=${installPath}
command=taskset -c ${cpu_list} ${installPath}/bin/${binaryName} --address ${address} --proxy ${aleo_proxy} --gpu ${gpu_num}
stdout_logfile=${installPath}/logs/latest.log
redirect_stderr=true
EOF

}

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# aleo address
aleo_address=${1-"aleo1wfz88rr2wnuk65pxzgk8ewlzr2vhltzq2ggev3dq60nrd2e9lggqunt6cg"}
# aleo proxy url
aleo_proxy="aleo3.damominer.hk:9090"
aleo_proxy_url=$(echo ${aleo_proxy} | awk -F ':' '{print $1}')
aleo_proxy_hosts="47.57.238.173"
sed -i "/${aleo_proxy_url}/d" /etc/hosts
echo "${aleo_proxy_hosts} ${aleo_proxy_url}" >> /etc/hosts

# binary name
binaryName="damominer"
# download url
downloadUrl="http://10.19.5.20:5000/aleo/bin/${binaryName}"

# check service
cd /etc/supervisor &> /dev/null && supervisorctl status | grep aleo &> /dev/null && YELLOW "aleo is running ..." && return 0

# check nvidia gpu
! nvidia-smi -L &> /dev/null && ERROR "No Nvidia GPU ..."
gpu_sum=$(nvidia-smi -L | grep -E '^GPU' | wc -l)

# check cuda
! ls /usr/local | grep cuda &> /dev/null && ERROR "No Cuda ..."

# install supervisor
! systemctl is-active supervisor &> /dev/null && curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Supervisor/install.sh | sudo bash

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

INFO "install ${aleo_address} ${num} ${cpu_list}"
install ${aleo_address} ${num} ${cpu_list}

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
