#!/usr/bin/env bash

#
# xiechengqi
# 2022/09/22
# install mongodb exporter
#

# source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
# ! echo "$osInfo" | grep -E 'centos7|ubuntu18|ubuntu20|ubuntu22' &> /dev/null && ERROR "You could only install on os: centos7、ubuntu18、ubuntu20"

# environments
serviceName="mongodb-exporter"
version="0.34.0"
installPath="/data/${serviceName}-${version}"
downloadUrl="https://github.com/percona/mongodb_exporter/releases/download/v${version}/mongodb_exporter-${version}.linux-amd64.tar.gz"
port=${1-"9216"}
mongodb_uri=${2-"127.0.0.1:27017"}

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName has been installed ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/logs"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath"
EXEC "chown -R root.root $installPath"

# register bin
EXEC "ln -fs $installPath/mongodb_exporter /usr/bin/mongodb_exporter"
EXEC "mongodb_exporter --version" && mongodb_exporter --version

# creat start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
timestamp=\$(date +%Y%m%d-%H%M%S)
installPath="${installPath}"
touch \$installPath/logs/\${timestamp}.log && ln -fs \$installPath/logs/\${timestamp}.log \$installPath/logs/latest.log
mongodb_exporter --web.listen-address=":$port" --mongodb.uri=mongodb://$mongodb_uri &> \$installPath/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=node-exporter
Documentation=https://github.com/percona/mongodb_exporter
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
YELLOW "monitor MongoDB: $mongodb_uri"
YELLOW "log: tail -f $installPath/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
