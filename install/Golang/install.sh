#!/usr/bin/env bash

#
# xiechengqi
# OS: ubuntu
# 2021/08/14
# binary install golang (adapt to China)
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# environments
serviceName="golang"
version=${1-"1.16.6"}
installPath="/data/${serviceName}-${version}"
countryCode=`curl -SsL https://api.ip.sb/geoip | sed 's/,/\n/g' | grep country_code | awk -F '"' '{print $(NF-1)}'`
[ "$countryCode" = "CN" ] && downloadUrl="https://mirrors.ustc.edu.cn/golang/go${version}.linux-amd64.tar.gz" || downloadUrl="https://golang.org/dl/go${version}.linux-amd64.tar.gz"

# check service
go version &> /dev/null && YELLOW "$serviceName has been installed ..." && return 0

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath/{data,path}"

# download tarball
EXEC "curl -SsL $downloadUrl | tar zx --strip-components 1 -C $installPath/data"

# register path
EXEC "sed -i '/golang\/bin/d' /etc/profile"
EXEC "echo 'export GOPATH=$installPath/path' >> /etc/profile"
EXEC "echo 'export GOBIN=\$GOPATH/bin' >> /etc/profile"
EXEC "echo 'export PATH=\$PATH:$installPath/data/bin:\$GOBIN' >> /etc/profile"
EXEC "ln -fs $installPath/data/bin/* /usr/local/bin/"
EXEC "source /etc/profile"
EXEC "go version"

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/${serviceName}"

# info
YELLOW "version: ${version}"
}

main $@
