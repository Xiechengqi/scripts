#!/usr/bin/env bash

#
# xiechengqi
# 2025/04/24
# install nvidia-container-toolkit
# docs: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Nvidia/Nvidia-Container-Toolkit/install.sh | sudo bash
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

gpgkeyUrl="https://raw.githubusercontent.com/NVIDIA/libnvidia-container/refs/heads/gh-pages/gpgkey"
[ "${countryCode}" = "China" ] && gpgkeyUrl="${GITHUB_PROXY}/${gpgkeyUrl}"
sourceListUrl="https://raw.githubusercontent.com/NVIDIA/libnvidia-container/refs/heads/gh-pages/stable/deb/nvidia-container-toolkit.list"
[ "${countryCode}" = "China" ] && sourceListUrl="${GITHUB_PROXY}/${sourceListUrl}"

EXEC "rm -f /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg"
EXEC "curl -SsL ${gpgkeyUrl} | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg"
curl -SsL ${sourceListUrl} | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' > /etc/apt/sources.list.d/nvidia-container-toolkit.list
[ "${countryCode}" = "China" ] && sed -i "s#https://nvidia.github.io/libnvidia-container/stable/deb#${GITHUB_PROXY}/https://raw.githubusercontent.com/NVIDIA/libnvidia-container/refs/heads/gh-pages/stable/deb#g" /etc/apt/sources.list.d/nvidia-container-toolkit.list
INFO "cat /etc/apt/sources.list.d/nvidia-container-toolkit.list" && cat /etc/apt/sources.list.d/nvidia-container-toolkit.list
INFO "apt update" && apt update || exit 1
INFO "apt install -y nvidia-container-toolkit" && apt install -y nvidia-container-toolkit || exit 1

YELLOW "nvidia-ctk runtime configure --runtime=[docker|containerd|crio]"
YELLOW "Doc: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html"

}

main $@
