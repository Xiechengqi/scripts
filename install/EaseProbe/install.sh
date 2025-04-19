#!/usr/bin/env bash

#
# 2025/04/19
# xiechengqi
# install easeprobe
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Easeprobe/install.sh | sudo bash
# config: https://github.com/megaease/easeprobe/blob/main/docs/Manual.md
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
serviceName="easeprobe"
version="2.2.1"
installPath="/data/${serviceName}"
downloadUrl="https://github.com/megaease/easeprobe/releases/download/v${version}/easeprobe-v${version}-linux-amd64.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
binary="easeprobe"
httpPort="8181"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,conf,logs}"

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx --strip-components 1 -C ${installPath}/bin/"
EXEC "chmod +x ${installPath}/bin/${binary}"

# register bin
EXEC "ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
INFO "${binary} -v" && ${binary} -v

# create conf
cat > ${installPath}/conf/${serviceName}.yaml << EOF
http:
  - name: elasticsearch
    url: http://elasticsearch/_cluster/health
    method: GET
    content_encoding: text/json
    insecure: true
    success_code:
      - [200,206]
      - [300,308]
    contain: "cluster_name"
    eval:
      doc: JSON
      expression: "x_str('//status')"
    labels:
      env: dev

ping:
  - name: Ping HK
    host: hk
    count: 5 # number of packets to send, default: 3
    lost: 0.2 # 20% lost percentage threshold, mark it down if the loss is greater than this, default: 0
    privileged: true # if true, the ping will be executed with icmp, otherwise use udp, default: false (Note: On Windows platform, this must be set to True)
    timeout: 10s # default is 30 seconds
    interval: 2m # default is 60 seconds
    labels:
      env: production

# TCP Probe Configuration
tcp:
  - name: SSH HK
    host: hk:22
    timeout: 10s # default is 30 seconds
    interval: 2m # default is 60 seconds
    nolinger: true # Disable SO_LINGER
    labels:
      env: production

# Notification Configuration
notify:
  log:
    - name: log file # local log file
      file: ${installPath}/logs/notify.log

#   wecom:
#     - name: "wechat alert"
#       webhook: ""

# Global settings for all probes and notifiers.
settings:
  name: "EaseProbe" # the name of the probe: default: "EaseProbe"
  icon: "https://megaease.com/favicon.png" # the icon of the probe. default: "https://megaease.com/favicon.png"
  pid: ${installPath}/easeprobe.pid

  # A HTTP Server configuration
  http:
    ip: 0.0.0.0 # the IP address of the server. default:"0.0.0.0"
    port: 8181 # the port of the server. default: 8181
    refresh: 30s # the auto-refresh interval of the server. default: the minimum value of the probes' interval.
    log:
      file: ${installPath}/logs/http.log # access log file. default: Stdout
      # Log Rotate Configuration (optional)
      self_rotate: true # true: self rotate log file. default: true
      size: 10 # max of access log file size. default: 10m
      age: 7 #  max of access log file age. default: 7 days
      backups: 5 # max of access log file backups. default: 5
      compress: true # compress the access log file. default: true

  probe:
    timeout: 30s # the time out for all probes
    interval: 1m # probe every minute for all probes
    failure: 2 # number of consecutive failed probes needed to determine the status down, default: 1
    success: 1 # number of consecutive successful probes needed to determine the status up, default: 1
    alert: # alert interval for all probes
      strategy: "regular" # it can be "regular", "increment" or "exponent", default: "regular"
      factor: 1 # the factor of the interval, default: 1
      max: 1 # the max of the alert, default: 1

  log:
    file: ${installPath}/logs/probe.log # default: stdout
    level: "info" # can be: panic, fatal, error, warn, info, debug.
    self_rotate: true # default: true
    size: 10 # max size of log file. default: 10M
    age: 7 # max age days of log file. default: 7 days
    backups: 5 # max backup log files. default: 5
    compress: true # compress. default: true

  timeformat: "2006-01-02 15:04:05"
  timezone: "Asia/Shanghai"
EOF

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

export installPath="${installPath}" && cd \${installPath}

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/${binary} -f \${installPath}/conf/${serviceName}.yaml &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=https://github.com/megaease/easeprobe
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
YELLOW "http port: ${httpPort}"
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
