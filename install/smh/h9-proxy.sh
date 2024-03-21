#!/usr/bin/env bash

#
# 2024/03/21
# xiechengqi
# install H9 SMH Proxy
# cmd: curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/smh/h9-proxy.sh | bash
#

source /etc/profile
# BASEURL="https://raw.githubusercontent.com/Xiechengqi/scripts/master"
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# environment
serviceName="smh-proxy-h9"
version=${1-"3.0.3-1"}
installPath="/data/${serviceName}-${version}"
[ ".${DOWNLOAD}" = "." ] && ERROR "Empty env DOWNLOAD ..."
binaryName="smh-proxy"
downloadUrl="${DOWNLOAD}/smh/h9/${version}/${binaryName}"
port="9190"
apiKey="smh00000-adca-6e4e-e609-0c43a53780df"

# check
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} has been installed ..." && return 0

# check install path
EXEC "rm -rf ${installPath} $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p ${installPath}/{bin,conf,logs}"

# download
EXEC "curl -SsL ${downloadUrl} -o ${installPath}/bin/${binaryName}"
EXEC "chmod +x ${installPath}/bin/${binaryName}"

# register bin
EXEC "ln -fs ${installPath}/bin/${binaryName} /usr/bin/${binaryName}"
EXEC "${binaryName} -h" && ${binaryName} -h

# conf
cat > ${installPath}/conf/config.yaml << EOF
server:
    host: 0.0.0.0
    port: ${port}
dbFile: "proxy.db"
chains:
    -
        chain: spacemesh
        apiKey: "${apiKey}"
EOF

# creat start.sh
cat > ${installPath}/start.sh << EOF
#!/usr/bin/env /bash

source /etc/profile

installPath="${installPath}"

mkdir -p \${installPath}/logs
timestamp=\$(date +%Y%m%d%H%M%S)
touch \${installPath}/logs/\${timestamp}.log && ln -fs \${installPath}/logs/\${timestamp}.log \${installPath}/logs/latest.log
\${installPath}/bin/${binaryName} -config \${installPath}/conf/config.yaml &> \${installPath}/logs/latest.log
EOF
EXEC "chmod +x ${installPath}/start.sh"

# register service
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
cat > ${installPath}/${serviceName}.service << EOF
[Unit]
Description=SMH Hpool Proxy
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
EXEC "ln -fs ${installPath}/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# change softlink
EXEC "ln -fs ${installPath} $(dirname ${installPath})/${serviceName}"

# start
EXEC "systemctl daemon-reload && systemctl enable ${serviceName} && systemctl start ${serviceName}"
EXEC "systemctl status ${serviceName} --no-pager" && systemctl status ${serviceName} --no-pager

# info
YELLOW "${serviceName} version: $version"
YELLOW "install: ${installPath}"
YELLOW "port: ${port}"
YELLOW "log: tail -f ${installPath}/logs/latest.log"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] ${serviceName}"

}

main $@
