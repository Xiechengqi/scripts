#!/usr/bin/env bash

#
# xiechengqi
# 2022/10/27
# Ubuntu 18.04+
# install kubeadm kubelet kubectl
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

_ubuntu() {

if [ "$countryCode" = "CN" ]
then
curl -SsL https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 
cat >/etc/apt/sources.list.d/kubernetes.list << EOF
deb https://mirrors.ustc.edu.cn/kubernetes/apt/ kubernetes-xenial main
EOF
else
curl -SsL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat >/etc/apt/sources.list.d/kubernetes.list << EOF
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
fi

# install
INFO "apt-get update"
apt-get update || exit 1
EXEC "apt-get -y install curl apt-transport-https"
EXEC "apt-mark unhold kubelet kubeadm kubectl"
INFO "apt-get install -y kubectl=1.23.13-00 kubelet=1.23.13-00 kubeadm=1.23.13-00"
apt-get install -y kubectl=1.23.13-00 kubelet=1.23.13-00 kubeadm=1.23.13-00 || exit 1
EXEC "apt-mark hold kubelet kubeadm kubectl"

}

_centos() {
sleep 1s
}

main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20|ubuntu22' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20、centos7、centos8"

# environments
serviceName="kubelet"
# countryCode=`curl -SsL https://api.ip.sb/geoip | sed 's/,/\n/g' | grep country_code | awk -F '"' '{print $(NF-1)}'`
curl -SsL cip.cc | grep -E '^地址' | head -1 | grep '中国' &> /dev/null && countryCode="CN" || countryCode="Other"

# check if installed
kubectl version --client && kubeadm version && YELLOW "kubectl and kubeadm have installed ..." && return 0

echo $osInfo | grep ubuntu &> /dev/null && _ubuntu
# echo $osInfo | grep centos &> /dev/null && _centos

# check
INFO "kubectl version --client"
kubectl version --client
INFO "kubeadm version"
kubeadm version

}

main $@
