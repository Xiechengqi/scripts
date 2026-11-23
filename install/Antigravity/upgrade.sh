#!/usr/bin/env bash

#
# 2026/11/23
# xiechengqi
# Upgrade Antigravity Cli
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
serviceName="Antigravity"
binary="agy"
versionUrl="https://api.github.com/repos/google-antigravity/antigravity-cli/releases/latest"
[ "${countryCode}" = "China" ] && versionUrl="${GITHUB_PROXY}/${versionUrl}"
version=$(curl -SsL ${versionUrl} | jq -r .tag_name)
[ ".${version}" = "." ] && ERROR "Could Not Get Latest Version ..."
INFO "Latest Version: ${version}"
INFO "Current Version: $(${binary} --version)"
EXEC "sleep 5"

installPath="/data/${serviceName}"
downloadUrl="https://github.com/google-antigravity/antigravity-cli/releases/download/${version}/agy_cli_linux_x64.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"

# check
ps -ef | grep -v grep | grep -v upgrade.sh | grep ${binary} && ERROR "${serviceName} Is Running, Can Not Upgrade ..."

# backup
INFO "mv -v ${installPath}/bin/${binary} ${installPath}/bin/${binary}.bak" && mv -v ${installPath}/bin/${binary} ${installPath}/bin/${binary}.bak

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}/bin/ && mv -v ${installPath}/bin/antigravity ${installPath}/bin/${binary} && chmod +x ${installPath}/bin/${binary}"

# register bin
EXEC "rm -f -v /usr/local/bin/${binary} && ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
EXEC "${binary} --version" && ${binary} --version

# info
YELLOW "${serviceName} version: ${version}"
YELLOW "install: ${installPath}"
}

main $@
