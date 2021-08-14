``` shell
# 获取当前主机的 ipv4
curl ip.sb -4

# 获取当前主机所在国家缩写
curl -SsL https://api.ip.sb/geoip | sed 's/,/\n/g' | grep country_code | awk -F '"' '{print $(NF-1)}'

# 判断用户是否为 root
[ $(id -u) = "0" ] && echo "yes" || echo "no"

# 获取 github 仓库 release 列表
curl -SsL https://api.github.com/repos/alibaba/nacos/releases | grep tag_name |  awk -F '"' '{print $(NF-1)}'

# 获取 github 仓库最新 release
curl -SsL https://api.github.com/repos/alibaba/nacos/releases/latest | grep tag_name |  awk -F '"' '{print $(NF-1)}'

# 获取当前主机系统和主版本
if [ -f "/etc/debian_version" ]; then
source /etc/os-release && os="${ID}"
elif [ -f "/etc/fedora-release" ]; then
os="fedora"
elif [ -f "/etc/redhat-release" ]; then
os="centos"
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
```
