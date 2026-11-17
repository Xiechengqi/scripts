#!/usr/bin/env bash

#
# 2026/11/17
# xiechengqi
# Install Codex Cli
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
serviceName="codex"
binary="codex"

versionUrl="https://api.github.com/repos/openai/codex/releases/latest"
[ "${countryCode}" = "China" ] && versionUrl="${GITHUB_PROXY}/${versionUrl}"
version=$(curl -SsL ${versionUrl} | jq -r .tag_name)
[ ".${version}" != "." ] && version="rust-v0.169.0"
INFO "version: ${version}"

installPath="/data/${serviceName}"
downloadUrl="https://github.com/openai/codex/releases/download/${version}/codex-x86_64-unknown-linux-musl.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"

# check
which ${binary} &> /dev/null && YELLOW "${binary} has been installed, please remove $(which ${binary}) first ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/bin"

# link data dir
export CODEX_HOME="$HOME/.codex"
EXEC "mkdir -p ${CODEX_HOME}"
EXEC "ln -fs ${CODEX_HOME} ${installPath}/data"

# env
cat >> ${installPath}/env << EOF
### Add To \$HOME/.bashrc
## Codex
export CODEX_BASE_URL=https://xxx/v1
export CODEX_API_KEY=
export CODEX_HOME=\$HOME/.codex
mkdir -p \${CODEX_HOME} && echo -e "model_provider = 'custom-api'\n[model_providers.custom-api]\nname = 'Custom API'\nbase_url = '\${CODEX_BASE_URL}'\nenv_key = 'CODEX_API_KEY'" > \${CODEX_HOME}/config.toml
alias codex="CODEX_HOME=\${{CODEX_HOME} CODEX_API_KEY=\${{CODEX_API_KEY} codex --search --sandbox=danger-full-access --ask-for-approval=never -c sandbox_workspace_write.network_access=true"
EOF

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}/bin/ && mv -v ${installPath}/bin/codex-x86_64-unknown-linux-musl ${installPath}/bin/${binary} && chmod +x ${installPath}/bin/${binary}"

# register bin
EXEC "ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
EXEC "${binary} --version" && ${binary} --version

# upgrade script
EXEC "curl -SsL ${BASEURL}/install/Codex/upgrade.sh -o ${installPath}/upgrade.sh && chmod +x ${installPath}/upgrade.sh"

# info
YELLOW "${serviceName} version: ${version}"
YELLOW "install: ${installPath}"
YELLOW "Add To $HOME/.bashrc"
cat ${installPath}/env

}

main $@
