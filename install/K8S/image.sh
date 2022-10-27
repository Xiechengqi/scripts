#!/usr/bin/env bash

#
# xiechengqi
# 2022/10/27
# Ubuntu 18.04+
# docker pull k8s used images
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# countryCode=`curl -SsL https://api.ip.sb/geoip | sed 's/,/\n/g' | grep country_code | awk -F '"' '{print $(NF-1)}'`
curl -SsL cip.cc | grep -E '^地址' | head -1 | grep '中国' &> /dev/null && countryCode="CN" || countryCode="Other"

# check if installed
systemctl is-active docker &> /dev/null && kubectl version --client &> /dev/null && kubeadm version &> /dev/null || ERROR "Please install docker or kubectl or kubeadm first ..."

if [ "$countryCode" = "CN" ]
then
INFO "kubeadm config images pull --image-repository registry.aliyuncs.com/google_containers"
kubeadm config images pull --image-repository registry.aliyuncs.com/google_containers || exit 1
EXEC "kubeadm config images list > /tmp/$$_office_images.list"
cat /tmp/$$_office_images.list
EXEC "kubeadm config images list --image-repository registry.aliyuncs.com/google_containers > /tmp/$$_cn_images.list"
cat /tmp/$$_cn_images.list
for cnImageUrl in $(cat /tmp/$$_cn_images.list)
do
imageName=$(echo ${cnImageUrl} | awk -F '/' '{print $NF}')
officeImageUrl=$(cat /tmp/$$_office_images.list | grep -E "${imageName}$")
EXEC "docker tag ${cnImageUrl} ${officeImageUrl} && docker rmi ${cnImageUrl}"
done

EOF
else
INFO "kubeadm config images pull"
kubeadm config images pull || exit 1
EOF
fi

INFO "docker images"
docker images

}

main $@
