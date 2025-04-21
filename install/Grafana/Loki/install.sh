#!/usr/bin/env bash

#
# 2025/04/21
# xiechengqi
# install grafana loki
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Grafana/Loki/install.sh | sudo bash
# doc: https://grafana.com/docs/loki/latest/setup/install/local/
# config: https://grafana.com/docs/loki/latest/configure/
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
serviceName="loki"
version="3.4.3"
installPath="/data/${serviceName}"
downloadUrl="https://github.com/grafana/loki/releases/download/v${version}/loki-linux-amd64.zip"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
logcliDownloadUrl="https://github.com/grafana/loki/releases/download/v${version}/logcli-linux-amd64.zip"
[ "${countryCode}" = "China" ] && logcliDownloadUrl="${GITHUB_PROXY}/${logcliDownloadUrl}"
lokitoolDownloadUrl="https://github.com/grafana/loki/releases/download/v${version}/lokitool-linux-amd64.zip"
[ "${countryCode}" = "China" ] && lokitoolDownloadUrl="${GITHUB_PROXY}/${lokitoolDownloadUrl}"
binary="loki"
port="3100"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# pre check
EXEC "which unzip"

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{data,bin,logs}"

# download tarball
EXEC "curl -SsL ${downloadUrl} -o /tmp/${serviceName}.zip && unzip /tmp/${serviceName}.zip -d ${installPath}/bin/"
EXEC "curl -SsL ${lokitoolDownloadUrl} -o /tmp/${serviceName}.zip && unzip /tmp/${serviceName}.zip -d ${installPath}/bin/"
EXEC "curl -SsL ${logcliDownloadUrl} -o /tmp/${serviceName}.zip && unzip /tmp/${serviceName}.zip -d ${installPath}/bin/"
EXEC "mv ${installPath}/bin/loki-linux-amd64 ${installPath}/bin/${binary}"
EXEC "mv ${installPath}/bin/logcli-linux-amd64 ${installPath}/bin/logcli"
EXEC "mv ${installPath}/bin/lokitool-linux-amd64 ${installPath}/bin/lokitool"
EXEC "chmod +x ${installPath}/bin/*"

# register bin
EXEC "ln -fs ${installPath}/bin/lo* /usr/local/bin/"
INFO "${binary} -version" && ${binary} -version

# create conf
cat > ${installPath}/${serviceName}.yaml << EOF
# https://raw.githubusercontent.com/grafana/loki/main/cmd/loki/loki-local-config.yaml
auth_enabled: false

server:
  http_listen_port: ${port}
  grpc_listen_port: 9096
  log_level: info
  grpc_server_max_concurrent_streams: 1000

common:
  instance_addr: 0.0.0.0
  path_prefix: ${installPath}/data
  storage:
    filesystem:
      chunks_directory: ${installPath}/data/chunks
      rules_directory: ${installPath}/data/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

query_range:
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 100

limits_config:
  metric_aggregation_enabled: true

schema_config:
  configs:
    - from: 2025-04-20
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

pattern_ingester:
  enabled: true
  metric_aggregation:
    loki_address: localhost:3100

# ruler:
#  alertmanager_url: http://localhost:9093

frontend:
  encoding: protobuf

# querier:
#   engine:
#     enable_multi_variant_queries: true
EOF

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

export installPath="${installPath}" && cd \${installPath}

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/${binary} -config.file=\${installPath}/${serviceName}.yaml &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=https://github.com/grafana/loki
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
