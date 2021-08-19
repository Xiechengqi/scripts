#!/usr/bin/env bash

#
# xiechengqi
# 2021/08/19
# install polkadot-index
#

source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu18|ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu18、ubuntu20"

# get chainId
# chainId="$1" && INFO "chain: $chainId"                                                                                                
# ! echo "$chainId" | grep -E 'mainnet|testnet' &> /dev/null && ERROR "You could only choose chain: mainnet、testnet"

# environments
serviceName="polkadot-index"
version="master"
installPath="/data/Polkadot/${serviceName}-${version}"
downloadUrl="https://github.com/HashKeyHub/polkadot-indexer.git"
# fullnode host ip
nodeHost=`hostname -I | awk '{print $1}'`
# fullnode wx rpc port
wsPort="9944"

# install script url
dockerUrl="$BASEURL/install/Docker/install.sh"
dockerComposeUrl="$BASEURL/install/docker-compose/install.sh"

# check service
docker ps | grep polkadot-index &> /dev/null && ERROR "${serviceName} is running ..." 

# check install path
EXEC "rm -rf $installPath $(dirname $installPath)/${serviceName}"

# download
INFO "git clone -b $version $downloadUrl $installPath" && git clone -b $version $downloadUrl $installPath

# install docker and docker-compose
curl -SsL $dockerUrl | bash
curl -SsL $dockerComposeUrl | bash

# create docker-compose-full.yml - https://wiki.i.wxblockchain.com/pages/viewpage.action?pageId=21695559 - https://wiki.xiechengqi.top/pages/viewpage.action?pageId=1573371
cat > $installPath/docker-compose-full.yml << EOF
version: "2.4"

services:
  redis:
    image: redis:3.2.11
    hostname: redis
    restart: always

  mysql:
    image: mysql:latest
    hostname: mysql
    volumes:
      - ./database:/var/lib/mysql:rw
    ports:
      - '33061:3306'
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_DATABASE=subscan
    restart: always
  subscan-api: &app_base
    image: scan/backend
    init: true
    build: .
    environment:
      MYSQL_HOST: mysql
      MYSQL_PASS: 'root'
      MYSQL_DB: 'subscan'
      REDIS_ADDR: redis:6379
      CHAIN_WS_ENDPOINT: 'ws://$nodeHost:$wsPort'
      NETWORK_NODE: 'polkadot'
      WEB_HOST: 'http://subscan-api:4399'
    ports:
      - 4399:4399
    command: ["/subscan/cmd/subscan","--conf","../configs"]
    depends_on:
      - redis
      - mysql
    restart: always
  subscan-daemon:
    <<: *app_base
    image: scan/backend
    ports: []
    command: ["python","run.py","substrate"]
    depends_on:
      - redis
      - mysql
    restart: always
EOF

# build
EXEC "cd $installPath"
EXEC "docker-compose build"

# change softlink
EXEC "ln -fs $installPath $(dirname $installPath)/$serviceName"

# start
EXEC "docker-compose -f docker-compose-full.yml up -d mysql"
EXEC "sleep 3"
EXEC "docker-compose -f docker-compose-full.yml up -d"
INFO "docker-compose -f docker-compose-full.yml ps" && docker-compose -f docker-compose-full.yml ps

# info
YELLOW "${serviceName} version: $version"
YELLOW "chain: ${chainId}"
YELLOW "install: $installPath"
YELLOW "managemanet cmd: cd $installPath && docker-compose [stop|start|restart|ps]"
}

main $@
