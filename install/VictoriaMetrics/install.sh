#!/usr/bin/env bash

#
# 2025/04/22
# xiechengqi
# install VictoriaMetrics
# docs: https://docs.victoriametrics.com/quick-start/
# scrape config: https://docs.victoriametrics.com/scrape_config_examples/
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/VictoriaMetrics/install.sh | sudo bash
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
serviceName="victoriametrics"
version="1.115.0"
installPath="/data/${serviceName}"
downloadUrl="https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${version}/victoria-metrics-linux-amd64-v${version}.tar.gz"
[ "${countryCode}" = "China" ] && downloadUrl="${GITHUB_PROXY}/${downloadUrl}"
binary="victoria-metrics-prod"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{bin,logs}"

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx -C ${installPath}/bin/"

# register bin
EXEC "ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
EXEC "${binary} -version" && ${binary} -version

# create scrape config demo
cat > ${installPath}/scrape.yaml << EOF
scrape_configs:
- job_name: local-victoriametrics
  static_configs:
  - targets:
    - http://localhost:8428/metrics

- job_name: k8s-node-exporter
  kubernetes_sd_configs:
  - role: endpoints
    kubeconfig_file: "/root/.kube/config"
  scrape_interval: 30s
  metrics_path: /metrics
  relabel_configs:
  - action: keep
    source_labels:
    - __meta_kubernetes_endpoints_name
    regex: .*node-exporter.*
  - action: keep
    source_labels:
    - __meta_kubernetes_pod_container_port_number
    regex: 9100

- job_name: k8s-argocd-application-controller-metrics
  kubernetes_sd_configs:
  - role: endpoints
    kubeconfig_file: "/root/.kube/config"
  scrape_interval: 30s
  metrics_path: /metrics
  relabel_configs:
  - action: keep
    source_labels:
    - __meta_kubernetes_endpoints_name
    regex: argo-cd-argocd-application-controller-metrics
  - action: keep
    source_labels:
    - __meta_kubernetes_pod_container_port_number
    regex: 8082
EOF

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

export installPath="${installPath}"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/victoria-metrics-prod -promscrape.config=\${installPath}/scrape.yaml -storageDataPath=\${installPath}/data -retentionPeriod=90d -selfScrapeInterval=10s &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=https://github.com/VictoriaMetrics/VictoriaMetrics
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
