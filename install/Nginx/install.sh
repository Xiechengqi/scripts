#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/13
# https://github.com/nginx/nginx
# Ubuntu 18.04
# install Nginx
#

source /etc/profile

OS() {
osType=$1
osVersion=$2
curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/master/tool/os.sh | bash -s ${osType} ${osVersion} || exit 1
}

INFO() {
printf -- "\033[44;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "%s" "$1"
printf "\n"
}

YELLOW() {
printf -- "\033[44;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "\033[33m%s\033[0m" "$1"
printf "\n"
}

ERROR() {
printf -- "\033[41;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "%s" "$1"
printf "\n"
exit 1
}

EXEC() {
local cmd="$1"
INFO "${cmd}"
eval ${cmd} 1> /dev/null
if [ $? -ne 0 ]; then
ERROR "Execution command (${cmd}) failed, please check it and try again."
fi
}

main() {

# check os
OS "ubuntu" "18"

# environments
serviceName="nginx"
version=${1-"1.17.7"}
installPath="/data/${serviceName}-${version}"
downloadUrl="https://nginx.org/download/nginx-${version}.tar.gz"

# check service
systemctl is-active $serviceName &> /dev/null && YELLOW "$serviceName is running ..." && return 0 

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/src"

# download tarball
EXEC "curl -sSL $downloadUrl | tar zx --strip-components 1 -C $installPath/src"

# install requirements，gcc/g++/make/c++ lib/ssl lib/pcre/zlib
EXEC "apt update"
EXEC "export DEBIAN_FRONTEND=noninteractive"
EXEC "apt install -y build-essential libtool libpcre3 libpcre3-dev zlib1g-dev libssl-dev"

# make and install
## --prefix	定义保存nginx的目录
## --with-pcre	强制使用PCRE库
## --with-http_ssl_module	支持构建将SSL/TLS协议支持添加到流模块的模块
## --with-http_v2_module	支持构建支持HTTP2的模块.这个模块默认是不构建的
## --with-http_gunzip_module	支持为不支持gzip编码方法的客户端构建ngx_http_gunzip_module模块，该模块使用 Content-Encoding：gzip解压缩响应。 默认情况下未构建此模块
## --with-http_gzip_static_module	支持构建ngx_http_gzip_static_module模块，该模块支持发送扩展名为.gz的预压缩文件，而不是常规文件。 默认情况下未构建此模块
EXEC "cd $installPath/src"
EXEC "./configure --prefix=$installPath --with-pcre --with-http_ssl_module --with-http_v2_module --with-http_gunzip_module --with-http_gzip_static_module --pid-path=$installPath/nginx.pid"
EXEC "make"
EXEC "make install"

# register bin
EXEC "ln -fs $installPath/sbin/* /usr/local/bin"

# register service
cat > $installPath/${serviceName}.service << EOF
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=$installPath/nginx.pid
# Nginx will fail to start if /run/nginx.pid already exists but has the wrong
# SELinux context. This might happen when running `nginx -t` from the cmdline.
# https://bugzilla.redhat.com/show_bug.cgi?id=1268621
ExecStartPre=/bin/rm -f $installPath/nginx.pid
ExecStartPre=/usr/local/bin/nginx -t
ExecStart=/usr/local/bin/nginx -c $installPath/conf/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=process
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
EXEC "rm -f /lib/systemd/system/${serviceName}.service"
EXEC "ln -fs $installPath/${serviceName}.service /lib/systemd/system/${serviceName}.service"

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "systemctl daemon-reload && systemctl enable $serviceName && systemctl start $serviceName"
EXEC "systemctl status $serviceName --no-pager" && systemctl status $serviceName --no-pager

# info
YELLOW "${serviceName} version: $version"
YELLOW "install path: $installPath"
YELLOW "config path: $installPath/conf"
YELLOW "log path: $installPath/logs"
YELLOW "managemanet cmd: systemctl [stop|start|restart|reload] $serviceName"
}

main $@
