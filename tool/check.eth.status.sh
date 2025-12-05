#!/bin/bash
# author: wangyubao
# date: 2018-09-13
# usage: 检查各网卡是否down

eth_list=$(ls -lL /sys/class/net | grep ^d | awk '{print $NF}' | xargs)

if [[ -n "$eth_list" ]]; then
    for i in $eth_list; do
        ip=$(ip a| grep -w inet| grep -w $i| awk '{print $2}'| awk -F/ '{print $1}'| sort -n| xargs| tr ' ' ',')
        mac=$(cat /sys/class/net/$i/address 2>/dev/null)
        speed=$(cat /sys/class/net/$i/speed 2>/dev/null)
        status=$(ip a | grep $i":" | awk -F' state ' '{print $2}' | awk '{print $1}')
        data=-1
        case $status in
        "UP")
            data=1
            ;;
        "DOWN")
            data=0
            ;;
        "UNKNOWN")
            data=2
            ;;
        esac
        echo "check_eth_status{device=\"$i\",mac=\"$mac\",speed=\"$speed\",ip=\"$ip\"}  $data"
    done
fi
