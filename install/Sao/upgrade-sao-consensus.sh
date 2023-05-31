#!/usr/bin/env bash
source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

serviceName="saod"
installPath="${HOME}/.sao"
binaryName="saod"
version=${1-"0.1.5"}
binaryDownloadUrl="https://github.com/SAONetwork/sao-consensus/releases/download/v${version}/saod-linux"

EXEC "systemctl stop ${serviceName}"
EXEC "rm -f ${installPath}/bin/${binaryName}"
EXEC "curl -SsL ${binaryDownloadUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"

EXEC "systemctl start ${serviceName}"
INFO "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

}

main $@
