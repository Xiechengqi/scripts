#!/usr/bin/env bash

#
# 2026/11/20
# xiechengqi
# Install Claude Cli
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
serviceName="claude"
binary="claude"

# https://downloads.claude.ai/claude-code-releases/latest"
versionUrl="https://api.github.com/repos/anthropics/claude-code/releases/latest"
[ "${countryCode}" = "China" ] && versionUrl="${GITHUB_PROXY}/${versionUrl}"
version=$(curl -SsL ${versionUrl} | jq -r .tag_name)
[ ".${version}" != "." ] && version="v2.1.329"
INFO "version: ${version}"

installPath="/data/${serviceName}"
# https://downloads.claude.ai/claude-code-releases/2.1.329/linux-x64/claude
downloadUrl="https://github.com/anthropics/claude-code/releases/download/${version}/claude-linux-x64.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"

# check
which ${binary} &> /dev/null && YELLOW "${binary} has been installed, please remove $(which ${binary}) first ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/bin"

# link data dir
export CODEX_HOME="$HOME/.claude"
EXEC "mkdir -p ${CODEX_HOME}"
EXEC "ln -fs ${CODEX_HOME} ${installPath}/data"

# env
cat >> ${installPath}/env << EOF
### Add To \$HOME/.bashrc
## Claude
ANTHROPIC_BASE_URL=xxx
ANTHROPIC_AUTH_TOKEN=xxx
ANTHROPIC_MODEL=
CLAUDE_CODE_SUBAGENT_MODEL=
alias claude="ANTHROPIC_BASE_URL=\${ANTHROPIC_BASE_URL} ANTHROPIC_AUTH_TOKEN=\${ANTHROPIC_AUTH_TOKEN} ANTHROPIC_MODEL=\${ANTHROPIC_MODEL} CLAUDE_CODE_SUBAGENT_MODEL=\${CLAUDE_CODE_SUBAGENT_MODEL} IS_SANDBOX=1 claude --dangerously-skip-permissions"
EOF

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}/bin/ && chmod +x ${installPath}/bin/${binary}"

# register bin
EXEC "rm -f -v /usr/local/bin/${binary} && ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
EXEC "${binary} --version" && ${binary} --version

# upgrade script
EXEC "curl -SsL ${BASEURL}/install/Claude/upgrade.sh -o ${installPath}/upgrade.sh && chmod +x ${installPath}/upgrade.sh"

# info
YELLOW "${serviceName} version: ${version}"
YELLOW "install: ${installPath}"
YELLOW "Add To $HOME/.bashrc"
cat ${installPath}/env

}

main $@
