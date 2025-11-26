#!/usr/bin/env bash

#
# xiechengqi
# OS: ubuntu
# 2025/11/26
# binary install golang (adapt to China)
# usage: curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/refs/heads/master/install/Golang/install.sh | sudo bash
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20|ubuntu22|centos7|centos8' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20、ubuntu22、centos7、centos8"

# environments
serviceName="golang"
version=${1-"1.24.9"}
installPath="/data/${serviceName}-${version}"
downloadUrl="https://mirrors.ustc.edu.cn/golang/go${version}.linux-amd64.tar.gz"
# downloadUrl="https://golang.org/dl/go${version}.linux-amd64.tar.gz"

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
