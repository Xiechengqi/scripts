#!/bin/bash
# author: wangyubao
# date: 2018-09-13
# usage: 检查各网卡是否down

#检查bond下网卡down
for i in  `ls /proc/net/bonding/* 2>/dev/null`; do
    down_eth=`cat $i|grep -A1 'Slave Interface' |grep -B1 down |grep 'Slave Interface'|awk '{print $NF}'`

    if  [[ -n  "$down_eth" ]] ; then
        for i in $down_eth; do
            status=1
            echo "check_eth_updown{device=\"$i\"}  $status"
        done
    fi
done

#检查非bond下网卡down
down_eth=`ip a|grep -v 127.0.0.1 |grep -w inet -B2 |grep 'state DOWN'|awk '{print $2}'|tr -d ':'`

if  [[ -n  "$down_eth" ]] ; then
    for i in $down_eth; do
        status=1
        echo "check_eth_updown{device=\"$i\"}  $status"
    done
fi
