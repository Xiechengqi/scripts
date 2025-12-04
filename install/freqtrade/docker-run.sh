#!/usr/bin/env bash

BASEPATH=`dirname $(readlink -f ${BASH_SOURCE[0]})` && cd $BASEPATH

source ./env
# export NAME="freqtrade-01"
# export PORT="8080"
# export STRATEGY="SampleStrategy"

set -x

! ls user_data &> /dev/null && docker run -v ${PWD}/user_data:/freqtrade/user_data --rm freqtradeorg/freqtrade:stable create-userdir --userdir user_data && docker run -it -v ${PWD}/user_data:/freqtrade/user_data --rm freqtradeorg/freqtrade:stable new-config --config user_data/config.json

sed -i 's/listen_ip_address.*/listen_ip_address": "0.0.0.0",/;s/username.*/username": "freqtrader",/;s/password.*/password": "freqtrader"/;/api_server/,+3s/"enabled": false/"enabled": true/' user_data/config.json

docker rm -f ${NAME}
docker run -itd \
--restart always \
--privileged=true \
-p ${PORT}:8080 \
-v ${PWD}/user_data:/freqtrade/user_data \
--name ${NAME} freqtradeorg/freqtrade:stable \
trade --logfile /freqtrade/user_data/logs/freqtrade.log --db-url sqlite:////freqtrade/user_data/tradesv3.sqlite --config /freqtrade/user_data/config.json --strategy ${STRATEGY}

ufw allow ${PORT}
