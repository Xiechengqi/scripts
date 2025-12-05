#! /bin/bash
# author: lijinglin
# date: 2018-08-15
# description: get error disk from dmesg

function check_error() {
	dev=$(echo $1 | cut -d '/' -f 3 | sed 's/[[:digit:]]*//g')
	mountpoint=$(df -hl | grep $1 | awk '{print $NF}')
	attach_num=$(dmesg -T | grep -P -w ${dev}[1]? | awk '$9=/Attached/{print  NR}' | tail -1)

	if [[ ! -z $attach_num ]]; then
		error_num=$(dmesg -T | grep -P -w ${dev}[1]? | awk -v a=$attach_num 'NR>=a' | grep error | grep -e sector -e EXT4-fs | grep -v 'errors=remount-ro' | wc -l)
	else
		error_num=$(dmesg -T | grep -P -w ${dev}[1]? | grep error | grep -e sector -e EXT4-fs | grep -v 'errors=remount-ro' | wc -l)
	fi

	if [[ $error_num -ne 0 ]]; then
		tag=""
		for item in pfd ptfd ebd dc mongo; do
			num=$(supervisorctl status | grep ^$item | wc -l)
			if [[ $num -ne 0 ]]; then
				if [[ "$tag" == "" ]]; then
					tag=$item
				else
					tag=$tag","$item
				fi
			fi
		done

		size=$(df -h | grep $1 | awk '{print $2}')
		echo "check_disk_error{mountpoint=\"${mountpoint}\",device=\"$i\",tag=\"$tag\",size=\"$size\"} $error_num"
	fi
}

dev_list=$(df -h | grep ^/dev/sd | awk '{print $1}')

for i in $(echo $dev_list); do
	check_error $i &
done
wait
