#!/usr/bin/env bash

#
# 2026/11/23
# xiechengqi
# Upgrade Grok Cli
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
serviceName="grok"
binary="grok"

versionUrl="https://storage.googleapis.com/grok-build-public-artifacts/cli/stable"
version=$(curl -SsL ${versionUrl} 2> /dev/null)
[ ".${version}" = "." ] && ERROR "Could Not Get Latest Version ..."
INFO "Latest Version: ${version}"
INFO "Current Version: $(${binary} --version)"
EXEC "sleep 5"

installPath="/data/${serviceName}"
downloadUrl="https://storage.googleapis.com/grok-build-public-artifacts/cli/grok-${version}-linux-x86_64"

# check
ps -ef | grep -v grep | grep -v upgrade.sh | grep ${binary} && ERROR "${serviceName} Is Running, Can Not Upgrade ..."

# backup
INFO "mv -v ${installPath}/bin/${binary} ${installPath}/bin/${binary}.bak" && mv -v ${installPath}/bin/${binary} ${installPath}/bin/${binary}.bak

# download
EXEC "curl -SsL ${downloadUrl} -o ${installPath}/bin/${binary} && chmod +x ${installPath}/bin/${binary}"

# register bin
EXEC "rm -f -v /usr/local/bin/${binary} && ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
EXEC "${binary} --version" && ${binary} --version

# info
YELLOW "${serviceName} version: ${version}"
YELLOW "install: ${installPath}"
}

main $@
