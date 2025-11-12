#!/usr/bin/env bash

main() {

export COMMAND=$(echo ${@} | sed 's/=/@@/' | awk -F '@@' '{print $NF}')
cat << EOF

你是一个 Linux 系统管理员，执行命令 `${COMMAND}` 时遇到了问题，请根据下面信息排查（使用命令行显示友好的格式输出）:

==== 当前操作系统信息 ====
$(cat /etc/os-release)

==== 执行命令: ${COMMAND} 输出 ====
$(${COMMAND} 2>&1)

EOF

}

main $@
