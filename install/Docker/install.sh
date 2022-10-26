#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/09
# Ubuntu 18.04+
# https://docs.docker.com/engine/install/ubuntu/
# install docker
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

_ubuntu() {
# remove old apps
apt-get remove docker docker-engine docker.io containerd runc &> /dev/null

# install requirements
EXEC "export DEBIAN_FRONTEND=noninteractive"
EXEC "apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release"

# add app source
EXEC "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg"
if [ "$countryCode" = "CN" ]
then
cat > /etc/apt/sources.list.d/docker.list << EOF
deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu $(lsb_release -cs) stable
EOF
else
cat > /etc/apt/sources.list.d/docker.list << EOF
deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable
EOF
fi

# install
EXEC "apt-get update && apt-get -y install docker-ce docker-ce-cli containerd.io"
}

_centos() {
INFO "yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine" && yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
EXEC "yum install -y yum-utils device-mapper-persistent-data lvm2"
EXEC "yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo"
[ "${countryCode}" = "CN" ] && EXEC "sed -i 's+download.docker.com+mirrors.tuna.tsinghua.edu.cn/docker-ce+' /etc/yum.repos.d/docker-ce.repo" && EXEC "yum makecache fast"
EXEC "yum install -y docker-ce docker-ce-cli containerd.io"
}

main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20|centos7|centos8' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20、centos7、centos8"

# environments
serviceName="docker"
# countryCode=`curl -SsL https://api.ip.sb/geoip | sed 's/,/\n/g' | grep country_code | awk -F '"' '{print $(NF-1)}'`
curl -SsL cip.cc | grep -E '^地址' | head -1 | grep '中国' &> /dev/null && countryCode="CN" || countryCode="Other"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0

echo $osInfo | grep ubuntu &> /dev/null && _ubuntu
echo $osInfo | grep centos &> /dev/null && _centos

# add log config
cat > /etc/docker/daemon.json << EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# start service
EXEC "systemctl enable docker && systemctl restart docker"

# check docker
INFO "docker run hello-world" && docker run hello-world
}

main $@
