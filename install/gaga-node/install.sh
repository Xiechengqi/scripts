#!/usr/bin/env bash

#
# 2023/01/28
# xiechengqi
# install gaganode
# https://dashboard.gaganode.com/install_run
#

source /etc/profile
BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

export TOKEN="bzqgszdbcwnmunydbfc932e297ccd27f"

# environment
serviceName="gaganode"
installPath="/data/${serviceName}"
downloadUrl="https://assets.coreservice.io/public/package/60/app-market-gaga-pro/1.0.4/app-market-gaga-pro-1_0_4.tar.gz"

# check node
ss -plunt | grep 29091 && INFO "gaga-node is running ..." && exit 0

# check install path
EXEC "rm -rf ${installPath} $(dirname ${installPath})/${serviceName}"
EXEC "mkdir -p ${installPath}/logs"

# install vnstat
! which vnstat &> /dev/null && EXEC "apt update && apt install -y vnstat"

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx --strip-components 1 -C ${installPath}"

# start
EXEC "cd ${installPath}"
INFO "./apphub service remove" && ./apphub service remove
EXEC "./apphub service install"
EXEC "./apphub service start"
EXEC "sleep 20"
INFO "ls -alht ./apps/gaganode/gaganode" && ls -alht ./apps/gaganode/gaganode || EXEC "sleep 20"
EXEC "./apps/gaganode/gaganode config set --token=${TOKEN}"
EXEC "./apphub restart"

# check
INFO "./apphub config show" && ./apphub config show
INFO "./apphub status" && ./apphub status

}

main $@
