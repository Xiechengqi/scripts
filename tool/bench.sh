#!/usr/bin/env bash

#
# 2022/09/06
# xiechengqi
# print system info
#

source /etc/profile
BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
timeout 2 curl -SsL $BASEURL/tool/common.sh &> /dev/null || BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

trap "_clean" EXIT

_clean() {

cd /tmp/ && rm -f $$_*

}

function check_cpu() {

# INFO "cat /proc/cpuinfo | grep 'model name' | uniq | awk -F ':' '{print $NF}' | sed 's/^[ ]*//'"
cpu_model_name=$(cat /proc/cpuinfo | grep 'model name' | uniq | awk -F ':' '{print $NF}' | sed 's/^[ ]*//')
# INFO "cat /proc/cpuinfo | grep 'physical id' | sort | uniq | wc -l"
cpu_physical_num=$(cat /proc/cpuinfo | grep 'physical id' | sort | uniq | wc -l)
YELLOW "cpu: ${cpu_model_name} * ${cpu_physical_num}"

}

function check_gpu() {

gpus=""
lspci | grep -i vga | grep -v 'ASPEED Graphics Family' | grep -v 'VMware SVGA II' | awk -F ': ' '{print $NF}' | awk -F '(' '{print $1}' | sort | uniq > /tmp/$$_gpus
while read gpu
do
gpu_id=$(echo ${gpu} | awk '{print $NF}')
gpu_name=$(curl -SsL http://pci-ids.ucw.cz/mods/PC/10de/${gpu_id} | grep ${gpu_id} | grep item | grep '\[GeForce' | head -1 | awk -F '[' '{print $NF}' | awk -F ']' '{print $1}')
gpu_num=$(lspci | grep -i vga | grep -v 'ASPEED Graphics Family' | grep -v 'VMware SVGA II' | awk -F ': ' '{print $NF}' | awk -F '(' '{print $1}' | grep "${gpu}" | wc -l)
gpus="${gpu_name} * ${gpu_num}; ${gpus}"
done < /tmp/$$_gpus

YELLOW "gpu: ${gpus}"

}

function check_men() {

mems=""
# INFO "sudo dmidecode --type memory | grep -E 'Size:.*GB$|Size:.*MB$' | grep -v ' Size' | awk -F ': ' '{print $NF}' | sed 's/ //g' | uniq -c | sed 's/^[ ]*//' | sed 's/[ ]/*/'"
sudo dmidecode --type memory | grep -E 'Size:.*GB$|Size:.*MB$' | grep -v ' Size' | awk -F ': ' '{print $NF}' | sed 's/ //g' | uniq -c > /tmp/$$_mem
while read mem
do
mem_num=$(echo $mem | awk '{print $1}')
mem_size=$(echo $mem | awk '{print $NF}')
mems="${mem_size} * ${mem_num}; ${mems}"
done < /tmp/$$_mem
YELLOW "memory: ${mems}"

}


function check_disk() {

disks=""
lsblk --nodeps | grep -E 'nvme|sd|hd|vd' | awk '{print $4}' | sort | uniq -c > /tmp/$$_disk
while read disk
do
disk_num=$(echo $disk | awk '{print $1}')
disk_size=$(echo $disk  | awk '{print $NF}')
disks="${disk_size} * ${disk_num}; ${disks}"
done < /tmp/$$_disk
YELLOW "disk: ${disks}"

}

function check_network_interface_card() {

nics=""
lspci | grep -i net | awk -F ': ' '{print $NF}' | awk -F '(' '{print $1}' | sort | uniq -c > /tmp/$$_nic
while read nic
do
nic_num=$(echo $nic | awk '{print $1}')
nic_size=$(echo $nic  | awk -F "${nic_num} " '{print $NF}')
nics="${nic_size} * ${nic_num}; ${nics}"
done < /tmp/$$_nic
YELLOW "nic: ${nics}"

}

function check_raid_hba() {

raid_hba=$(lspci -v | grep -i -E 'fibre|raid')
YELLOW "raid&hba: ${raid_hba}"

}

# 生产厂商和产品品牌
function check_manufacturer_product_name() {

manufacturer_product_nam="$(sudo dmidecode | grep -A4 'System Information' | grep -E 'Manufacturer|Product Name' | awk -F ':' '{print $NF}' | tr '\n' ' ' | sed 's/^[ ]*//' | sed 's/$/\n/')"
YELLOW "Product Name: ${manufacturer_product_nam}"

}

main() {

check_manufacturer_product_name
check_cpu
check_gpu
check_men
check_disk
check_network_interface_card
check_raid_hba

}

main $@
