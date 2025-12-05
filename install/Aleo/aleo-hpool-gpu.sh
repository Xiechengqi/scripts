#!/usr/bin/env bash

#
# 2021/12/07
# xiechengqi
# install https://www.hpool.in/help/tutorial/48
#

source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# hpool api key
apiKey=${1}
[ ".${apiKey}" = "." ] && ERROR "Hpool Api Key can not be empty!"
# hpool xproxy url
xproxy=${2-"10.19.6.15:9190"}
# download url
echo "$osInfo" | grep -E 'ubuntu18' &> /dev/null && binaryName="hpool-miner-aleo-cuda-ubuntu18"
echo "$osInfo" | grep -E 'ubuntu20' &> /dev/null && binaryName="hpool-miner-aleo-cuda-ubuntu20"
BASEURL="https://install.xiechengqi.top"
downloadUrl="${BASEURL}/${binaryName}"
# install path
installPath="/scratch/aleo-gpu"

# check service
cd /etc/supervisor &> /dev/null && supervisorctl status | grep aleo &> /dev/null && YELLOW "aleo is running ..." && return 0

# check nvidia gpu
! nvidia-smi -L &> /dev/null && ERROR "No Nvidia GPU ..."
gpu_sum=$(nvidia-smi -L | grep -E '^GPU' | wc -l)

# check cuda
! ls /usr/local | grep cuda &> /dev/null && ERROR "No Cuda ..."

# install supervisor
! systemctl is-active supervisor &> /dev/null && curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Supervisor/install.sh | sudo bash

# install aleo-gpu
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,conf,logs}"
EXEC "curl -SsL ${downloadUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"

# conf
minerName=$(hostname -I | awk '{print $1}')
devices="0"
for num in $(seq 1 `expr ${gpu_sum} - 1`)
do
devices="${devices},${num}"
done
taskThreads=$(expr $(cat /proc/cpuinfo | grep "processor" | wc -l) / ${gpu_sum})
if_hyper_threading | grep "true" &> /dev/null && cpuAffinityStep="2" || cpuAffinityStep="1"

cat > ${installPath}/conf/config.yaml << EOF
minerName: ${minerName}
apiKey: "${apiKey}"
log:
  level: info
server:
  xproxy: "http://${xproxy}"
extraParams:
    # 设备编号，多设备0,1,2,3
    devices: ${devices}
    # 任务线程数，4卡32核设置为 8
    taskThreads: ${taskThreads}
    # CPU绑定间隔，
    cpuAffinityStep: ${cpuAffinityStep}
    # cpu开始绑定编号
    cpuAffinityStart: 0
EOF

INFO "create /etc/supervisor/conf.d/aleo-hpool-gpu.conf ..."
cat > /etc/supervisor/conf.d/aleo-hpool-gpu.conf << EOF
[program:aleo-hpool-gpu]
directory=${installPath}
command=${installPath}/bin/${binaryName} -config ${installPath}/conf/config.yaml
stdout_logfile=${installPath}/logs/latest.log
redirect_stderr=true
EOF

# start
EXEC "cd /etc/supervisor"
EXEC "supervisorctl update"

# sleep
EXEC "sleep 5"

# status
INFO "supervisorctl status" && supervisorctl status

}

main $@
