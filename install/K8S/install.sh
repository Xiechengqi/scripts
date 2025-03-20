#!/usr/bin/env bash

#
# xiechengqi
# 2025/03/20
# Ubuntu 18.04+
# install kubeadm kubelet kubectl
# China: https://mirrors.tuna.tsinghua.edu.cn/help/kubernetes/
# Other: https://v1-28.docs.kubernetes.io/zh-cn/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

_ubuntu() {

INFO "apt remove kubectl kubelet kubeadm" && apt remove kubectl kubelet kubeadm
EXEC "apt update"
EXEC "apt install -y apt-transport-https ca-certificates curl gpg"
EXEC "mkdir -p -m 755 /etc/apt/keyrings"
EXEC "rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg"
EXEC "curl -fsSL https://pkgs.k8s.io/core:/stable:/${version}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg"
if [ "${countryCode}" = "China" ]
then
cat > /etc/apt/sources.list.d/kubernetes.list << EOF
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://mirrors.tuna.tsinghua.edu.cn/kubernetes/core:/stable:/${version}/deb/ /
EOF
else
cat > /etc/apt/sources.list.d/kubernetes.list << EOF
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${version}/deb/ /
EOF
INFO "cat /etc/apt/sources.list.d/kubernetes.list" && cat /etc/apt/sources.list.d/kubernetes.list

# install
INFO "apt update" && apt update || exit 1
INFO "apt install -y kubectl kubelet kubeadm" && apt install -y kubectl kubelet kubeadm || exit 1
EXEC "apt-mark hold kubelet kubeadm kubectl"

}

_centos() {

cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=kubernetes
baseurl=https://mirrors.tuna.tsinghua.edu.cn/kubernetes/yum/repos/kubernetes-el7-$basearch
name=Kubernetes
baseurl=https://mirrors.tuna.tsinghua.edu.cn/kubernetes/core:/stable:/${version}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/${version}/rpm/repodata/repomd.xml.key
EOF
INFO "cat /etc/yum.repos.d/kubernetes.repo" && cat /etc/yum.repos.d/kubernetes.repo

}

main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20|ubuntu22' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20、ubuntu22"
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."

# environments
version="v1.28"

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
