#!/usr/bin/env bash

#
# xiechengqi
# 2023/08/08
# install gost
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL ${BASEURL}/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: ${osInfo}"
! echo "${osInfo}" | grep -E 'centos7|ubuntu18|ubuntu20|ubuntu22' &> /dev/null && ERROR "You could only install on os: centos7、ubuntu18、ubuntu20、ubuntu22"

# environments
serviceName="gost"
version=${1-"3.0.0-rc8"}
installPath="/data/${serviceName}-${version}"
downloadUrl="https://github.com/go-gost/gost/releases/download/v${version}/gost_${version}_linux_amd64.tar.gz"
configUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Gost/gnfd-testenet-sp-config.yaml"

# check service
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} has been installed ..." && return 0

# check install path
EXEC "rm -rf ${installPath} $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p ${installPath}/{bin,conf,logs}"

# download
EXEC "rm -rf /tmp/${serviceName} && mkdir /tmp/${serviceName}"
EXEC "curl -sSL ${downloadUrl} | tar zx -C /tmp/${serviceName}"
EXEC "mv /tmp/${serviceName}/gost ${installPath}/bin/ && chmod +x ${installPath}/bin/gost"

# register bin
EXEC "ln -fs ${installPath}/bin/gost /usr/local/bin/gost"

# create config.yaml
EXEC "curl -SsL ${configUrl} -o ${installPath}/conf/config.yaml"
INFO "cat ${installPath}/conf/config.yaml" && cat ${installPath}/conf/config.yaml

# update config
cat > ${installPath}/cron-update-config.sh << EOF
#!/usr/bin/env bash

curl -SsL ${configUrl} -o /tmp/config.yaml
if [ "\$(md5sum ${installPath}/conf/config.yaml /tmp/config.yaml | awk '{print \$1}' | uniq | wc -l)" = "2" ]
then
cp -f /tmp/config.yaml ${installPath}/conf/config.yaml
systemctl restart gost
else
return 0
fi
EOF
EXEC "chmod +x ${installPath}/cron-update-config.sh"
INFO "cat ${installPath}/cron-update-config.sh" && cat ${installPath}/cron-update-config.sh

# add cronjob
echo '*/5 * * * * /usr/bin/bash '"${installPath}"'/cron-update-config.sh' | crontab
INFO "crontab -l" && crontab -l

# open cron log
grep '#cron' /etc/rsyslog.d/50-default.conf && sed -i 's/#cron/cron/' /etc/rsyslog.d/50-default.conf && EXEC "systemctl restart rsyslog"

# create start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env bash
source /etc/profile

installPath=${installPath}
timestamp=\$(date +%Y%m%d-%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log

\${installPath}/bin/gost -C \${installPath}/conf/config.yaml &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=Gost
Documentation=https://github.com/go-gost/gost
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
EXEC "rm -f /etc/systemd/system/${serviceName}.service"
EXEC "ln -fs ${installPath}/${serviceName}.service /etc/systemd/system/${serviceName}.service"

# change softlink
EXEC "ln -fs ${installPath} $(dirname ${installPath})/${serviceName}"

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName} && systemctl start ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# info
YELLOW "${serviceName} version: ${version}"
YELLOW "install path: ${installPath}"
YELLOW "config path: ${installPath}/conf"
YELLOW "tail log cmd: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"
}

main $@
