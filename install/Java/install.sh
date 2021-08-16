#!/usr/bin/env bash

#
# 2021/08/15
# xiechengqi
# install openJdk
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

# ubuntu 18+
_ubuntu() {
apt install openjdk-${version}-jdk
}

# centos 7+
_centos() {
yum install epel-release java-${version}-openjdk-devel
}

main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20|centos7|centos8' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20、centos7、centos8"

# environments
version=${1-"11"}
[ "$version" != "11" ] && [ "$version" != "8" ] && ERROR "You could only choose openJdk 8 or 11"

# check java
java -version &> /dev/null && YELLOW "Java has been installed ..." && return 0

echo $osInfo | grep ubuntu &> /dev/null && _ubuntu
echo $osInfo | grep centos &> /dev/null && _centos

# info
INFO "java -version" && java -version
}

main $@
