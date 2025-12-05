#!/usr/bin/env bash

#
# 2021/10/13
# xiechengqi
# install openJdk
#

source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'centos7|centos8|ubuntu16|ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: centos7、centos8、ubuntu16、ubuntu18、ubuntu20"

# check java
java -version &> /dev/null && YELLOW "Java has been installed ..." && return 0

# install
if [[ "$osInfo" =~ "ubuntu" ]]
then
  EXEC "wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | sudo apt-key add -"
  if [[ "$osInfo" =~ "ubuntu16" ]]
  then
    EXEC "echo 'deb https://mirrors.tuna.tsinghua.edu.cn/AdoptOpenJDK/deb xenial main' > /etc/apt/sources.list.d/AdoptOpenJDK.list"
  elif [[ "$osInfo" =~ "ubuntu18" ]]
  then
    EXEC "echo 'deb https://mirrors.tuna.tsinghua.edu.cn/AdoptOpenJDK/deb bionic main' > /etc/apt/sources.list.d/AdoptOpenJDK.list"
  elif [[ "$osInfo" =~ "ubuntu20" ]]
  then
    EXEC "echo 'deb https://mirrors.tuna.tsinghua.edu.cn/AdoptOpenJDK/deb focal main' > /etc/apt/sources.list.d/AdoptOpenJDK.list"
  fi
  EXEC "apt-get update"
  EXEC "apt-get install -y java"
elif [[ "$osInfo" =~ "centos" ]]
then
cat > /etc/yum.repos.d/AdoptOpenJDK.repo < EOF
[AdoptOpenJDK]
name=AdoptOpenJDK
baseurl=https://mirrors.tuna.tsinghua.edu.cn/AdoptOpenJDK/rpm/centos$releasever-$basearch/
enabled=1
gpgcheck=1
gpgkey=https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public
EOF
EXEC "yum makecache"
EXEC "yum install -y java"
fi

# info
INFO "java -version" && java -version
}

main $@
