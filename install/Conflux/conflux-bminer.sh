#!/usr/bin/env bash

#
# 2023/02/24
# xiechengqi
# https://blog.f2pool.com/zh/mining-tutorial/how-to-mine-cfx-guide-mine-conflux
#

source /etc/profile
BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
source <(curl -SsL $BASEURL/tool/common.sh)

function install() {

installPath="/scratch/conflux-bminer"

EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,logs}"
EXEC "curl -SsL ${downloadUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"

INFO "create /etc/supervisor/conf.d/conflux-bminer.conf ..."
cat > /etc/supervisor/conf.d/conflux-bminer.conf << EOF
[program:conflux-bminer]
directory=${installPath}
command=${installPath}/bin/${binaryName} -uri ${uri}
stdout_logfile=${installPath}/logs/latest.log
redirect_stderr=true
EOF

}

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

BASEURL="http://10.19.5.20:5000/bminer/bin"
# binary name
binaryName="bminer"
# download url
downloadUrl="${BASEURL}/${binaryName}"
# uri
uri="conflux://aleomining.$(hostname)@cfx.f2pool.com:6800"

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

# install
INFO "install"
install

# start
EXEC "cd /etc/supervisor"
EXEC "supervisorctl update"

# sleep
EXEC "sleep 5"

# status
INFO "supervisorctl status" && supervisorctl status

}

main $@
