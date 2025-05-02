#!/usr/bin/env bash

#
# sn42 common functions
# usage: source <(curl -SsL https://raw.githubusercontent.com/Xiechengqi/scripts/refs/heads/master/tool/sn42.sh)
#

# usage: prom_guage [metric name]
function prom_guage() {
cat << EOF
# HELP ${1} get $(echo ${1} | tr '_' ' ')
# TYPE ${1} gauge
EOF
}

# usage: sn42_tweets_number_metric [axon]
function sn42_tweets_number_metric() {
axon=${1}
local teeUrl=$(curl -SsL http://${axon}/tee 2> /dev/null | sed 's/"//g')
[ ".${teeUrl}" = "." ] && return 1
local sig=$(curl -SsL -k ${teeUrl}/job/generate -H "Content-Type: application/json" -d '{ "type": "telemetry"}' 2> /dev/null)
local uuid=$(curl -SsL -k ${teeUrl}/job/add -H "Content-Type: application/json" -d '{ "encrypted_job": "'${sig}'" }' 2> /dev/null | jq -r .uid)
local result=$(curl -SsL -k ${teeUrl}/job/status/${uuid} 2> /dev/null)
local de=$(curl -SsL -k ${teeUrl}/job/result -H "Content-Type: application/json" -d '{ "encrypted_result": "'${result}'", "encrypted_request": "'${sig}'" }' 2> /dev/null)
local tweets=$(echo ${de} | jq '.stats.twitter_returned_tweets')
[ ".${tweets}" = "." ] && return 1
echo "sn42_tweets_number{axon=\"${axon}\", tee=\"${teeUrl}\"} ${tweets}"
}

# usage: sn42_tweets_per_minute_metric [axon]
function sn42_tweets_per_minute_metric() {
axon=${1}
local teeUrl=$(curl -SsL http://${axon}/tee 2> /dev/null | sed 's/"//g')
[ ".${teeUrl}" = "." ] && return 1
local tweetsA=$(sn42_tweets_number_metric ${axon} | awk '{print $NF}')
[ ".${tweetsA}" = "." ] && return 1
sleep 10s
local tweetsB=$(sn42_tweets_number_metric ${axon} | awk '{print $NF}')
[ ".${tweetsB}" = "." ] && return 1
local tweetsPerMinute=$(echo "$(echo "${tweetsB} - ${tweetsA}" | bc) * 6" | bc)
echo "sn42_tweets_per_minute{axon=\"${axon}\", tee=\"${teeUrl}\"} ${tweetsPerMinute}"
}
