#!/usr/bin/env bash

#
# xiechengqi
# 2025/03/20
# Ubuntu 18.04+
# Usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/K8S/image.sh | sudo bash [-s cri_socket_path]
# kubeadm pull k8s images
# Containerd:  unix:///var/run/containerd/containerd.sock
# CRI-O:  unix:///var/run/crio/crio.sock
# Docker Engine(cri-dockerd):  unix:///var/run/cri-dockerd.sock
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."

# Env
[ "$countryCode" = "China" ] && imageRepositoryOption="--image-repository k8s-gcr.m.daocloud.io" || imageRepositoryOption=""
criSocket=${1-"unix:///var/run/cri-dockerd.sock"}
criSocketOption="--cri-socket ${criSocket}"

# pull images
INFO "kubeadm config images pull ${criSocketOption} ${imageRepositoryOption}" && kubeadm config images pull ${criSocketOption} ${imageRepositoryOption} || exit 1

# if [ "$countryCode" = "China" ]
# then
# EXEC "kubeadm config images list > /tmp/k8s_office_images.list"
# cat /tmp/k8s_office_images.list
# EXEC "kubeadm config images list --image-repository registry.aliyuncs.com/google_containers > /tmp/k8s_cn_images.list"
# cat /tmp/k8s_cn_images.list
# for cnImageUrl in $(cat /tmp/k8s_cn_images.list)
# do
# imageName=$(echo ${cnImageUrl} | awk -F '/' '{print $NF}')
# officeImageUrl=$(cat /tmp/$$_office_images.list | grep -E "${imageName}$")
# EXEC "docker tag ${cnImageUrl} ${officeImageUrl} && docker rmi ${cnImageUrl}"
# done
# fi

}

main $@
