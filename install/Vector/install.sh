#!/usr/bin/env bash

#
# 2025/04/14
# xiechengqi
# install Vector
# docs: https://vector.dev/docs/setup/quickstart/
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Vector/install.sh | sudo bash
# os: ubuntu22
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
serviceName="vector"
version="0.46.0"
installPath="/data/${serviceName}"
downloadUrl="https://file.xiecq.top/helm-charts/siglens/siglens"
sourceDownloadUrl="https://github.com/vectordotdev/vector/releases/download/v${version}/vector-${version}-x86_64-unknown-linux-gnu.tar.gz"
[ "${countryCode}" = "China" ] && sourceDownloadUrl="${GITHUB_PROXY}/${sourceDownloadUrl}"
binary="vector"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath} /tmp/${serviceName} /var/lib/vector"
EXEC "mkdir -p ${installPath} /tmp/${serviceName}"
EXEC "mkdir -p ${installPath}/{bin,conf,logs}"
EXEC "mkdir -p /var/lib/vector"
EXEC "ln -fs /var/lib/vector ${installPath}/data"

# download tarball
EXEC "curl -SsL ${sourceDownloadUrl} | tar zx --strip-components 2 -C /tmp/${serviceName}/"
EXEC "cp -f /tmp/${serviceName}/bin/${binary} ${installPath}/bin/"
EXEC "chmod +x ${installPath}/bin/${binary}"

# register bin
EXEC "ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
INFO "${binary} -V" && ${binary} -V

# create config
cat > ${installPath}/conf/demo_logs.yaml << EOF
sources:
  generate_syslog:
    type:   "demo_logs"
    format: "syslog"
    count:  100

transforms:
  remap_syslog:
    inputs:
      - "generate_syslog"
    type:   "remap"
    source: |
            structured = parse_syslog!(.message)
            . = merge(., structured)

sinks:
  emit_syslog:
    inputs:
      - "remap_syslog"
    type: "console"
    encoding:
      codec: "json"
EOF

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

export installPath="${installPath}" && cd \${installPath}
export data_dir="\${installPath}/data"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

# check config
\${installPath}/bin/${binary} validate --config-dir \${installPath}/conf || exit 1

# --watch -config/-w: 更改其配置文件时，自动重新加载
# --watch-config-poll-interval-seconds: 检测配置文件变更间隔，默认 30s
\${installPath}/bin/${binary} --config-dir \${installPath}/conf --watch-config &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=https://github.com/vectordotdev/vector
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
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
