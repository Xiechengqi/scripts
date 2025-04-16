#!/usr/bin/env bash

#
# 2025/04/16
# xiechengqi
# install elasticsearch
# usage: curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/ElasticSearch/install.sh | sudo bash
# config: https://www.elastic.co/docs/deploy-manage/deploy/self-managed/important-settings-configuration
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

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu20|ubuntu22' &> /dev/null && ERROR "You could only install on os: ubuntu20、ubuntu22"

# environment
serviceName="elasticsearch"
version="8.18.0"
installPath="/data/${serviceName}"
downloadUrl="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${version}-linux-x86_64.tar.gz"
binary="elasticsearch"
clusterName="es-cluster"
nodeName="es-node-1"
httpPort="9200"
elasticPassword=""

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

# create user
user="elasticsearch"
INFO "useradd ${user}" && useradd ${user}

# pre env
# 调大进程可以拥有的内存映射区域的最大数量为 262144，默认 65535
# https://www.elastic.co/guide/en/elasticsearch/reference/8.18/bootstrap-checks-max-map-count.html
sed -i "/vm.max_map_count/d" /etc/sysctl.conf
EXEC "echo 'vm.max_map_count=262144' >> /etc/sysctl.conf"
EXEC "sysctl -p"
# 赋予Elasticsearch的用户锁定内存权限
# https://www.elastic.co/guide/en/elasticsearch/reference/8.18/setup-configuration-memory.html#bootstrap-memory_lock
sed -i "/elasticsearch/d" /etc/security/limits.conf
cat >> /etc/security/limits.conf << EOF
elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited
EOF

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p ${installPath}/{logs,data}"

# download tarball
EXEC "curl -SsL ${downloadUrl} | tar zx --strip-components 1 -C ${installPath}/"
EXEC "chmod +x ${installPath}/bin/${binary}"
EXEC "chown -R ${user}:${user} ${installPath}"

# register bin
EXEC "ln -fs ${installPath}/bin/${binary} /usr/local/bin/${binary}"
INFO "${binary} -version" && ${binary} -version

# create conf
sed -i "s!^#path.data: .*!path.data: ${installPath}/data!" ${installPath}/config/elasticsearch.yml
sed -i "s!^#path.logs: .*!path.logs: ${installPath}/logs!" ${installPath}/config/elasticsearch.yml
sed -i "s/^#cluster.name: .*/cluster.name: ${clusterName}/" ${installPath}/config/elasticsearch.yml
sed -i "s/^#node.name: .*/node.name: ${nodeName}/" ${installPath}/config/elasticsearch.yml
sed -i "s/^#network.host: .*/network.host: 0.0.0.0/" ${installPath}/config/elasticsearch.yml
sed -i "s/^#http.port: .*/http.port: ${httpPort}/" ${installPath}/config/elasticsearch.yml
sed -i "s/^#bootstrap.memory_lock: .*/bootstrap.memory_lock: true/" ${installPath}/config/elasticsearch.yml
sed -i "s/^#discovery.seed_hosts: .*/discovery.seed_hosts: []/" ${installPath}/config/elasticsearch.yml
cat >> ${installPath}/config/elasticsearch.yml << EOF
transport.host: 0.0.0.0
xpack.security.enabled: false
discovery.type: single-node
EOF

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash

ulimit -n 65535
ulimit -u 4096
swapoff -a

export installPath="${installPath}"
cd \${installPath}

export ES_HOME="${installPath}"
[ ".${elasticPassword}" != "." ] && export ELASTIC_PASSWORD="${elasticPassword}"

timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/${binary} &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=${serviceName}
Documentation=https://github.com/elastic/elasticsearch
After=network.target

[Service]
User=${user}
Group=${user}
LimitMEMLOCK=infinity
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
YELLOW "port: ${httpPort}"
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
