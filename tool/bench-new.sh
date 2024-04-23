#!/usr/bin/env bash

#
# 2022/09/06
# xiechengqi
# print system info
#

# println information
INFO() {
printf -- "\033[44;37m%s\033[0m " "[$(TZ=UTC-8 date "+%Y-%m-%d %H:%M:%S")]"
printf -- "%s" "$1"
printf "\n"
}

# println yellow color information
YELLOW() {
printf -- "\033[44;37m%s\033[0m " "[$(TZ=UTC-8 date "+%Y-%m-%d %H:%M:%S")]"
printf -- "\033[33m%s\033[0m" "$1"
printf "\n"
}

# println error information
ERROR() {
printf -- "\033[41;37m%s\033[0m " "[$(TZ=UTC-8 date "+%Y-%m-%d %H:%M:%S")]"
printf -- "%s" "$1"
printf "\n"
exit 1
}

# exec cmd and print error information
EXEC() {
local cmd="$1"
INFO "${cmd}"
eval ${cmd} 1> /dev/null
if [ $? -ne 0 ]; then
ERROR "Execution command (${cmd}) failed, please check it and try again."
fi
}

get_os() {
if [ -f "/etc/debian_version" ]; then
source /etc/os-release && local os="${ID}"
elif [ -f "/etc/fedora-release" ]; then
local os="fedora"
elif [ -f "/etc/redhat-release" ]; then
local os="centos"
else
exit 1
fi

if [ -f /etc/redhat-release ]; then
local os_full=`awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release`
elif [ -f /etc/os-release ]; then
local os_full=`awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release`
elif [ -f /etc/lsb-release ]; then
local os_full=`awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release`
else
exit 1
fi

local main_ver="$( echo $os_full | grep -oE  "[0-9.]+")"
printf -- "%s" "${os}${main_ver%%.*}"
}

OS() {
osType=$1
osVersion=$2
curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/tool/os.sh | bash -s ${osType} ${osVersion} || exit 1
}

if_hyper_threading() {

physical_cpu_num=$(grep "physical id" /proc/cpuinfo | sort | uniq | wc -l)
single_logical_cpu_num=$(cat /proc/cpuinfo | grep "cpu cores" | uniq | wc -l)
logical_cpu_num=$(expr ${physical_cpu_num} \* ${single_logical_cpu_num})
real_logical_cpu_num=$(cat /proc/cpuinfo | grep "processor" | wc -l)
[ "${real_logical_cpu_num}" -gt "${logical_cpu_num}" ] && echo "true" || echo "false"

}

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

mem_manufacturer=$(dmidecode --type memory | grep 'Manufacturer' | grep -v 'NO DIMM' | sort | uniq | awk -F ': ' '{print $NF}' | tr '\n' ',' | sed 's/,$//')
mem_speed=$(dmidecode --type memory | grep 'Speed: ' | grep -v 'Configured Clock Speed' | grep -v Unknown | sort | uniq | awk -F ': ' '{print $NF}' | tr '\n' ',' | sed 's/,$//')

YELLOW "memory: ${mem_manufacturer} ${mem_speed} ${mems}"

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

disk_product=$(lshw -class disk | grep 'product' | sort | uniq -c | sed 's/        product://' | sed 's/^[ ]*//g' | sed 's/ /\*/g' | tr '\n' ',' | sed 's/,$//')
# lshw -class disk | grep 'product' | sort | uniq | awk -F ': ' '{print $NF}' | tr '\n' ',' | sed 's/,$//')

YELLOW "disk: ${disk_product} ${disks}"

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
