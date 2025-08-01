#!/usr/bin/env bash
#
# xiechengqi
# 2025/08/01
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/ubuntu/ufw/delete-port.sh | sudo bash -s [port]
#

main() {

local port=${1}
[ ".${port}" = "." ] && echo "Less Port, exit ..." && exit 1
echo "=> grep ufw ${port}"
ufw status numbered | grep -E "^\[[0-9]+\] ${port} " || exit 0
echo "=> delete ufw ${port}"
for number in $(ufw status numbered | grep -oP "^\[[0-9]+\] ${port} " | grep -oP "^\[[0-9]+\]" |  grep -oP "[0-9]+" | sort -rn)
do
echo "=> ufw delete ${number}"
echo 'y' | ufw delete ${number}
done

}

main $@
