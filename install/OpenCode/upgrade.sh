#!/usr/bin/env bash

#
# 2026/11/17
# xiechengqi
# Upgrade OpenCode Cli And Web Service
#

source /etc/profile
BASEURL="https://install.xiecq.top"
source <(curl -SsL $BASEURL/tool/common.sh)

BASEPATH=`dirname $(readlink -f ${BASH_SOURCE[0]})` && cd $BASEPATH

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

# environment
serviceName="opencode"
binary="opencode"
versionUrl="https://api.github.com/repos/anomalyco/opencode/releases/latest"
[ "${countryCode}" = "China" ] && versionUrl="${GITHUB_PROXY}/${versionUrl}"
version=$(curl -SsL ${versionUrl} | jq -r .tag_name)
[ ".${version}" = "." ] && ERROR "Could Not Get Latest Version ..."
INFO "Latest Version: ${version}"
INFO "Current Version: $(${binary} --version)"
EXEC "sleep 5"

installPath="/data/${serviceName}"
downloadUrl="https://github.com/anomalyco/opencode/releases/download/${version}/opencode-linux-x64.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"

# stop service
systemctl is-active ${serviceName} &> /dev/null && EXEC "systemctl stop ${serviceName}"

# check
ps -ef | grep -v grep | grep -v upgrade.sh | grep ${binary} && ERROR "${serviceName} Is Running, Can Not Upgrade ..."

# backup
INFO "mv -v ${installPath}/bin/${binary} ${installPath}/bin/${binary}.bak" && mv -v ${installPath}/bin/${binary} ${installPath}/bin/${binary}.bak

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}/bin/ && chmod +x ${installPath}/bin/${binary}"

# register bin
EXEC "rm -f -v /usr/local/bin/${binary} && ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
EXEC "${binary} --version" && ${binary} --version

# start
EXEC "systemctl start ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# info
YELLOW "${serviceName} version: ${version}"
YELLOW "install: ${installPath}"
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
