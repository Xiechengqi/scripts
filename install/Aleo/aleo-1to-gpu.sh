#!/usr/bin/env bash

#
# 2023/01/09
# xiechengqi
# https://mp.weixin.qq.com/s/Bc9OQmrQIpYK3U902UnLWA
#

source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

function install() {

local aleo_address=$1
local proxy=$2

installPath="/scratch/aleo-gpu"
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,logs}"
EXEC "curl -SsL ${downloadUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"

INFO "create /etc/supervisor/conf.d/aleo-gpu.conf ..."
cat > /etc/supervisor/conf.d/aleo-gpu.conf << EOF
[program:aleo-gpu]
directory=${installPath}
command=${installPath}/bin/${binaryName} --address ${aleo_address} --solo --ws ${proxy}
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
# 1to proxy
proxy=${2-"ws://pool.aleo1.to:32000"}
BASEURL="https://install.xiechengqi.top"
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

# install aleo-gpu
INFO "install ${aleo_address} ${proxy}"
install ${aleo_address} ${proxy}

# start
EXEC "cd /etc/supervisor"
EXEC "supervisorctl update"

# sleep
EXEC "sleep 5"

# status
INFO "supervisorctl status" && supervisorctl status

}

main $@
