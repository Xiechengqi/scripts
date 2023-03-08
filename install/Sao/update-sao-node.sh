#!/usr/bin/env bash
source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

serviceName="sao-node"
installPath="/data/sao-node"
binaryName="saonode"
binaryDownloadUrl="http://203.23.128.181:5000/sao/${binaryName}"

EXEC "systemctl stop ${serviceName}"
EXEC "rm -f ${installPath}/bin/${binaryName}"
EXEC "curl -SsL ${binaryDownloadUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"

EXEC "systemctl start ${serviceName}"
INFO "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

}

main $@
