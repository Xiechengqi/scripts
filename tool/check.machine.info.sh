#!/bin/bash

# prometheus metric 中尽量不要出现空格，这里用 '_' 代替
board_vendor=$(cat /sys/class/dmi/id/board_vendor 2>/dev/null | tr ' ' '_')
board_name=$(cat /sys/class/dmi/id/board_name 2>/dev/null | tr ' ' '_')
board_serial=$(cat /sys/class/dmi/id/board_serial 2>/dev/null | tr ' ' '_')
board_version=$(cat /sys/class/dmi/id/board_version 2>/dev/null | tr ' ' '_')
production_name=$(cat /sys/class/dmi/id/product_name 2>/dev/null | tr ' ' '_')
production_version=$(cat /sys/class/dmi/id/product_version 2>/dev/null | tr ' ' '_')
production_serial=$(cat /sys/class/dmi/id/product_serial 2>/dev/null | tr ' ' '_')
production_uuid=$(cat /sys/class/dmi/id/product_uuid 2>/dev/null | tr ' ' '_')

# 只打印七牛自己写入的 tag，其他的忽略
avail_tags=("qiniu")
chassis_asset_tag=$(cat /sys/class/dmi/id/chassis_asset_tag 2>/dev/null | tr ' ' '_')
if [[ ! " ${avail_tags[@]} " =~ " ${chassis_asset_tag} " ]]; then
    chassis_asset_tag=""
fi

os=$(grep ^ID= /etc/os-release | awk -F'=' '{print $2}' | tr -d '"')$(grep ^VERSION_ID= /etc/os-release | awk -F'"' '{print $2}' 2>/dev/null)
kernel=$(uname -r)
arch=$(uname -m)

echo "machine_info{board_vendor=\"$board_vendor\",board_name=\"$board_name\",board_serial=\"$board_serial\",board_version=\"$board_version\",production_name=\"$production_name\",production_version=\"$production_version\",production_serial=\"$production_serial\",production_uuid=\"$production_uuid\",chassis_asset_tag=\"$chassis_asset_tag\"} 0"

# for OS
echo "system_info{os=\"$os\",kernel=\"$kernel\",arch=\"$arch\"} 0"
