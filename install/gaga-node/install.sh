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

export TOKEN="qbwdyttsbmtkzhyg8e57b73fa38d9fa0"

# environment
serviceName="gaganode"
installPath="/data/${serviceName}"
downloadUrl="https://assets.coreservice.io/public/package/22/app/1.0.3/app-1_0_3.tar.gz"

# check node
ss -plunt | grep 29091 && INFO "gaga-node is running ..." && exit 0

# check install path
EXEC "rm -rf ${installPath} $(dirname ${installPath})/${serviceName}"
EXEC "mkdir -p ${installPath}/logs"

# install vnstat
EXEC "apt update && apt install -y vnstat"

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx --strip-components 1 -C ${installPath}"

# start
EXEC "cd ${installPath}"
EXEC "./app service install"
EXEC "./app service start"
EXEC "sleep 20"
INFO "ls -alht ./apps/gaganode/gaganode" && ls -alht ./apps/gaganode/gaganode || EXEC "sleep 20"
EXEC "./apps/gaganode/gaganode config set --token=${TOKEN}"
EXEC "./app restart"

# check
INFO "./app config show" && ./app config show
INFO "./app status" && ./app status

}

main $@
