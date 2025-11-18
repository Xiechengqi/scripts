#!/usr/bin/env bash

main() {

export FILE=$(echo ${@} | sed 's/=/@@/' | awk -F '@@' '{print $NF}')
cat << EOF

==== 文件 ${FILE} 内容 ====
$(cat ${FILE})

EOF

}

main $@
