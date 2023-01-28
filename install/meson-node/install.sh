#!/usr/bin/env bash

#
# 2023/01/28
# xiechengqi
# install meson node
# https://dashboard.meson.network/user_node
#

source /etc/profile
BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

export MESON_TOKEN="ndofiwxlyoaqyiaicyydvtqh"
export HTTPS_PORT="29092"
export CACHE_SIZE="30"

# environment
serviceName="meson_cdn"
version=${1-"3.1.19"}
installPath="/data/${serviceName}"
downloadUrl="https://staticassets.meson.network/public/meson_cdn/v${version}/meson_cdn-linux-amd64.tar.gz"
binaryName="meson_cdn"

# install vnstat
EXEC "apt update && apt install -y vnstat"

# check install path
EXEC "rm -rf ${installPath} $(dirname ${installPath})/${serviceName}"
EXEC "mkdir -p ${installPath}/logs"

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx --strip-components 1 -C ${installPath}"

# start
EXEC "cd ${installPath}"
EXEC "./service install ${serviceName}"
EXEC "./${binaryName} config set --token=${MESON_TOKEN} --https_port=${HTTPS_PORT} --cache.size=${CACHE_SIZE}"
EXEC "./service start ${serviceName}"
INFO "./service status ${serviceName}" && ./service status ${serviceName}
INFO "./${binaryName} config show" && ./${binaryName} config show

}

main $@
