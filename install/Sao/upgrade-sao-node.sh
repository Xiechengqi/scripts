#!/usr/bin/env bash
source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

serviceName="sao-node"
binaryName="saonode"
binaryDownloadUrl=${1}
[ ".${binaryDownloadUrl}" = "." ] && echo "Less Params binaryDownloadUrl" && exit 1
installPath=${2-"/data/sao-node"}

EXEC "systemctl stop ${serviceName}"
EXEC "rm -f ${installPath}/bin/${binaryName}"
EXEC "curl -SsL ${binaryDownloadUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"

EXEC "systemctl start ${serviceName}"
INFO "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

}

main $@
