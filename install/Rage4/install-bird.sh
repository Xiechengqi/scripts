#!/usr/bin/env bash
#
# 2025/08/23
# xiechengqi
# install rage4 bird
# usage: curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Rage4/install-bird.sh | bash -s REGION RAGE_ANYCAST_NETWORK_PASSWORD
#

source /etc/profile
BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
source <(curl -SsL $BASEURL/tool/common.sh)

USAGE() {
INFO "curl -SsL ${BASEURL}/install/Rage4/install-bird.sh | bash -s REGION ANYCASTIP1,ANYCASTIP2..."
exit 0
}

main() {

EXEC "systemctl is-active zerotier-one"
EXEC "export DEBIAN_FRONTEND=noninteractive"

# environment
export serviceName="bird"
export installPath="/data/${serviceName}" && EXEC "mkdir -p ${installPath}"
export anycastIpLocationUrl="${BASEURL}/install/Rage4/anycast-ip-location.txt"
EXEC "curl -SsL ${anycastIpLocationUrl} -o ${installPath}/anycast-ip-location.txt"
export REGION=${1}
[ ".${REGION}" = "." ] && USAGE

EXEC "grep ${REGION} ${installPath}/anycast-ip-location.txt"
export ANYCAST_GW="172.31.255."$(grep ${REGION} ${installPath}/anycast-ip-location.txt | head -1 | awk -F '172.31.255.' '{print $NF}' | awk '{print $1}')
export RAGE_ANYCAST_NETWORK_PASSWORD=${2}
[ ".${RAGE_ANYCAST_NETWORK_PASSWORD}" = "." ] && USAGE
# eg: 185.187.152.11,185.187.153,3
EXEC "grep 'export ANYCAST_IP_LIST' /data/zerotier-one/post-start.sh"
export ANYCAST_IP_LIST=$(grep 'export ANYCAST_IP_LIST' /data/zerotier-one/post-start.sh | awk -F '=' '{print $NF}')
export ZEROTIER_IP=$(ifconfig | grep -B1 'inet 172.3' | tail -1 | awk -F 'inet ' '{print $NF}' | awk '{print $1}')
export ZEROTIER_DEVICE=$(ifconfig | grep -B1 'inet 172.3' | head -1 | awk -F ':' '{print $1}')
export RAGE_ANYCAST_DEVICE="dummy0"
export RAGE_ANYCAST_ASNUM="65026"

# check servcie
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "cd ${installPath}"

# install
EXEC "apt update"
INFO "apt install -y bird2" && apt install -y bird2
systemctl is-active ${serviceName} &> /dev/null || EXEC "systemctl start ${serviceName}"

cat > /etc/bird/bird.conf << EOF
log syslog all;

router id ${ZEROTIER_IP};

filter out_filter {
EOF

for IP in $(echo ${ANYCAST_IP_LIST} | tr ',' '\n')
do
cat >> /etc/bird/bird.conf << EOF
    if net = ${IP}/32 then accept;
EOF
done

cat >> /etc/bird/bird.conf << EOF
    else reject;
}

protocol bgp anycastip4
{
  local as ${RAGE_ANYCAST_ASNUM};
  source address ${ZEROTIER_IP};
  ipv4 {
    import all;
    export filter out_filter;
    next hop self;
  };
  graceful restart on;
  multihop 25;
  neighbor ${ANYCAST_GW} as 198412;
  password "${RAGE_ANYCAST_NETWORK_PASSWORD}";
}

protocol static
{
    ipv4;
EOF

for IP in $(echo ${ANYCAST_IP_LIST} | tr ',' '\n')
do
cat >> /etc/bird/bird.conf << EOF
    route ${IP}/32 via ${ZEROTIER_IP};
EOF
done

cat >> /etc/bird/bird.conf << EOF
}

protocol direct {
  interface "${ZEROTIER_DEVICE}";
  interface "${RAGE_ANYCAST_DEVICE}";
}

protocol kernel {
  scan time 60;
  ipv4 {
    import all;
    export where source=RTS_STATIC;
  };
}

protocol device
{
    scan time 5;
}
EOF

INFO "cat /etc/bird/bird.conf" && cat /etc/bird/bird.conf
EXEC "sleep 10"

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName} && systemctl restart ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# check
INFO "birdc show protocols all" && birdc show protocols all

}

main $@
