``` shell
# 获取当前主机的 ipv4
curl ip.sb -4

# 获取当前主机所在国家缩写
curl -SsL https://api.ip.sb/geoip | sed 's/,/\n/g' | grep country_code | awk -F '"' '{print $(NF-1)}'

# 判断用户是否为 root
[ $(id -u) = "0" ] && echo "yes" || echo "no"


```
