#!/usr/bin/env bash
#
# xiechengqi
# 2025/08/01
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/ubuntu/ufw/delete-ip.sh | sudo bash -s [ip]
#

main() {

local ip=${1}
[ ".${ip}" = "." ] && echo "Less IP, exit ..." && exit 1
echo "=> grep ufw ${ip}"
ufw status numbered | grep -E " ${ip}" || exit 0
echo "=> delete ufw ${ip}"
for number in $(ufw status numbered | grep -E " ${ip}" | grep -oP "^\[[ ]*[0-9]+\]" |  grep -oP "[0-9]+" | sort -rn)
do
echo "=> ufw delete ${number}"
echo 'y' | ufw delete ${number}
done

}

main $@
