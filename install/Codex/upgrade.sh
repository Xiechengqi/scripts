#!/usr/bin/env bash

#
# 2026/11/17
# xiechengqi
# Update Codex Cli
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
serviceName="codex"
binary="codex"

versionUrl="https://api.github.com/repos/openai/codex/releases/latest"
[ "${countryCode}" = "China" ] && versionUrl="${GITHUB_PROXY}/${versionUrl}"
version=$(curl -SsL ${versionUrl} | jq -r .tag_name)
[ ".${version}" = "." ] && ERROR "Could Not Get Latest Version ..."
INFO "Latest Version: ${version}"
INFO "Current Version: $(${binary} --version)"
EXEC "sleep 5"

installPath="/data/${serviceName}"
downloadUrl="https://github.com/openai/codex/releases/download/${version}/codex-x86_64-unknown-linux-musl.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
downloadModeUrl="https://github.com/openai/codex/releases/download/${version}/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz"
[ "${countryCode}" = "China" ] && downloadModeUrl="${GITHUB_PROXY}/${downloadModeUrl}"

# check
ps -ef | grep -v grep | grep -v upgrade.sh | grep ${binary} && ERROR "${serviceName} Is Running, Can Not Upgrade ..."

# backup
INFO "mv -v ${installPath}/bin/${binary} ${installPath}/bin/${binary}.bak" && mv -v ${installPath}/bin/${binary} ${installPath}/bin/${binary}.bak
INFO "mv -v ${installPath}/bin/codex-code-mode-host ${installPath}/bin/codex-code-mode-host.bak" && mv -v ${installPath}/bin/codex-code-mode-host ${installPath}/bin/codex-code-mode-host.bak

# download
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}/bin/ && mv -v ${installPath}/bin/codex-x86_64-unknown-linux-musl ${installPath}/bin/${binary} && chmod +x ${installPath}/bin/${binary}"
EXEC "curl -SsL ${downloadModeUrl} | tar zx -C ${installPath}/bin/ && mv -v ${installPath}/bin/codex-code-mode-host-x86_64-unknown-linux-musl ${installPath}/bin/codex-code-mode-host && chmod +x ${installPath}/bin/codex-code-mode-host"

# register
EXEC "rm -f -v /usr/local/bin/${binary} && ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
EXEC "rm -f -v /usr/local/bin/codex-code-mode-host && ln -fs ${installPath}/bin/codex-code-mode-host /usr/local/bin/codex-code-mode-host"

# info
YELLOW "${serviceName} version: ${version}"
YELLOW "install: ${installPath}"

}

main $@
