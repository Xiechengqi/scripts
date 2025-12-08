#!/usr/bin/env bash
#
# xiechengqi
# 2025/12/18
# make install cri-dockerd
#

source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu22' &> /dev/null && ERROR "You could only install on os: ubuntu22"
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."

# https://github.com/Mirantis/cri-dockerd/releases/
version="0.3.21"
serviceName="cri-docker"
# https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.21/cri-dockerd_0.3.21.3-0.ubuntu-focal_amd64.deb
downloadUrl="https://github.com/Mirantis/cri-dockerd/releases/download/v${version}/cri-dockerd_${version}.3-0.ubuntu-focal_amd64.deb"
[ "$countryCode" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"

# check servcie
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# download deb package
EXEC "curl -SsL ${downloadUrl} -o /tmp/cri-dockerd.deb"

# install
INFO "dpkg -i /tmp/cri-dockerd.deb" || exit 1

# check
EXEC "systemctl daemon-reload && systemctl enable --now ${serviceName}.socket ${serviceName}"
INFO "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager
INFO "cri-dockerd --version" && cri-dockerd --version
INFO "ls -al /var/run/cri-dockerd.sock" && ls -al /var/run/cri-dockerd.sock

}

main $@
