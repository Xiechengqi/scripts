#!/bin/bash

for DEV in /sys/class/net/*; do
	if [ "$DEV" = "/sys/class/net/bonding_masters" ]; then
		continue
	fi
	devtype="unknow"
	for ipaddr in $(ip addr show ${DEV##*/} | sed -rne '/inet/s:\s+inet\s+([0-9.]+).*:\1:gp'); do
		[ "wan" == "$devtype" ] && break
		[ "127.0.0.1" == "$ipaddr" ] && devtype=lo && break
		echo $ipaddr | grep -P '^192\.|^172\.|^10\.' >/dev/null && devtype=lan && break
		echo $ipaddr | grep -P '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' >/dev/null && devtype=wan && break
	done
	# echo qiniu_node_network_transmit_bytes_total{device=${DEV##*/} $devtype
	printf "qiniu_node_network_transmit_bytes_total{device=\"%s\",type=\"%s\"} %d\n" ${DEV##*/} $devtype $(cat /sys/class/net/${DEV##*/}/statistics/tx_bytes)
	printf "qiniu_node_network_receive_bytes_total{device=\"%s\",type=\"%s\"} %d\n" ${DEV##*/} $devtype $(cat /sys/class/net/${DEV##*/}/statistics/rx_bytes)
done
