#!/usr/bin/env bash

#
# 2023/02/09
# xiechengqi
# install https://docs.arweave.org/info/mining/mining-guide
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# environments
address=${1-"XQX6B-V_chp-wO5tNTajaZEhUivCOyt5oOE6YPK_QSA"}
version=${2-"2.6.0.0"}
serviceName="arweaved"
installPath="/scratch/${serviceName}-${version}"
echo "${osInfo}" | grep -E 'ubuntu20' &>/dev/null && downloadUrl="https://github.com/ArweaveTeam/arweave/releases/download/N.${version}/arweave-${version}.linux-x86_64.tar.gz" || downloadUrl="https://github.com/ArweaveTeam/arweave/releases/download/N.${version}/arweave-${version}.ubuntu18-x86_64.tar.gz"
transactionBlacklistUrl="http://shepherd-v.com/list.txt"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath} $(dirname ${installPath})/${serviceName}"
EXEC "mkdir -p ${installPath}/{bin,data,logs}"

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}"


# create start.sh
## ./bin/start stage_one_hashing_threads 32 stage_two_hashing_threads 32 io_threads 50 randomx_bulk_hashing_iterations 64 data_dir /your/dir mine sync_jobs 80 mining_addr YOUR-MINING-ADDRESS peer 188.166.200.45 peer 188.166.192.169 peer 163.47.11.64 peer 139.59.51.59 peer 138.197.232.192
## 使用巨大页: enable randomx_large_pages
cpuThreadNum=$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

installPath="${installPath}"
timestamp=\$(date +%Y%m%d%H%M%S)
touch \$installPath/logs/\${timestamp}.log && ln -fs \$installPath/logs/\${timestamp}.log \$installPath/logs/latest.log
${installPath}/bin/start mine sync_jobs 80 enable randomx_large_pages stage_one_hashing_threads ${cpuThreadNum} stage_two_hashing_threads ${cpuThreadNum} data_dir ${installPath}/data mining_addr ${address} peer 188.166.200.45 peer 188.166.192.169 peer 163.47.11.64 peer 139.59.51.59 peer 138.197.232.192 &> \$installPath/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=The Arweave server and App Developer Toolkit
Documentation=https://github.com/ArweaveTeam/arweave
After=network.target
[Service]
User=root
Group=root
LimitNOFILE=10000000
ExecStart=/bin/bash ${installPath}/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=2
[Install]
WantedBy=multi-user.target
EOF
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
EXEC "ln -fs ${installPath}/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

}

main $@
