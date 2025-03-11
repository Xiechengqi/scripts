#!/usr/bin/env bash
#
# xiechengqi
# 2025/03/11
# make install cri-dockerd
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

export serviceName="cri-dockerd"

# check servcie
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# download deb package
EXEC "curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Docker/cri-dockerd/cri-dockerd_0.3.15.3-0.ubuntu-focal_amd64.deb -o /tmp/cri-dockerd_0.3.15.3-0.ubuntu-focal_amd64.deb"

# install
INFO "dpkg -i /tmp/cri-dockerd_0.3.15.3-0.ubuntu-focal_amd64.deb" && dpkg -i /tmp/cri-dockerd_0.3.15.3-0.ubuntu-focal_amd64.deb || exit 1

# check
EXEC "systemctl daemon-reload && systemctl enable --now ${serviceName}.socket ${serviceName}"
INFO "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager
INFO "cri-dockerd --version" && cri-dockerd --version
INFO "ls -al /var/run/cri-dockerd.sock" && ls -al /var/run/cri-dockerd.sock

}

main $@
