#!/usr/bin/env bash

#
# 2026/11/23
# xiechengqi
# Install Grok Cli
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
serviceName="grok"
binary="grok"

# https://x.ai/cli/stable
versionUrl="https://storage.googleapis.com/grok-build-public-artifacts/cli/stable"
version=$(curl -SsL ${versionUrl} 2> /dev/null)
[ ".${version}" != "." ] && version="1.0.92"
INFO "version: ${version}"

installPath="/data/${serviceName}"
# https://x.ai/cli/grok-${version}-linux-x86_64
downloadUrl="https://storage.googleapis.com/grok-build-public-artifacts/cli/grok-${version}-linux-x86_64"

# check
which ${binary} &> /dev/null && YELLOW "${binary} has been installed, please remove $(which ${binary}) first ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/bin"

# link data dir
export GROK_HOME="$HOME/.grok"
EXEC "mkdir -p ${GROK_HOME}"
EXEC "ln -fs ${GROK_HOME} ${installPath}/data"

# env
cat >> ${installPath}/env << EOF
### Add To \$HOME/.bashrc
## Grok
export GROK_MODELS_BASE_URL=https://xxx/v1
export XAI_API_KEY=xxx
export GROK_DEFAULT_MODEL=
alias grok="GROK_MODELS_BASE_URL=\${GROK_MODELS_BASE_URL} XAI_API_KEY=\${XAI_API_KEY} GROK_DEFAULT_MODEL=\${GROK_DEFAULT_MODEL} grok"
EOF

# download
EXEC "curl -SsL ${downloadUrl} -o ${installPath}/bin/${binary} && chmod +x ${installPath}/bin/${binary}"

# register bin
EXEC "rm -f -v /usr/local/bin/${binary} && ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
EXEC "${binary} --version" && ${binary} --version

# upgrade script
EXEC "curl -SsL ${BASEURL}/install/Grok/upgrade.sh -o ${installPath}/upgrade.sh && chmod +x ${installPath}/upgrade.sh"

# info
YELLOW "${serviceName} version: ${version}"
YELLOW "install: ${installPath}"
YELLOW "Add To $HOME/.bashrc"
cat ${installPath}/env

}

main $@
