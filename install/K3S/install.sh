#!/usr/bin/env bash

#
# 2025/04/24
# xiechengqi
# install K3S
# docs: https://docs.k3s.io/zh/installation/configuration
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/K3S/install.sh | sudo bash
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
serviceName="k3s"
version="1.32.3"
installPath="/data/${serviceName}"
downloadUrl="https://github.com/k3s-io/k3s/releases/download/v${version}%2Bk3s1/k3s"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
binary="k3s"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check containerd service
EXEC "systemctl is-active containerd"

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,data,logs}"

# download tarball
EXEC "curl -SsL ${downloadUrl} -o ${installPath}/bin/${binary} && chmod +x ${installPath}/bin/${binary}"

# register bin
EXEC "ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
EXEC "${binary} -version" && ${binary} -version

# create config
cat > ${installPath}/${serviceName}.yaml << EOF
write-kubeconfig-mode: "0644"
cluster-init: true
EOF

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

export installPath="${installPath}"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/k3s server --write-kubeconfig \${installPath}/kubeconfig --config \${installPath}/${serviceName}.yaml --data-dir \${installPath}/data --container-runtime-endpoint unix:///var/run/containerd/containerd.sock &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=https://github.com/k3s-io/k3s
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

# copy kubeconfig
EXEC "mkdir -p /root/.kube && cp -f ${installPath}/kubeconfig /root/.kube/config"

# info
YELLOW "${serviceName} version: ${version}"
YELLOW "install: ${installPath}"
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
