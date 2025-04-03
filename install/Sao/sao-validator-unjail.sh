#!/usr/bin/env bash

SAODHOME="/data/saod/home"

export validatorInfoPubKeyValue=$(saod --home ${SAODHOME} status | awk -F 'value":"' '{print $NF}' | awk -F '"' '{print $1}')
export validatorOperatorAddress=$(saod --home ${SAODHOME} query staking validators | grep -A 20 "${validatorInfoPubKeyValue}" | grep 'operator_address:' | head -1 | awk '{print $NF}')
export validatorWalletAddress=""

for address in `saod --home ${SAODHOME} keys list | grep 'address:' | awk '{print $NF}'`
do
echo $(saod --home ${SAODHOME} keys show --address ${address} --bech=val) | grep "${validatorOperatorAddress}" &> /dev/null && validatorWalletAddress="${address}" && break
done
echo "validatorWalletAddress: ${validatorWalletAddress}"
saod query staking validator ${validatorOperatorAddress} | grep 'jailed: false' &> /dev/null && echo "saod --home ${SAODHOME} tx slashing unjail --from=${validatorWalletAddress}" && echo 'y' | saod --home ${SAODHOME} tx slashing unjail --from=${validatorWalletAddress} && echo "sleep 10 ..." && sleep 10
saod query staking validator ${validatorOperatorAddress}
