#!/usr/bin/env bash

#
# xiechengqi
# 2021/07/16
# install pyenv
#

source /etc/profile

INFO() {
printf -- "\033[44;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "%s" "$1"
printf "\n"
}

YELLOW() {
printf -- "\033[44;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "\033[33m%s\033[0m" "$1"
printf "\n"
}

ERROR() {
printf -- "\033[41;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "%s" "$1"
printf "\n"
exit 1
}

EXEC() {
local cmd="$1"
INFO "${cmd}"
eval ${cmd} 1> /dev/null
if [ $? -ne 0 ]; then
ERROR "Execution command (${cmd}) failed, please check it and try again."
fi
}

function main() {
# check pyenv
pyenv -v &> /dev/null && INFO "pyenv has been installed ..." && return 0

# install
EXEC "curl https://pyenv.run | bash"

# register bin
EXEC "ln -fs $HOME/.pyenv/bin/* /usr/local/bin/"

source /etc/profile
EXEC "pyenv -v" && pyenv -v
}

main
