#!/usr/bin/env bash

#
# 2021/10/29
# xiechengqi
# install node-exporter
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

countryCode=`curl -SsL https://api.ip.sb/geoip | sed 's/,/\n/g' | grep country_code | awk -F '"' '{print $(NF-1)}'`

# environment
serviceName="node-exporter"
version="1.2.2"
installPath="/data/${serviceName}-${version}"
# [ "${countryCode}" = "CN" ] && downloadUrl="https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/v${version}/node-v${version}-linux-x64.tar.gz" || downloadUrl="https://nodejs.org/download/release/v${version}/node-v${version}-linux-x64.tar.gz"
downloadUrl="https://github.com/prometheus/node_exporter/releases/download/v${version}/node_exporter-${version}.linux-amd64.tar.gz"
port=${1-"9009"}

# check node
node-exporter --version &> /dev/null && YELLOW "${serviceName} has been installed ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath"
EXEC "chown -R root.root $installPath"

# register bin
EXEC "ln -fs /usr/bin/node-exporter $installPath/node-exporter"
EXEC "node-exporter --version" && node-exporter --version

# creat start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

timestamp=\$(date +%Y%m%d-%H%M%S)
touch $installPath/logs/\${timestamp}.log && ln -fs $installPath/logs/\${timestamp}.log $installPath/logs/latest.log

node_exporter --web.listen-address=":$port" &> $installPath/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=node-exporter
Documentation=https://github.com/prometheus/node_exporter
After=network.target

[Service]
User=root
Group=root
ExecStart=/bin/bash $installPath/start.sh
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "${serviceName} version: $version"
YELLOW "install: $installPath"
YELLOW "port: $port"
YELLOW "log: tail -f $installPath/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
