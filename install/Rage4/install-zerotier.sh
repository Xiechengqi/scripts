#!/usr/bin/env bash
#
# 2025/08/23
# xiechengqi
# install rage4 zerotier-one
# usage: curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/Rage4/install-zerotier.sh | bash -s REGION RAGE_ANYCAST_APIKEY ANYCASTIP1,ANYCASTIP2...
#

source /etc/profile
BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
source <(curl -SsL $BASEURL/tool/common.sh)

USAGE() {
INFO "curl -SsL ${BASEURL}/Rage4/install-zerotier.sh | bash -s REGION RAGE_ANYCAST_APIKEY ANYCASTIP1,ANYCASTIP2..."
exit 0
}

main() {

# environment
export serviceName="zerotier-one"
export installPath="/data/${serviceName}" && EXEC "mkdir -p ${installPath}"
export anycastIpLocationUrl="${BASEURL}/Rage4/anycast-ip-location.txt"
EXEC "curl -SsL ${anycastIpLocationUrl} -o ${installPath}/anycast-ip-location.txt"
export REGION=${1}
[ ".${REGION}" = "." ] && USAGE
EXEC "grep ${REGION} ${installPath}/anycast-ip-location.txt"
export ANYCAST_GW="172.31.255."$(grep ${REGION} ${installPath}/anycast-ip-location.txt | head -1 | awk -F '172.31.255.' '{print $NF}' | awk '{print $1}')
export RAGE_ANYCAST_APIKEY=${2}
[ ".${RAGE_ANYCAST_APIKEY}" = "." ] && USAGE
# eg: 185.187.152.11,185.187.153,3
export ANYCAST_IP_LIST=${3}
[ ".${ANYCAST_IP_LIST}" = "." ] && USAGE
export DEVICE="dummy0"
export RAGE_ANYCAST_URL='https://rage4.com'
export RAGE_ANYCAST_NETWORK="a80b1461811046f2"
export RAGE_ANYCAST_EMAIL="xiechengqi01@gmail.com"
export RAGE_ANYCAST_ASNUM="65012"
export RAGE_ANYCAST_REGION=$(grep ${REGION} ${installPath}/anycast-ip-location.txt | head -1 | awk -F '172.31.255.' '{print $1}' | awk '{print $NF}' | sed 's/[[:space:]]//g')

INFO "REGION: ${REGION}"
INFO "ANYCAST IP LIST: ${ANYCAST_IP_LIST}"
INFO "ANYCAST GATEWAY: ${ANYCAST_GW}"
INFO "RAGE4 ANYCAST URL: ${RAGE_ANYCAST_URL}"
INFO "RAGE4 ANYCAST NETWORK: ${RAGE_ANYCAST_NETWORK}"
INFO "RAGE4 ANYCAST EMAIL: ${RAGE_ANYCAST_EMAIL}"
INFO "RAGE4 ANYCAST APIKEY: ${RAGE_ANYCAST_APIKEY}"
INFO "RAGE4 ANYCAST ASNUM: ${RAGE_ANYCAST_ASNUM}"
INFO "RAGE4 ANYCAST REGION: ${RAGE_ANYCAST_REGION}"
EXEC "sleep 10"

# check servcie
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && ip a && return 0

# check install path
EXEC "cd ${installPath}"

# install
INFO "curl -s https://install.zerotier.com | sudo bash" && curl -s https://install.zerotier.com | sudo bash
INFO "ip a" && ip a
EXEC "sleep 3"
systemctl is-active ${serviceName} &> /dev/null || EXEC "systemctl start ${serviceName}"
EXEC "sleep 3"
EXEC "which zerotier-cli"
INFO "zerotier-cli join ${RAGE_ANYCAST_NETWORK}" && zerotier-cli join ${RAGE_ANYCAST_NETWORK} || exit 1
EXEC "sleep 3"
INFO "zerotier-cli info" && zerotier-cli info
export RAGE_ANYCAST_ZEROTIER=$(zerotier-cli info | awk '{print $3}')
export RAGE_ANYCAST_REGISTER_URL="${RAGE_ANYCAST_URL}/anycastapi/createnodeforasn/?zerotier=${RAGE_ANYCAST_ZEROTIER}&code=${RAGE_ANYCAST_REGION}&asnum=${RAGE_ANYCAST_ASNUM}"
INFO "RAGE4 ANYCAST REGISTER URL: ${RAGE_ANYCAST_REGISTER_URL}"
EXEC "sleep 3"
INFO "wget --user=${RAGE_ANYCAST_EMAIL} --password=${RAGE_ANYCAST_APIKEY} --auth-no-challenge -qO- ${RAGE_ANYCAST_REGISTER_URL}" && wget --user=${RAGE_ANYCAST_EMAIL} --password=${RAGE_ANYCAST_APIKEY} --auth-no-challenge -qO- ${RAGE_ANYCAST_REGISTER_URL} || exit 1
EXEC "sleep 5"
INFO "ip a" && ip a
EXEC "systemctl stop zerotier-one"
EXEC "sleep 5"
EXEC "systemctl start zerotier-one"
EXEC "sleep 5"
INFO "ip a" && ip a

cat > ${installPath}/post-start.sh << EOF
#!/usr/bin/env bash

export ANYCAST_IP_LIST=${ANYCAST_IP_LIST}
export ANYCAST_GW=${ANYCAST_GW}
export DEVICE=${DEVICE}

sleep 0.5
grep 'anycast' /etc/iproute2/rt_tables &> /dev/null || echo '666       anycast' >> /etc/iproute2/rt_tables
modprobe dummy
ip link set \${DEVICE} down
ip link del dev \${DEVICE} type dummy
ip link add \${DEVICE} type dummy
ip link set \${DEVICE} up
for IP in \$(echo \${ANYCAST_IP_LIST} | tr ',' '\\n'); do
ip -4 addr add dev \${DEVICE} \${IP}/32
ip -4 rule add from \${IP}/32 table anycast
done
ip -4 route add default via \${ANYCAST_GW} table anycast
EOF
EXEC "chmod +x ${installPath}/post-start.sh"

cat > ${installPath}/post-stop.sh << EOF
#!/usr/bin/env bash

export ANYCAST_GW=\$(ip -4 route show table anycast | awk '{ print \$3 }')
export DEVICE=${DEVICE}

[ "" != "\${ANYCAST_GW}" ] && ip -4 route del default via \${ANYCAST_GW} table anycast
ip link set \${DEVICE} down
ip link del dev \${DEVICE} type dummy
EOF
EXEC "chmod +x ${installPath}/post-stop.sh"

cat > /lib/systemd/system/zerotier-one.service << EOF
[Unit]
Description=ZeroTier One
After=network-online.target network.target
Wants=network-online.target

[Service]
ExecStart=/usr/sbin/zerotier-one
ExecStartPost=/bin/bash ${installPath}/post-start.sh
ExecStopPost=/bin/bash ${installPath}/post-stop.sh
Restart=always
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName} && systemctl restart ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

}

main $@
