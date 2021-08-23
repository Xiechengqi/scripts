#!/usr/bin/env bash

#
# xiechengqi
# 2021/07/23
# install node
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# environment
serviceName="node"
version=${1-"12.16.0"}
installPath="/data/${serviceName}-${version}"
downloadUrl="https://nodejs.org/download/release/v${version}/node-v${version}-linux-x64.tar.gz"

# check node
[[ "$(node -v)" =~ "${version}" ]] && YELLOW "node has been installed ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath"

# register path
EXEC "sed -i '/node\/bin/d' /etc/profile"
EXEC "echo 'export PATH=\$PATH:$installPath/bin' >> /etc/profile"
EXEC "ln -fs $installPath/bin/* /usr/bin/"
EXEC "source /etc/profile"
EXEC "node -v" && node -v
EXEC "npm -v" && npm -v

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/${serviceName}"

# info
YELLOW "version: $version"
}

main $@
