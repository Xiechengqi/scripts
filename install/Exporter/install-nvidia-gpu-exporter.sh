#!/usr/bin/env bash

#
# 2025/04/02
# xiechengqi
# install nvidia-gpu-exporter
# https://github.com/utkuozdemir/nvidia_gpu_exporter
# pre request: install nvidia-smi
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Nvidia/install-nvidia-gpu-exporter.sh | sudo bash
#

source /etc/profile
# BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

# environment
serviceName="nvidia-gpu-exporter"
version="1.3.0"
installPath="/data/${serviceName}"
downloadUrl="https://github.com/utkuozdemir/nvidia_gpu_exporter/releases/download/v${version}/nvidia_gpu_exporter_${version}_linux_x86_64.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
port=${1-"9835"}

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check nvidia-smi
EXEC "nvidia-smi"

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/logs"

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}"

# register bin
EXEC "ln -fs ${installPath}/nvidia_gpu_exporter /usr/bin/nvidia_gpu_exporter"
EXEC "nvidia_gpu_exporter --version" && nvidia_gpu_exporter --version

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

export installPath="${installPath}"
\${installPath}/nvidia_gpu_exporter --web.listen-address=":${port}" &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=node-exporter
Documentation=https://github.com/utkuozdemir/nvidia_gpu_exporter
After=network.target

[Service]
User=root
Group=root
ExecStart=/bin/bash ${installPath}/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName} && systemctl start ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# info
YELLOW "${serviceName} version: ${version}"
YELLOW "install: ${installPath}"
YELLOW "port: ${port}"
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
