#!/usr/bin/env bash

BASEPATH=`dirname $(readlink -f ${BASH_SOURCE[0]})` && cd $BASEPATH

name="github-proxy"
docker rm -f ${name}
docker run -itd \
--restart always \
-p 7210:8080 \
-v ./ghproxy/log/run:/data/ghproxy/log \
-v ./ghproxy/log/caddy:/data/caddy/log \
-v ./ghproxy/config:/data/ghproxy/config \
--name ${name} wjqserver/ghproxy
