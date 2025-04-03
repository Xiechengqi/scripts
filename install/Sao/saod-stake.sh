#!/usr/bin/env bash

#
# 2023/04/18
# xiechengqi
# sao stake
#

source /etc/profile

saod tx staking create-validator \
  --amount=1000000000sao \
  --pubkey=$(saod tendermint show-validator) \
  --moniker="$(hostname)" \
  --commission-rate="0.10" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1000000" \
  --gas="2000000" \
  --gas-prices="0.0025sao" \
  --from=$(saod keys list | grep address | head -1 | awk '{print $NF}')
