#!/usr/bin/env bash

#
# xiechengqi
# 2021/07/16
# install pyenv
#

source /etc/profile
BASEURL="https://install.xiechengqi.top"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {
# check pyenv
pyenv -v &> /dev/null && YELLOW "pyenv has been installed ..." && return 0

# install
EXEC "curl https://pyenv.run | bash"

# register bin
EXEC "ln -fs $HOME/.pyenv/bin/* /usr/local/bin/"

source /etc/profile
YELLOW "pyenv -v" && pyenv -v
}

main
