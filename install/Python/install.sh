#!/usr/bin/env bash

#
# xiechengqi
# 2021/07/23
# pyenv install python
# usage: curl -SsL http://xxx/install.sh | bash -s 3.6
#

source /etc/profile
source <(curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/tool/common.sh)

main() {
# environments
version="${1}-dev"
pythonCmd="python${1}"
pipCmd="pip"`echo ${1} | awk -F '.' '{print $1}'`
installPyenvScriptUrl="https://raw.githubusercontent.com/Xiechengqi/scripts/master/install/Pyenv/install.sh"

# check
$pythonCmd --version &> /dev/null && YELLOW "$pythonCmd has been install ..." && return 0

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

# info
YELLOW "$pythonCmd --version" && $pythonCmd --version
YELLOW "$pipCmd --version" && $pipCmd --version
}

main $@
