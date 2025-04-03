#!/usr/bin/env bash

#
# xiechengqi
# 2025/02/14
# install tailscaled
#

# source /etc/profile
BASEURL="https://gitee.com/Xiechengqi/scripts/raw/master"
source <(curl -SsL $BASEURL/tool/common.sh)

main() {

# check os
osInfo=`get_os` && INFO "current os: $osInfo"
! echo "$osInfo" | grep -E 'ubuntu20' &> /dev/null && ERROR "You could only install on os: ubuntu20"

# environments
serviceName="tailscaled"

# check servcie
systemctl is-active ${serviceName} &> /dev/null && YELLOW "${serviceName} is running ..." && return 0

EXEC "apt update"

EXEC "apt install -y gnupg"
EXEC "mkdir -p --mode=0755 /usr/share/keyrings"
INFO "curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/tailscaled/focal.noarmor.gpg | apt-key add -" && curl -SsL https://gitee.com/Xiechengqi/scripts/raw/master/install/tailscaled/focal.noarmor.gpg | apt-key add -
cat > /etc/apt/sources.list.d/tailscale.list << EOF
deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu focal main
EOF

EXEC "apt update"
INFO "apt-get install -y tailscale tailscale-archive-keyring" && apt-get install -y tailscale tailscale-archive-keyring || exit 1
EXEC "systemctl enable --now tailscaled"
EXEC "systemctl status tailscaled"
INFO "tailscale up" && tailscale up

}

main $@
