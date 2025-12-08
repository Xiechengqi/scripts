#!/usr/bin/env bash

#
# 2025/04/16
# xiechengqi
# install kibana
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/Kibana/install.sh | sudo bash
# config: https://www.elastic.co/docs/deploy-manage/deploy/self-managed/configure-kibana
# prd config: https://www.elastic.co/guide/en/kibana/8.18/production.html#openssl-legacy-provider
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
serviceName="kibana"
version="8.18.0"
installPath="/data/${serviceName}"
downloadUrl="https://artifacts.elastic.co/downloads/kibana/kibana-${version}-linux-x86_64.tar.gz"
binary="kibana"
elasticsearchHost="http://localhost:9200"
serverHost="0.0.0.0"
serverPort="5601"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{logs,data}"

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx --strip-components 1 -C ${installPath}/"
EXEC "chmod +x ${installPath}/bin/${binary}"

# register bin
EXEC "ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"

# create conf
sed -i "s!^#path.data: .*!path.data: ${installPath}/data!" ${installPath}/config/kibana.yml
sed -i "s/^#i18n.locale: .*/i18n.locale: zh-CN/" ${installPath}/config/kibana.yml
sed -i "s/^#elasticsearch.hosts: .*/elasticsearch.hosts: [\"${elasticsearchHost}\"]/" ${installPath}/config/kibana.yml
sed -i "s/^#server.host: .*/server.host: ${serverHost}/" ${installPath}/config/kibana.yml
sed -i "s/^#server.port: .*/server.port: ${serverPort}/" ${installPath}/config/kibana.yml
cat >> ${installPath}/config/kibana.yml << EOF
logging.root.level: info
logging.appenders.default:
  type: rolling-file
  fileName: ${installPath}/logs/kibana.log
  policy:
    type: size-limit
    size: 256mb
  strategy:
    type: numeric
    max: 10
  layout:
    type: json
EOF

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

ulimit -n 65535
ulimit -u 4096
swapoff -a

export installPath="${installPath}"
cd \${installPath}

export KIBANA_HOME="${installPath}"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/${binary} --allow-root &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=https://github.com/elastic/kibana
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
YELLOW "port: ${serverPort}"
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
