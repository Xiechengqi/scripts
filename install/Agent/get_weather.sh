#!/usr/bin/env bash

main() {

export CITY=$(echo ${1} | awk -F '=' '{print $NF}')

cat << EOF

===== ${CITY} 天气 =====
$(curl -SsL https://wttr.in/${CITY}?T)

EOF

}

main $@
