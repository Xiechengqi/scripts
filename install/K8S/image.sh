#!/usr/bin/env bash

#
# xiechengqi
# 2025/03/20
# Ubuntu 18.04+
# Usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/K8S/image.sh | sudo bash -s [docker|containerd]
# kubeadm pull k8s images
# Containerd:  unix:///var/run/containerd/containerd.sock
# CRI-O:  unix:///var/run/crio/crio.sock
# Docker Engine(cri-dockerd):  unix:///var/run/cri-dockerd.sock
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

function usage() {
INFO "curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/K8S/image.sh | sudo bash -s [docker|containerd]"
exit 0
}

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."

cri=${1-"docker"}
case cri in
"docker")
criSocket="unix:///var/run/cri-dockerd.sock"
pullCmd="docker pull"
tagCmd="docker tag"
;;
"containerd")
criSocket="unix:///var/run/containerd/containerd.sock"
pullCmd="ctr -n k8s.io i pull"
tagCmd="ctr -n k8s.io i tag"
;;
*)
usage
esac
criSocketOption="--cri-socket ${criSocket}"

EXEC "kubeadm config images list > /tmp/k8s_office_images.list"
INFO "cat /tmp/k8s_office_images.list" && cat /tmp/k8s_office_images.list

# pull images
[ "$countryCode" = "China" ] && imageRepository="k8s-gcr.m.daocloud.io"
if [ "$countryCode" = "China" ]
then
for image in $(cat /tmp/k8s_office_images.list)
do
local cnImage=$(echo ${image} | sed "s/registry.k8s.io/${imageRepository}/g")
INFO "${pullCmd} ${cnImage}" && ${pullCmd} ${cnImage} || exit 1
INFO "${tagCmd} ${cnImage} ${image}" && ${tagCmd} ${cnImage} ${image} || exit 1
done
else
for image in $(cat /tmp/k8s_office_images.list)
do
INFO "${pullCmd} ${image}" && ${pullCmd} ${image} || exit 1
done
fi

INFO "kubeadm config images pull ${criSocketOption}" && kubeadm config images pull ${criSocketOption} || exit 1

}

main $@
