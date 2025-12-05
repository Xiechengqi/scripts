#!/usr/bin/env bash

#
# xiechengqi
# 2022/11/25
# install ooklaserver
#

source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# environments
serviceName="ooklaserver"
installPath="/data/${serviceName}"
downloadUrl="https://github.com/Xiechengqi/scripts/raw/master/install/ooklaserver/OoklaServer-linux64.tgz"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName has been installed ..." && return 0

# check install path
EXEC "rm -rf ${installPath}"
EXEC "mkdir -p $installPath/{src,bin,logs}"

# download tarball
EXEC "cd ${installPath}/src"
EXEC "curl -sSL ${downloadUrl} -o ${installPath}/OoklaServer-linux64.tgz"
EXEC "cd ${installPath}"
EXEC "tar xvf OoklaServer-linux64.tgz"

# register bin
EXEC "ln -fs ${installPath}/OoklaServer /usr/local/bin/OoklaServer"

# install limit process io tool - trickle
EXEC "apt update"
INFO "apt install trickle -y"
apt install trickle -y

# install speedtest
INFO "curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash"
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
INFO "apt install speedtest -y"
apt install speedtest -y

# create start.sh
cat > $installPath/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

timestamp=\$(date +%Y%m%d-%H%M%S)
touch $installPath/logs/\${timestamp}.log && ln -fs $installPath/logs/\${timestamp}.log $installPath/logs/latest.log

cd ${installPath}
trickle -u 8000000 -d 80000000 OoklaServer &> $installPath/logs/latest.log
EOF
EXEC "chmod +x $installPath/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > /lib/systemd/system/${serviceName}.service << EOF
[Unit]
Description=OoklaServer
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

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "install path: $installPath"
YELLOW "tail log cmd: tail -f $installPath/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
