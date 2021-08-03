#!/usr/bin/env bash

# 
# xiechengqi
# 2021/08/02
# 操作系统信息
# Usage: curl -SsL https://xxx.os.sh | bash -s Ubuntu 16.04
#

_os() {
local os=""
[ -f "/etc/debian_version" ] && source /etc/os-release && os="${ID}" && printf -- "%s" "${os}" && return
[ -f "/etc/fedora-release" ] && os="fedora" && printf -- "%s" "${os}" && return
[ -f "/etc/redhat-release" ] && os="centos" && printf -- "%s" "${os}" && return
}

_os_full() {
[ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
[ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
[ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

_os_ver() {
local main_ver="$( echo $(_os_full) | grep -oE  "[0-9.]+")"
printf -- "%s" "${main_ver%%.*}"
}

function main() {
_os
_os_full
_os_ver
}

main
