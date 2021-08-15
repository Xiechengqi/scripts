#!/usr/bin/env bash

#
# 2021/08/15
# xiechengqi
# install openJdk
#

source /etc/profile

source <(curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/tool/common.sh)

# ubuntu 18+
_ubuntu() {
apt install openjdk-${version}-jdk
}

# centos 7+
_centos() {
yum install epel-release java-${version}-openjdk-devel
}

main() {

os=`get_os`

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
