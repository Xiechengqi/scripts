#!/usr/bin/env bash
# by centos and ubuntu

export LANG="en_US.UTF-8"
host_cpus=20
host_memory=60
host_sys_disk=400
host_disk_num=36

check_network(){
    net_dev=$(ip addr|grep ine|grep "inet 10.19.30.80"|awk '{print $NF}')
    net_speed=$(ethtool $net_dev|grep "Speed:"|awk '{print $2}'|cut -d"M" -f1)
    if [ $net_speed -ge 20000 ];then
        echo "10.19.30.80: Network rate [$net_speed]Mb normal [YES]"
    else
        echo "10.19.30.80: Network rate [$net_speed]Mb abnormal [NO]"
    fi
    bond_mode=$(grep 'Bonding Mode' /proc/net/bonding/$net_dev|awk '{print $4}')
    bond_thp=$(grep 'Transmit Hash' /proc/net/bonding/$net_dev|awk '{print $4}')
    if [ $bond_mode == "802.3ad" ];then
        echo "10.19.30.80: Bonding Mode [$bond_mode] normal [YES]"
    else
        echo "10.19.30.80: Bonding Mode [$bond_mode] abnormal [NO]"
    fi
    if [ "$bond_thp"x == "layer3+4"x ];then
        echo "10.19.30.80: Bonding Transmit Hash [$bond_thp] normal [YES]"
    else
        echo "10.19.30.80: Bonding Transmit Hash [$bond_thp] abnormal [NO]"
    fi
}

check_disk(){
    sys_disk=()
    for i in $(df --block-size=G |egrep '/boot$|/boot/efi$|/$'|awk '{print $1}');do
      sys_disk+=(${i})
    done
    # sys_disk=$(df --block-size=G |egrep '/boot$|/boot/efi$'|awk '{print $1}')
	fdisk=$(fdisk -l|grep "sectors$"|grep -v "mapper"|awk '{print $2}'|cut -d":" -f1)
    rm -f /tmp/disks
    for disk in $fdisk;do
        echo ${sys_disk[@]}|grep $disk > /dev/null
        if [ $? != 0 ];then
            fdisk -l $disk|grep "sectors$"|awk -F"," '{print $1}'|awk '{print $2,$3,$4}' >> /tmp/disks
            lsblk $disk|grep "T  0 disk"
           # if [ $? == 0 ];then
           #     wipefs -a $disk
           # fi

        fi
    done
    disk_num=$(grep -v nvme /tmp/disks|wc -l)
    if [ $host_disk_num == $disk_num ];then
        echo "10.19.30.80: DISK: Number of disks "$disk_num" normal[YES]"
    else
        echo "10.19.30.80: DISK: Number of disks "$disk_num" abnormal[NO]"
    fi
    disk_capacity=$(awk '{print $2}' /tmp/disks |sort |uniq)
    for capacity in $disk_capacity;do
        capacity_num=$(grep "$capacity" /tmp/disks|wc -l)
        capacity_name=$(grep "$capacity" /tmp/disks|awk -F":" '{print $1}'|cut -d"/" -f3|xargs)
        capacity_unit=$(grep "$capacity" /tmp/disks|awk '{print $NF}'|uniq)
        echo "10.19.30.80: DISK: $capacity_num,$capacity$capacity_unit,[$capacity_name]"
    done
}

check_material(){
    cpus=$(lscpu |grep ^"CPU(s):"|awk '{print $NF}')
    if [ $cpus -ge $host_cpus ];then
        echo "10.19.30.80: CPU normal [YES]"
    else
        echo "10.19.30.80: CPU abnormal [NO]"
    fi

    memory=$(lsmem |grep "Total online memory:"|awk '{print $NF}'|cut -d"G" -f1)
	if [ `echo "$memory > $host_memory"|bc` -eq 1 ];then
        echo "10.19.30.80: memory normal [YES]"
    else
        echo "10.19.30.80: memory abnormal [NO]"
    fi
    # sys_disk=$(df --block-size=G |grep '/$'|awk '{print $2}'|cut -d"G" -f1)
    sys_disk=$(mount -l|awk '{if($3=="/"){print $1}}')
    if [[ ${sys_disk} =~ /mapper/ ]];then
        sys_size=$(lvdisplay --units G ${sys_disk}|sed -nr '/LV Size/s/[^0-9\.]+([0-9]+).*\s.*/\1/p')
    else
        sys_size=$(df --block-size=G |grep "${sys_disk}"|awk '{print $2}'|cut -d"G" -f1)
    fi
    if [ $sys_size -ge $host_sys_disk ];then
        echo "10.19.30.80: / Partition normal [YES]"
    else
        echo "10.19.30.80: / Partition abnormal [NO]"
    fi
    mount_home=$(df --block-size=G | grep "/home\$" | awk '{print $NF}')
    if [ "$mount_home"x != "/home"x ];then
        echo "10.19.30.80: /home directory normal [YES]"
    else
        echo "10.19.30.80: /home directory abnormal [NO]"
    fi
    swap_status=$(free -g |grep Swap | awk '{print $2}')
    if [ $swap_status -eq 0 ];then
        echo "10.19.30.80: Swap Partition normal [YES]"
    else
        echo "10.19.30.80: Swap Partition abnormal [NO]"
    fi
    dmesg_net=$(dmesg |grep "dmesg -T | grep 'NIC Link is Down")
    if [ $? == 0 ];then
        echo "10.19.30.80: dmesg network abnormal [NO]"
    fi
    dmesg_disk=$(dmesg -T | grep ' I/O error')
    if [ $? == 0 ];then
        echo "10.19.30.80: dmesg disk abnormal [NO]"
    fi
}
main(){
    check_material
    check_network
    check_disk
}

main
