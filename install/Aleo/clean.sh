#!/usr/bin/env bash

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# clean service
cd /etc/supervisor/conf.d && EXEC "pwd" && EXEC "rm -f ./*" && EXEC "supervisorctl update" && EXEC "cd -"

}

main $@
