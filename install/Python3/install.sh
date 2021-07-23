#!/usr/bin/env bash

#
# xiechengqi
# 2021/07/16
# pyenv install python3.6
# usage: curl -SsL http://xxx/install.sh | bash -s 3.6
#

source /etc/profile

INFO() {
printf -- "\033[44;37m%s\033[0m " "[$(date "+%Y-%m-%d %H:%M:%S")]"
printf -- "%s" "$1"
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
# environments
version="${1}-dev"
pythonCmd="python${1}"
pipCmd="pip"`echo ${1} | awk -F '.' '{print $1}'`
installPyenvScriptUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Pyenv/install.sh"

# check
$pythonCmd --version &> /dev/null && INFO "$pythonCmd has been install ..." && return 0

# check pyenv
if pyenv -v &> /dev/null
then
EXEC "pyenv -v" && pyenv -v
else
curl -SsL $installPyenvScriptUrl | bash || exit 1
fi

# install gcc/make/zlib
EXEC "apt update && apt install -y build-essential zlib1g-dev libffi-dev libssl-dev libbz2-dev libreadline-dev libsqlite3-dev liblzma-dev"

# install
EXEC "pyenv install $version"

# link
EXEC "ln -fs /root/.pyenv/versions/$version/bin/$pythonCmd /usr/local/bin/$pythonCmd"
EXEC "ln -fs /root/.pyenv/versions/$version/bin/$pipCmd /usr/local/bin/$pipCmd"
EXEC "ln -fs /usr/local/bin/$pipCmd /usr/bin/$pipCmd"
EXEC "$pythonCmd --version" && $pythonCmd --version
EXEC "$pipCmd --version" && $pipCmd --version
}

main $@
