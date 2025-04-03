#!/usr/bin/env bash

trap "_clean" EXIT

_clean() {

cd /tmp/ && rm -f $$_*

}

main() {

curl -SsL 'https://orchestrator.strn.pl/nodes/local' > /tmp/$$_local 2>/dev/null
ip=$(curl -4 -SsL ip.sb)
cat /tmp/$$_local | grep "\"${ip}\"" &> /dev/null && echo "${ip} ... online" || echo "${ip} ... offline"

}

main $@
