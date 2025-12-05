#!/usr/bin/env bash

#
# 2025/04/14
# xiechengqi
# install SigLens
# docs: https://www.siglens.com/siglens-docs/installation/git
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/SigLens/install.sh | sudo bash
#

source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check location
countryCode=$(check_if_in_china)
[ ".${countryCode}" = "." ] && ERROR "Get country location fail ..."
INFO "Location: ${countryCode}"

# environment
serviceName="siglens"
version="1.0.35"
installPath="/data/${serviceName}"
downloadUrl="https://file.xiecq.top/helm-charts/siglens/siglens"
sourceDownloadUrl="https://github.com/siglens/siglens/archive/refs/tags/${version}.tar.gz"
[ "${countryCode}" = "China" ] && sourceDownloadUrl="${GITHUB_PROXY}/${sourceDownloadUrl}"
binary="siglens"
# dashboard ui port
queryPort="5122"
# log/metric push port
ingestPort="8081"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}"
EXEC "curl -SsL ${sourceDownloadUrl} | tar zx --strip-components 1 -C ${installPath}/"
EXEC "mkdir -p ${installPath}/{logs,data}"

# download tarball
EXEC "curl -SsL ${downloadUrl} -o ${installPath}/${binary}"
EXEC "chmod +x ${installPath}/${binary}"

# register bin
EXEC "ln -fs ${installPath}/${binary} /usr/local/bin/${binary}"

# create config
# config: https://github.com/siglens/siglens/releases/download/1.0.35/server.yaml
cat > ${installPath}/server.yaml << EOF
## IP and port for SigLens ingestion server
ingestListenIP: "[::]"
ingestPort: ${ingestPort}

## IP and port for SigLens query server, including UI
queryListenIP: "[::]"
queryPort: ${queryPort}

## Location for storing local node data
dataPath : data/

## field name to use as a timestamp key
timestampKey : timestamp

pqsEnabled: true

## Elasticsearch Version for kibana integration
esVersion: "7.9.3"

## Number of hours data will be stored/retained on persistent storage.
# retentionHours: 360

## For ephemeral servers (docker, k8s) set this variable to unique container name to persist data across restarts:
# the default ssInstanceName is "sigsingle"
ssInstanceName: "sigsingle"

log:
  logPrefix : ./logs/

  ## Maximum size of siglens.log file in megabytes
  # logFileRotationSizeMB: 100

  ## Compress log file
  # compressLogFile: false

# TLS configuration
tls:
  enabled: false   # Set to true to enable TLS
  certificatePath: ""  # Path to the certificate file
  privateKeyPath: ""   # Path to the private key file
  mtlsEnabled: false
  clientCaPath: ""  # Path to the client Certificate Authority file. Required for mTLS.

# SigLens server hostname
queryHostname: "$(hostname)"

queryTimeoutSecs: 300  # 5 minutes default

# memoryLimits:
#   lowMemoryMode: true  # Set to true to enable low memory mode
#   maxUsagePercent: 80  # Percent of available RAM that siglens will occupy

## Pause SigLens from starting up.
#pauseMode: true
EOF

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

export installPath="${installPath}"
cd \${installPath}

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

./${binary} -config \${installPath}/server.yaml &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=https://github.com/siglens/siglens
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
