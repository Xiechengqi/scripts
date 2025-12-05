#!/usr/bin/env bash

#
# xiechengqi
# 2021/10/13
# install gradle
#

source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'centos7|ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: centos7、ubuntu18、ubuntu20"

countryCode=`curl -SsL https://api.ip.sb/geoip | sed 's/,/\n/g' | grep country_code | awk -F '"' '{print $(NF-1)}'`

# environment
serviceName="gradle"
version=${1-"6.0"}
installPath="/data/${serviceName}-${version}"
downloadUrl="https://services.gradle.org/distributions/gradle-${version}-bin.zip"

# check java
java -version &> /dev/null || ERROR "Please install java first"

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"
EXEC "mkdir -p $installPath"

# install unzip
if [[ "$osInfo" =~ "ubuntu" ]]
then
EXEC "apt update && apt install -y unzip"
else
EXEC "yum install -y unzip"
fi

# download
EXEC "rm -rf /tmp/${serviceName} && mkdir /tmp/${serviceName}"
EXEC "curl -SsL ${downloadUrl} -o /tmp/${serviceName}/${serviceName}.zip"
EXEC "unzip /tmp/${serviceName}/${serviceName}.zip -d ${installPath}"
EXEC "mv ${installPath}/gradle-*/* ${installPath} && rm -rf ${installPath}/gradle-*"

# register
EXEC "ln -fs $installPath/bin/* /usr/local/bin"
EXEC "gradle -v" && gradle -v

# info
YELLOW "${serviceName} version: $version"
YELLOW "install path: $installPath"
}

main $@
