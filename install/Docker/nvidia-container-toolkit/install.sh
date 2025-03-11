#!/usr/bin/env bash

#
# xiechengqi
# 2025/03/12
# install docker nvidia-container-toolkit
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20|ubuntu22' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20、ubuntu22"

EXEC "curl -fsSL https://gitee.com/Xiechengqi/scripts/raw/master/install/Docker/nvidia-container-toolkit/libnvidia-container1_1.17.5-1_amd64.deb -o /tmp/libnvidia-container1_1.17.5-1_amd64.deb && dpkg -i /tmp/libnvidia-container1_1.17.5-1_amd64.deb"
EXEC "curl -fsSL https://gitee.com/Xiechengqi/scripts/raw/master/install/Docker/nvidia-container-toolkit/libnvidia-container-tools_1.17.5-1_amd64.deb -o /tmp/libnvidia-container-tools_1.17.5-1_amd64.deb && dpkg -i /tmp/libnvidia-container-tools_1.17.5-1_amd64.deb"
EXEC "curl -fsSL https://gitee.com/Xiechengqi/scripts/raw/master/install/Docker/nvidia-container-toolkit/nvidia-container-toolkit-base_1.17.5-1_amd64.deb -o /tmp/nvidia-container-toolkit-base_1.17.5-1_amd64.deb && dpkg -i /tmp/nvidia-container-toolkit-base_1.17.5-1_amd64.deb"
EXEC "curl -fsSL https://gitee.com/Xiechengqi/scripts/raw/master/install/Docker/nvidia-container-toolkit/nvidia-container-toolkit_1.17.5-1_amd64.deb -o /tmp/nvidia-container-toolkit_1.17.5-1_amd64.deb && dpkg -i /tmp/nvidia-container-toolkit_1.17.5-1_amd64.deb"
# 使用 nvidia-ctk 命令修改 /etc/docker/daemon.json 文件，设置 Docker 默认使用 NVIDIA runtime
EXEC "nvidia-ctk runtime configure --runtime=docker"
INFO "cat /etc/docker/daemon.json" && cat /etc/docker/daemon.json
EXEC "systemctl restart docker"
INFO "docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi" && docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi

}

main $@
