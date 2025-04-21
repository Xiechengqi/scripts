#!/usr/bin/env bash

#
# 2025/04/21
# xiechengqi
# install grafana alloy
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Grafana/Alloy/install.sh | sudo bash
# doc: https://grafana.com/docs/alloy/latest/set-up/install/binary/
# config: https://grafana.com/docs/alloy/latest/configure/
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
serviceName="alloy"
version="1.8.1"
installPath="/data/${serviceName}"
downloadUrl="https://github.com/grafana/alloy/releases/download/v${version}/alloy-linux-amd64.zip"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
binary="alloy"
port="3110"
lokiUrl=${1-"http://localhost:3100"}

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# pre check
EXEC "which unzip"

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{data,bin,logs}"

# download tarball
EXEC "curl -SsL ${downloadUrl} -o /tmp/${serviceName}.zip && unzip /tmp/${serviceName}.zip -d ${installPath}/bin/"
EXEC "mv ${installPath}/bin/alloy-linux-amd64 ${installPath}/bin/${binary}"
EXEC "chmod +x ${installPath}/bin/*"

# register bin
EXEC "ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
INFO "${binary} -v" && ${binary} -v

# create conf
cat > ${installPath}/${serviceName}.yaml << EOF
loki.write "loki" {
  endpoint {
    url = "${lokiUrl}/loki/api/v1/push"
//    basic_auth {
//      username = "<USERNAME>"
//      password = "<PASSWORD>"
//    }
  }
}

// System logs
// local.file_match discovers files on the local filesystem using glob patterns and the doublestar library. It returns an array of file paths.
local.file_match "syslog" {
  path_targets = [{
      __path__  = "/var/log/syslog",
      job       = "syslog",
      hostname = "k8s-master1",
  }]
}

// loki.source.file reads log entries from files and forwards them to other loki.* components.
// You can specify multiple loki.source.file components by giving them different labels.
loki.source.file "syslog" {
  targets    = local.file_match.syslog.targets
  forward_to = [loki.write.loki.receiver]
}
EOF

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

export installPath="${installPath}" && cd \${installPath}

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/${binary} run --storage.path=\${installPath}/data --server.http.listen-addr=0.0.0.0:${port} \${installPath}/${serviceName}.yaml &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=https://github.com/grafana/alloy
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
