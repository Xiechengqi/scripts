#!/usr/bin/env bash

#
# 2026/11/23
# xiechengqi
# Install Antigravity Cli
#

source /etc/profile
BASEURL="https://install.xiecq.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

# environment
serviceName="antigravity"
binary="agy"

versionUrl="https://api.github.com/repos/google-antigravity/antigravity-cli/releases/latest"
[ "${countryCode}" = "China" ] && versionUrl="${GITHUB_PROXY}/${versionUrl}"
version=$(curl -SsL ${versionUrl} | jq -r .tag_name)
[ ".${version}" != "." ] && version="1.5.14"
INFO "version: ${version}"

installPath="/data/${serviceName}"
downloadUrl="https://github.com/google-antigravity/antigravity-cli/releases/download/${version}/agy_cli_linux_x64.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"

# check
which ${binary} &> /dev/null && YELLOW "${binary} has been installed, please remove $(which ${binary}) first ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/bin"

# link data dir
export AGY_HOME="$HOME/.gemini/antigravity-cli"
EXEC "mkdir -p ${AGY_HOME}"
EXEC "ln -fs ${AGY_HOME} ${installPath}/data"

# env
cat >> ${installPath}/env << EOF
### Add To \$HOME/.bashrc
## Antigravity
alias agy="agy --dangerously-skip-permissions"
EOF

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}/bin/ && mv -v ${installPath}/bin/antigravity ${installPath}/bin/${binary} && chmod +x ${installPath}/bin/${binary}"

# register bin
EXEC "rm -f -v /usr/local/bin/${binary} && ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
EXEC "${binary} --version" && ${binary} --version

# upgrade script
EXEC "curl -SsL ${BASEURL}/install/Antigravity/upgrade.sh -o ${installPath}/upgrade.sh && chmod +x ${installPath}/upgrade.sh"

# info
YELLOW "${serviceName} version: ${version}"
YELLOW "install: ${installPath}"
YELLOW "Add To $HOME/.bashrc"
cat ${installPath}/env

}

main $@
