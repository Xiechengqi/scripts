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

EXEC "rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg"
EXEC "curl -fsSL https://pkgs.k8s.io/core:/stable:/${version}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg"
cat > /etc/apt/sources.list.d/kubernetes.list << EOF
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors.tuna.tsinghua.edu.cn/kubernetes/core:/stable:/${version}/deb/ /
EOF

INFO "cat /etc/apt/sources.list.d/kubernetes.list"
cat /etc/apt/sources.list.d/kubernetes.list

# install
INFO "apt-get update"
apt-get update || exit 1
EXEC "apt-get -y install curl apt-transport-https"
INFO "apt-get install -y kubectl kubelet kubeadm"
apt-get install -y kubectl kubelet kubeadm || exit 1
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
version="v1.28"
# countryCode=`curl -SsL https://api.ip.sb/geoip | sed 's/,/\n/g' | grep country_code | awk -F '"' '{print $(NF-1)}'`
curl -SsL cip.cc | grep -E '^地址' | head -1 | grep '中国' &> /dev/null && countryCode="CN" || countryCode="Other"

# check if installed
kubectl version --client &> /dev/null && kubeadm version &> /dev/null && YELLOW "kubectl and kubeadm have installed ..." && return 0

echo $osInfo | grep ubuntu &> /dev/null && _ubuntu
# echo $osInfo | grep centos &> /dev/null && _centos

# check
INFO "kubectl version --client"
kubectl version --client
INFO "kubeadm version"
kubeadm version

}

main $@
